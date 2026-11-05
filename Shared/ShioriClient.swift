import Foundation

// MARK: - API Models

struct LoginRequest: Codable {
    let username: String
    let password: String
    let remember: Bool
}

struct LoginResponse: Codable {
    let ok: Bool
    let message: LoginMessage?
    
    struct LoginMessage: Codable {
        let token: String
        let session: String?
        let expires: Int?
    }
}

struct BookmarkRequest: Encodable {
    let url: String
    let title: String?
    let excerpt: String?
    let tags: [TagObject]?
    let createArchive: Bool
    let `public`: Int
    
    struct TagObject: Encodable {
        let name: String
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(excerpt, forKey: .excerpt)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(createArchive, forKey: .createArchive)
        try container.encode(`public`, forKey: .public)
    }
    
    private enum CodingKeys: String, CodingKey {
        case url, title, excerpt, tags, createArchive
        case `public` = "public"
    }
}

struct BookmarkResponse: Codable {
    let id: Int
    let url: String
    let title: String?
    let excerpt: String?
}

struct TagItem: Codable {
    let id: Int
    let name: String
    let bookmarkCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case bookmarkCount = "nBookmarks"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        bookmarkCount = try container.decode(Int.self, forKey: .bookmarkCount)
    }
}

// MARK: - API Errors

enum ShioriAPIError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidCredentials
    case connectionFailed(Error)
    case serverError(Int)
    case unauthorized
    case notFound
    case certificateError
    case decodingError(Error)
    case unknownError(Error)
    case apiNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Server not configured. Please open Shiori Share app to configure your server."
        case .invalidURL:
            return "Invalid server URL"
        case .invalidCredentials:
            return "Invalid username or password"
        case .connectionFailed(let error):
            return "Connection failed: \(error.localizedDescription)"
        case .serverError(let code):
            if code == 502 {
                return "API unavailable (502). Shiori v1.8.0 has a known bug. Please downgrade to v1.7.x."
            }
            return "Server error (\(code))"
        case .unauthorized:
            return "Session expired. Please try again."
        case .notFound:
            return "Shiori API not found. Check server URL."
        case .certificateError:
            return "Certificate error. Enable 'Trust Self-Signed Certs' in Settings if using self-signed certificate."
        case .decodingError:
            return "Invalid server response"
        case .unknownError(let error):
            return error.localizedDescription
        case .apiNotAvailable:
            return "Bookmark API unavailable. Shiori v1.8.0 has a known bug. Please use v1.7.x."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .connectionFailed, .serverError, .unauthorized:
            return true
        default:
            return false
        }
    }
}

// MARK: - Authentication

/// How API requests carry the credential returned by login.
enum ShioriAuthStyle: String, CaseIterable {
    /// `X-Session-Id: <session>`. Accepted by Shiori v1.7.x's legacy API.
    /// Removed in v1.8.0, which only accepts `Authorization`.
    case sessionID = "session-id"
    /// `Authorization: Bearer <token>`. Accepted by v1.7.x and v1.8.0.
    case bearer
}

/// What a successful login returns.
struct ShioriCredential {
    let token: String
    let session: String?
    /// Expiry as returned by the server, if any.
    let expires: Int?

    /// The value to send with requests for a given auth style.
    func value(for style: ShioriAuthStyle) -> String {
        switch style {
        case .bearer:
            return token
        case .sessionID:
            // Historical behaviour: fall back to the token when the server
            // returns no session (v1.8.0 doesn't). v1.8.0 ignores X-Session-Id,
            // so this fallback can't actually work there.
            return session ?? token
        }
    }
}

// MARK: - Shiori Client

/// Stateless HTTP client for the Shiori API.
///
/// Knows nothing about settings, the keychain, logging or session caching, so
/// it can be used by `ShioriAPI` (app + share extension), by unit tests, and by
/// the `Tools/shiori-cli` test program, which compiles only this file plus
/// `String+URL.swift` and `TrustSelfSignedCertificatesDelegate.swift`.
struct ShioriClient {

    /// API paths. Login uses the v1 API; bookmarks and tags use the legacy API.
    enum Path {
        static let login = "/api/v1/auth/login"
        static let bookmarks = "/api/bookmarks"
        static let tags = "/api/tags"
        static let logout = "/api/logout"
    }

    let baseURL: URL
    var authStyle: ShioriAuthStyle
    var trustSelfSignedCerts: Bool
    var timeout: TimeInterval

    /// Called before each request with (method, URL). Never sees credentials.
    var onRequest: ((String, URL) -> Void)?
    /// Called after each response with (method, URL, status code, duration).
    var onResponse: ((String, URL, Int, TimeInterval) -> Void)?

    init(
        baseURL: URL,
        authStyle: ShioriAuthStyle,
        trustSelfSignedCerts: Bool = false,
        timeout: TimeInterval = 30
    ) {
        self.baseURL = baseURL
        self.authStyle = authStyle
        self.trustSelfSignedCerts = trustSelfSignedCerts
        self.timeout = timeout
    }

    // MARK: Endpoints

    /// POST /api/v1/auth/login
    func login(username: String, password: String, remember: Bool = true) async throws -> ShioriCredential {
        var request = makeRequest(path: Path.login, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            LoginRequest(username: username, password: password, remember: remember)
        )

        let (data, response) = try await send(request)

        if response.statusCode == 401 || response.statusCode == 403 {
            throw ShioriAPIError.invalidCredentials
        }
        try Self.checkStatus(response.statusCode)

        let loginResponse = try decode(LoginResponse.self, from: data)
        guard loginResponse.ok, let message = loginResponse.message else {
            throw ShioriAPIError.invalidCredentials
        }
        return ShioriCredential(token: message.token, session: message.session, expires: message.expires)
    }

    /// POST /api/bookmarks (legacy API)
    func addBookmark(_ bookmark: BookmarkRequest, auth: String) async throws -> BookmarkResponse {
        var request = makeRequest(path: Path.bookmarks, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        authorize(&request, with: auth)
        request.httpBody = try JSONEncoder().encode(bookmark)

        let (data, response) = try await send(request)
        try Self.checkStatus(response.statusCode)
        return try decode(BookmarkResponse.self, from: data)
    }

    /// GET /api/tags (legacy API)
    func fetchTags(auth: String) async throws -> [TagItem] {
        var request = makeRequest(path: Path.tags, method: "GET")
        authorize(&request, with: auth)

        let (data, response) = try await send(request)
        try Self.checkStatus(response.statusCode)
        return try decode([TagItem].self, from: data)
    }

    // MARK: Request plumbing

    private func makeRequest(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathSafely(path))
        request.httpMethod = method
        request.timeoutInterval = timeout
        return request
    }

    private func authorize(_ request: inout URLRequest, with auth: String) {
        switch authStyle {
        case .bearer:
            request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        case .sessionID:
            request.setValue(auth, forHTTPHeaderField: "X-Session-Id")
        }
    }

    private func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let method = request.httpMethod ?? "GET"
        let url = request.url ?? baseURL
        onRequest?(method, url)
        let startTime = Date()

        let session = makeSession()
        defer {
            if session !== URLSession.shared {
                session.finishTasksAndInvalidate()
            }
        }

        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch {
            throw Self.mapNetworkError(error)
        }
        let (data, response) = result

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShioriAPIError.unknownError(NSError(domain: "ShioriAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        onResponse?(method, url, httpResponse.statusCode, Date().timeIntervalSince(startTime))
        return (data, httpResponse)
    }

    private func makeSession() -> URLSession {
        guard trustSelfSignedCerts else { return URLSession.shared }
        return URLSession(
            configuration: .default,
            delegate: TrustSelfSignedCertificatesDelegate(allowedHost: baseURL.host),
            delegateQueue: nil
        )
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ShioriAPIError.decodingError(error)
        }
    }

    // MARK: Helpers (pure, unit-tested via ShioriAPI)

    static func checkStatus(_ statusCode: Int) throws {
        switch statusCode {
        case 200, 201:
            return
        case 401:
            throw ShioriAPIError.unauthorized
        case 403:
            throw ShioriAPIError.invalidCredentials
        case 404:
            throw ShioriAPIError.notFound
        default:
            throw ShioriAPIError.serverError(statusCode)
        }
    }

    static func parseKeywords(_ keywords: String?) -> [BookmarkRequest.TagObject]? {
        guard let keywords = keywords?.trimmingCharacters(in: .whitespacesAndNewlines),
              !keywords.isEmpty else {
            return nil
        }
        
        let tags = keywords
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
            .map { BookmarkRequest.TagObject(name: $0) }
        
        return tags.isEmpty ? nil : tags
    }

    static func mapNetworkError(_ error: Error) -> ShioriAPIError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .serverCertificateUntrusted,
                 .secureConnectionFailed,
                 .serverCertificateHasBadDate,
                 .serverCertificateNotYetValid,
                 .serverCertificateHasUnknownRoot:
                return .certificateError
                
            case .cannotFindHost,
                 .cannotConnectToHost,
                 .networkConnectionLost,
                 .dnsLookupFailed,
                 .notConnectedToInternet,
                 .timedOut:
                return .connectionFailed(error)
                
            default:
                return .unknownError(error)
            }
        }
        return .unknownError(error)
    }
}

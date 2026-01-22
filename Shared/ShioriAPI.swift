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
        let session: String
        let expires: Int?
    }
}

struct BookmarkRequest: Codable {
    let url: String
    let title: String?
    let excerpt: String?
    let tags: [TagObject]?
    let createArchive: Bool
    let `public`: Int
    
    struct TagObject: Codable {
        let name: String
    }
}

struct BookmarkResponse: Codable {
    let id: Int
    let url: String
    let title: String?
    let excerpt: String?
}

struct TagResponse: Codable {
    let id: Int
    let name: String
    let nBookmarks: Int
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

// MARK: - Shiori API Client

final class ShioriAPI {
    static let shared = ShioriAPI()
    
    private let keychain = KeychainHelper.shared
    private let settings = SettingsManager.shared
    private let logger = DebugLogger.shared
    
    private init() {}
    
    // MARK: - Public API
    
    func login() async throws -> String {
        guard let serverURL = settings.serverURL,
              let username = settings.username,
              let password = keychain.password else {
            throw ShioriAPIError.notConfigured
        }
        
        guard let baseURL = URL(string: serverURL) else {
            throw ShioriAPIError.invalidURL
        }
        
        let loginURL = baseURL.appendingPathSafely(AppConstants.API.loginPath)
        
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = AppConstants.Timing.networkTimeout
        
        let loginRequest = LoginRequest(username: username, password: password, remember: true)
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        logger.apiRequest(method: "POST", url: loginURL.absoluteString)
        let startTime = Date()
        
        do {
            let (data, response) = try await createSession().data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ShioriAPIError.unknownError(NSError(domain: "ShioriAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
            
            logger.apiResponse(method: "POST", url: loginURL.absoluteString, statusCode: httpResponse.statusCode, duration: duration)
            
            switch httpResponse.statusCode {
            case 200:
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                
                guard loginResponse.ok, let message = loginResponse.message else {
                    throw ShioriAPIError.invalidCredentials
                }
                
                // Use session ID for legacy API (not JWT token)
                settings.cachedSessionID = message.session
                settings.sessionTimestamp = Date()
                
                logger.info("Login successful for user: \(username)")
                return message.session
                
            case 401, 403:
                throw ShioriAPIError.invalidCredentials
            case 404:
                throw ShioriAPIError.notFound
            case 500...599:
                throw ShioriAPIError.serverError(httpResponse.statusCode)
            default:
                throw ShioriAPIError.serverError(httpResponse.statusCode)
            }
        } catch let error as ShioriAPIError {
            throw error
        } catch let error as DecodingError {
            logger.error(error, context: "Login decoding error")
            throw ShioriAPIError.decodingError(error)
        } catch {
            throw mapNetworkError(error)
        }
    }
    
    func addBookmark(
        url: String,
        title: String?,
        description: String?,
        keywords: String?,
        createArchive: Bool,
        makePublic: Bool
    ) async throws -> BookmarkResponse {
        let sessionID = try await getValidSession()
        
        guard let serverURL = settings.serverURL,
              let baseURL = URL(string: serverURL) else {
            throw ShioriAPIError.notConfigured
        }
        
        let bookmarksURL = baseURL.appendingPathSafely(AppConstants.API.bookmarksPath)
        
        var request = URLRequest(url: bookmarksURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionID, forHTTPHeaderField: "X-Session-Id")
        request.timeoutInterval = AppConstants.Timing.networkTimeout
        
        let tags = parseKeywords(keywords)
        
        // Build JSON manually to avoid null values that Shiori may not handle
        var body: [String: Any] = [
            "url": url,
            "createArchive": createArchive,
            "public": makePublic ? 1 : 0
        ]
        if let title = title, !title.isEmpty {
            body["title"] = title
        }
        if let description = description, !description.isEmpty {
            body["excerpt"] = description
        }
        if let tags = tags {
            body["tags"] = tags.map { ["name": $0.name] }
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        logger.apiRequest(method: "POST", url: bookmarksURL.absoluteString, headers: ["X-Session-Id": "[REDACTED]"])
        let startTime = Date()
        
        do {
            let (data, response) = try await createSession().data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ShioriAPIError.unknownError(NSError(domain: "ShioriAPI", code: -1))
            }
            
            logger.apiResponse(method: "POST", url: bookmarksURL.absoluteString, statusCode: httpResponse.statusCode, duration: duration)
            
            switch httpResponse.statusCode {
            case 200, 201:
                let bookmarkResponse = try JSONDecoder().decode(BookmarkResponse.self, from: data)
                
                if let tags = tags {
                    settings.addRecentTags(tags.map { $0.name })
                }
                
                logger.info("Bookmark saved: id=\(bookmarkResponse.id)")
                return bookmarkResponse
                
            case 401:
                settings.clearSession()
                throw ShioriAPIError.unauthorized
            case 404:
                throw ShioriAPIError.notFound
            case 500...599:
                throw ShioriAPIError.serverError(httpResponse.statusCode)
            default:
                throw ShioriAPIError.serverError(httpResponse.statusCode)
            }
        } catch let error as ShioriAPIError {
            throw error
        } catch let error as DecodingError {
            logger.error(error, context: "Bookmark decoding error")
            throw ShioriAPIError.decodingError(error)
        } catch {
            throw mapNetworkError(error)
        }
    }
    
    func fetchTags() async throws -> [TagResponse] {
        let sessionID = try await getValidSession()
        
        guard let serverURL = settings.serverURL,
              let baseURL = URL(string: serverURL) else {
            throw ShioriAPIError.notConfigured
        }
        
        let tagsURL = baseURL.appendingPathSafely(AppConstants.API.tagsPath)
        
        var request = URLRequest(url: tagsURL)
        request.httpMethod = "GET"
        request.setValue(sessionID, forHTTPHeaderField: "X-Session-Id")
        request.timeoutInterval = AppConstants.Timing.networkTimeout
        
        logger.apiRequest(method: "GET", url: tagsURL.absoluteString)
        let startTime = Date()
        
        do {
            let (data, response) = try await createSession().data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ShioriAPIError.unknownError(NSError(domain: "ShioriAPI", code: -1))
            }
            
            logger.apiResponse(method: "GET", url: tagsURL.absoluteString, statusCode: httpResponse.statusCode, duration: duration)
            
            switch httpResponse.statusCode {
            case 200:
                let tags = try JSONDecoder().decode([TagResponse].self, from: data)
                logger.info("Fetched \(tags.count) tags from server")
                return tags
                
            case 401:
                settings.clearSession()
                throw ShioriAPIError.unauthorized
            case 404:
                throw ShioriAPIError.notFound
            default:
                throw ShioriAPIError.serverError(httpResponse.statusCode)
            }
        } catch let error as ShioriAPIError {
            throw error
        } catch let error as DecodingError {
            logger.error(error, context: "Tags decoding error")
            throw ShioriAPIError.decodingError(error)
        } catch {
            throw mapNetworkError(error)
        }
    }
    
    func refreshPopularTags() async {
        do {
            let tags = try await fetchTags()
            let popularTags = tags
                .sorted { $0.nBookmarks > $1.nBookmarks }
                .prefix(AppConstants.Defaults.maxRecentTags)
                .map { $0.name }
            settings.recentTags = Array(popularTags)
            logger.info("Updated popular tags cache: \(popularTags)")
        } catch {
            logger.error(error, context: "Failed to refresh popular tags")
        }
    }
    
    // MARK: - Session Management
    
    private func getValidSession() async throws -> String {
        if settings.isSessionValid, let session = settings.cachedSessionID {
            return session
        }
        
        return try await login()
    }
    
    func clearSession() {
        settings.clearSession()
    }
    
    // MARK: - Helper Methods
    
    private func parseKeywords(_ keywords: String?) -> [BookmarkRequest.TagObject]? {
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
    
    private func createSession() -> URLSession {
        if settings.trustSelfSignedCerts {
            let config = URLSessionConfiguration.default
            return URLSession(configuration: config, delegate: SelfSignedCertDelegate(), delegateQueue: nil)
        }
        return URLSession.shared
    }
    
    private func mapNetworkError(_ error: Error) -> ShioriAPIError {
        let nsError = error as NSError
        
        switch nsError.code {
        case NSURLErrorServerCertificateUntrusted,
             NSURLErrorSecureConnectionFailed,
             NSURLErrorServerCertificateHasBadDate,
             NSURLErrorServerCertificateNotYetValid,
             NSURLErrorServerCertificateHasUnknownRoot:
            return .certificateError
            
        case NSURLErrorCannotFindHost,
             NSURLErrorCannotConnectToHost,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorDNSLookupFailed,
             NSURLErrorNotConnectedToInternet,
             NSURLErrorTimedOut:
            return .connectionFailed(error)
            
        default:
            return .unknownError(error)
        }
    }
}

// MARK: - Self-Signed Certificate Delegate

private class SelfSignedCertDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

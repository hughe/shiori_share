import Foundation

// Models, ShioriAPIError and the HTTP client itself live in ShioriClient.swift.

// MARK: - Shiori API (app-facing)

/// App-facing Shiori API used by the main app and the share extension.
///
/// Wraps the stateless `ShioriClient` with the stored server settings, the
/// keychain password, session caching and recent-tag bookkeeping.
final class ShioriAPI {
    static let shared = ShioriAPI()

    /// How requests authenticate. `.sessionID` only works with Shiori v1.7.x;
    /// `.bearer` works with v1.7.x and v1.8.0. Switching is planned, see TODO.md.
    static let authStyle: ShioriAuthStyle = .sessionID

    private let keychain = KeychainHelper.shared
    private let settings = SettingsManager.shared
    private let logger = DebugLogger.shared

    private init() {}

    // MARK: - Public API

    /// Login with explicitly provided credentials (doesn't cache session)
    func login(serverURL: String, username: String, password: String) async throws -> String {
        let client = try makeClient(serverURL: serverURL)
        do {
            let credential = try await client.login(username: username, password: password)
            logger.info("Login successful for user: \(username)")
            return credential.value(for: Self.authStyle)
        } catch {
            throw handle(error, context: "Login")
        }
    }

    /// Login using stored credentials (caches session)
    func login() async throws -> String {
        guard let serverURL = settings.serverURL,
              let username = settings.username,
              let password = keychain.password else {
            throw ShioriAPIError.notConfigured
        }

        let session = try await login(serverURL: serverURL, username: username, password: password)

        // Cache the session for reuse
        settings.cachedSessionID = session
        settings.sessionTimestamp = Date()

        return session
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
        let client = try makeClient()

        let tags = parseKeywords(keywords)
        let bookmarkRequest = BookmarkRequest(
            url: url,
            title: title?.isEmpty == false ? title : nil,
            excerpt: description?.isEmpty == false ? description : nil,
            tags: tags,
            createArchive: createArchive,
            public: makePublic ? 1 : 0
        )

        do {
            let bookmarkResponse = try await client.addBookmark(bookmarkRequest, auth: sessionID)

            if let tags = tags {
                settings.addRecentTags(tags.map { $0.name })
            }

            logger.info("Bookmark saved: id=\(bookmarkResponse.id)")
            return bookmarkResponse
        } catch {
            throw handle(error, context: "Bookmark")
        }
    }

    func fetchTags() async throws -> [TagItem] {
        let sessionID = try await getValidSession()
        let client = try makeClient()

        do {
            let tags = try await client.fetchTags(auth: sessionID)
            logger.info("Fetched \(tags.count) tags from server")
            return tags
        } catch {
            throw handle(error, context: "Tags")
        }
    }

    func refreshPopularTags() async {
        do {
            let tags = try await fetchTags()
            let popularTags = tags
                .sorted { $0.bookmarkCount > $1.bookmarkCount }
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

    func parseKeywords(_ keywords: String?) -> [BookmarkRequest.TagObject]? {
        ShioriClient.parseKeywords(keywords)
    }

    internal func mapNetworkError(_ error: Error) -> ShioriAPIError {
        ShioriClient.mapNetworkError(error)
    }

    /// Builds a client for an explicit server URL (login/test connection) or
    /// for the stored settings.
    private func makeClient(serverURL: String? = nil) throws -> ShioriClient {
        let urlString: String
        if let serverURL = serverURL {
            guard URL(string: serverURL) != nil else { throw ShioriAPIError.invalidURL }
            urlString = serverURL
        } else {
            guard let stored = settings.serverURL, URL(string: stored) != nil else {
                throw ShioriAPIError.notConfigured
            }
            urlString = stored
        }

        var client = ShioriClient(
            baseURL: URL(string: urlString)!,
            authStyle: Self.authStyle,
            trustSelfSignedCerts: settings.trustSelfSignedCerts,
            timeout: AppConstants.Timing.networkTimeout
        )
        client.onRequest = { [logger = self.logger] method, url in
            logger.apiRequest(method: method, url: url.absoluteString)
        }
        client.onResponse = { [logger = self.logger] method, url, statusCode, duration in
            logger.apiResponse(method: method, url: url.absoluteString, statusCode: statusCode, duration: duration)
        }
        return client
    }

    /// Logs decoding errors and clears the cached session on 401.
    private func handle(_ error: Error, context: String) -> Error {
        if let apiError = error as? ShioriAPIError {
            switch apiError {
            case .decodingError(let underlying):
                logger.error(underlying, context: "\(context) decoding error")
            case .unauthorized:
                settings.clearSession()
            default:
                break
            }
        }
        return error
    }
}

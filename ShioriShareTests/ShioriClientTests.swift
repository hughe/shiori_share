import XCTest
@testable import ShioriShare

final class ShioriClientTests: XCTestCase {
    private var session: URLSession!
    private var client: ShioriClient!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        session = URLSession(configuration: configuration)
        client = ShioriClient(baseURL: URL(string: "https://example.com/shiori")!,
                              authStyle: ShioriAPI.authStyle, session: session)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        StubURLProtocol.handler = nil
        client = nil
        session = nil
        super.tearDown()
    }

    func testLoginParsesTokenOnlyResponse() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/shiori/api/v1/auth/login")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            return (200, #"{"ok":true,"message":{"token":"jwt-only","expires":3600}}"#)
        }
        let credential = try await client.login(username: "user", password: "password")
        XCTAssertEqual(credential.token, "jwt-only")
        XCTAssertNil(credential.session)
        XCTAssertEqual(credential.expires, 3600)
        XCTAssertEqual(credential.value(for: ShioriAPI.authStyle), "jwt-only")
    }

    func testLoginUsesTokenWhenLegacySessionAlsoPresent() async throws {
        StubURLProtocol.handler = { _ in
            (200, #"{"ok":true,"message":{"token":"jwt","session":"legacy-session"}}"#)
        }
        let credential = try await client.login(username: "user", password: "password")
        XCTAssertEqual(credential.value(for: ShioriAPI.authStyle), "jwt")
    }

    func testTagsSendsBearerHeader() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/shiori/api/tags")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer jwt")
            XCTAssertNil(request.value(forHTTPHeaderField: "X-Session-Id"))
            return (200, #"[{"id":1,"name":"swift","nBookmarks":2}]"#)
        }
        let tags = try await client.fetchTags(auth: "jwt")
        XCTAssertEqual(tags.first?.name, "swift")
    }

    func testBookmarkSendsBearerHeader() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/shiori/api/bookmarks")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer jwt")
            XCTAssertNil(request.value(forHTTPHeaderField: "X-Session-Id"))
            return (201, #"{"id":1,"url":"https://example.org"}"#)
        }
        let bookmark = BookmarkRequest(url: "https://example.org", title: nil, excerpt: nil,
                                       tags: nil, createArchive: true, public: 0)
        let response = try await client.addBookmark(bookmark, auth: "jwt")
        XCTAssertEqual(response.id, 1)
    }

    func testTagsParsesV180Envelope() async throws {
        StubURLProtocol.handler = { _ in
            (200, #"{"ok":true,"message":[{"id":1,"name":"swift","bookmark_count":2,"deleted":false}]}"#)
        }
        let tags = try await client.fetchTags(auth: "jwt")
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags[0].name, "swift")
        XCTAssertEqual(tags[0].bookmarkCount, 2)
    }

    func testTagsDefaultsOmittedLegacyCountToZero() async throws {
        StubURLProtocol.handler = { _ in (200, #"[{"id":1,"name":"unused"}]"#) }
        let tags = try await client.fetchTags(auth: "jwt")
        XCTAssertEqual(tags[0].bookmarkCount, 0)
    }

    func testTagsPreservesZeroV180Count() async throws {
        StubURLProtocol.handler = { _ in
            (200, #"{"ok":true,"message":[{"id":1,"name":"unused","bookmark_count":0}]}"#)
        }
        let tags = try await client.fetchTags(auth: "jwt")
        XCTAssertEqual(tags[0].bookmarkCount, 0)
    }

    func testTagsParsesEmptyV180Envelope() async throws {
        StubURLProtocol.handler = { _ in (200, #"{"ok":true,"message":[]}"#) }
        let tags = try await client.fetchTags(auth: "jwt")
        XCTAssertTrue(tags.isEmpty)
    }

    func testBookmarkParsesV180Envelope() async throws {
        StubURLProtocol.handler = { _ in
            (200, #"{"ok":true,"message":{"id":42,"url":"https://example.org","title":"Example"}}"#)
        }
        let bookmark = BookmarkRequest(url: "https://example.org", title: nil, excerpt: nil,
                                       tags: nil, createArchive: true, public: 0)
        let response = try await client.addBookmark(bookmark, auth: "jwt")
        XCTAssertEqual(response.id, 42)
        XCTAssertEqual(response.title, "Example")
    }

    func testTagsRejectsFailedOrMalformedEnvelopes() async throws {
        for body in [#"{"ok":false,"message":[]}"#,
                     #"{"ok":true,"message":{"unexpected":"dictionary"}}"#,
                     #"{"ok":true}"#] {
            StubURLProtocol.handler = { _ in (200, body) }
            do {
                _ = try await client.fetchTags(auth: "jwt")
                XCTFail("Expected decoding failure for \(body)")
            } catch ShioriAPIError.decodingError {
                // A malformed payload must not look like a valid empty tag list.
            }
        }
    }

    func testTagsUnauthorizedRemainsAuthenticationError() async throws {
        StubURLProtocol.handler = { _ in (401, #"{"ok":false,"message":"Unauthorized"}"#) }
        do {
            _ = try await client.fetchTags(auth: "jwt")
            XCTFail("Expected unauthorized")
        } catch ShioriAPIError.unauthorized {
            // HTTP authentication failures are handled before payload decoding.
        }
    }

    func testWrongPasswordReturnsInvalidCredentials() async throws {
        StubURLProtocol.handler = { _ in (401, "{}") }
        do {
            _ = try await client.login(username: "user", password: "wrong")
            XCTFail("Expected invalid credentials")
        } catch ShioriAPIError.invalidCredentials {
            // Expected login error.
        }
    }
}

private final class StubURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, String))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let handle = try XCTUnwrap(Self.handler)
            let (status, body) = try handle(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

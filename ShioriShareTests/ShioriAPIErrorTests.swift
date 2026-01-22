import XCTest
@testable import ShioriShare

final class ShioriAPIErrorTests: XCTestCase {

    // MARK: - Error Descriptions

    func testErrorDescription_notConfigured() {
        let error = ShioriAPIError.notConfigured
        XCTAssertEqual(error.errorDescription, "Server not configured. Please open Shiori Share app to configure your server.")
    }

    func testErrorDescription_invalidURL() {
        let error = ShioriAPIError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid server URL")
    }

    func testErrorDescription_invalidCredentials() {
        let error = ShioriAPIError.invalidCredentials
        XCTAssertEqual(error.errorDescription, "Invalid username or password")
    }

    func testErrorDescription_connectionFailed() {
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Network unreachable"])
        let error = ShioriAPIError.connectionFailed(underlyingError)
        XCTAssertEqual(error.errorDescription, "Connection failed: Network unreachable")
    }

    func testErrorDescription_serverError() {
        let error = ShioriAPIError.serverError(500)
        XCTAssertEqual(error.errorDescription, "Server error (500)")
    }

    func testErrorDescription_unauthorized() {
        let error = ShioriAPIError.unauthorized
        XCTAssertEqual(error.errorDescription, "Session expired. Please try again.")
    }

    func testErrorDescription_notFound() {
        let error = ShioriAPIError.notFound
        XCTAssertEqual(error.errorDescription, "Shiori API not found. Check server URL.")
    }

    func testErrorDescription_certificateError() {
        let error = ShioriAPIError.certificateError
        XCTAssertEqual(error.errorDescription, "Certificate error. Enable 'Trust Self-Signed Certs' in Settings if using self-signed certificate.")
    }

    func testErrorDescription_decodingError() {
        let underlyingError = NSError(domain: "DecodingDomain", code: 456, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        let error = ShioriAPIError.decodingError(underlyingError)
        XCTAssertEqual(error.errorDescription, "Invalid server response")
    }

    func testErrorDescription_unknownError() {
        let underlyingError = NSError(domain: "UnknownDomain", code: 789, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        let error = ShioriAPIError.unknownError(underlyingError)
        XCTAssertEqual(error.errorDescription, "Something went wrong")
    }

    // MARK: - isRetryable

    func testIsRetryable_connectionFailed_returnsTrue() {
        let underlyingError = NSError(domain: "TestDomain", code: 123)
        let error = ShioriAPIError.connectionFailed(underlyingError)
        XCTAssertTrue(error.isRetryable)
    }

    func testIsRetryable_serverError_returnsTrue() {
        let error = ShioriAPIError.serverError(500)
        XCTAssertTrue(error.isRetryable)
    }

    func testIsRetryable_unauthorized_returnsTrue() {
        let error = ShioriAPIError.unauthorized
        XCTAssertTrue(error.isRetryable)
    }

    func testIsRetryable_notConfigured_returnsFalse() {
        let error = ShioriAPIError.notConfigured
        XCTAssertFalse(error.isRetryable)
    }

    func testIsRetryable_invalidURL_returnsFalse() {
        let error = ShioriAPIError.invalidURL
        XCTAssertFalse(error.isRetryable)
    }

    func testIsRetryable_invalidCredentials_returnsFalse() {
        let error = ShioriAPIError.invalidCredentials
        XCTAssertFalse(error.isRetryable)
    }

    func testIsRetryable_notFound_returnsFalse() {
        let error = ShioriAPIError.notFound
        XCTAssertFalse(error.isRetryable)
    }

    func testIsRetryable_certificateError_returnsFalse() {
        let error = ShioriAPIError.certificateError
        XCTAssertFalse(error.isRetryable)
    }

    func testIsRetryable_decodingError_returnsFalse() {
        let underlyingError = NSError(domain: "DecodingDomain", code: 456)
        let error = ShioriAPIError.decodingError(underlyingError)
        XCTAssertFalse(error.isRetryable)
    }

    func testIsRetryable_unknownError_returnsFalse() {
        let underlyingError = NSError(domain: "UnknownDomain", code: 789)
        let error = ShioriAPIError.unknownError(underlyingError)
        XCTAssertFalse(error.isRetryable)
    }
}

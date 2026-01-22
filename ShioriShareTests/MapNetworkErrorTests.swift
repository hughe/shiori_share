import XCTest
@testable import ShioriShare

final class MapNetworkErrorTests: XCTestCase {

    let api = ShioriAPI.shared

    // MARK: - Certificate Errors

    func testMapNetworkError_serverCertificateUntrusted_returnsCertificateError() {
        let urlError = URLError(.serverCertificateUntrusted)
        let result = api.mapNetworkError(urlError)

        if case .certificateError = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .certificateError, got \(result)")
        }
    }

    func testMapNetworkError_secureConnectionFailed_returnsCertificateError() {
        let urlError = URLError(.secureConnectionFailed)
        let result = api.mapNetworkError(urlError)

        if case .certificateError = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .certificateError, got \(result)")
        }
    }

    func testMapNetworkError_serverCertificateHasBadDate_returnsCertificateError() {
        let urlError = URLError(.serverCertificateHasBadDate)
        let result = api.mapNetworkError(urlError)

        if case .certificateError = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .certificateError, got \(result)")
        }
    }

    func testMapNetworkError_serverCertificateNotYetValid_returnsCertificateError() {
        let urlError = URLError(.serverCertificateNotYetValid)
        let result = api.mapNetworkError(urlError)

        if case .certificateError = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .certificateError, got \(result)")
        }
    }

    func testMapNetworkError_serverCertificateHasUnknownRoot_returnsCertificateError() {
        let urlError = URLError(.serverCertificateHasUnknownRoot)
        let result = api.mapNetworkError(urlError)

        if case .certificateError = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .certificateError, got \(result)")
        }
    }

    // MARK: - Connection Errors

    func testMapNetworkError_cannotFindHost_returnsConnectionFailed() {
        let urlError = URLError(.cannotFindHost)
        let result = api.mapNetworkError(urlError)

        if case .connectionFailed(let error) = result {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .cannotFindHost)
        } else {
            XCTFail("Expected .connectionFailed, got \(result)")
        }
    }

    func testMapNetworkError_cannotConnectToHost_returnsConnectionFailed() {
        let urlError = URLError(.cannotConnectToHost)
        let result = api.mapNetworkError(urlError)

        if case .connectionFailed(let error) = result {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .cannotConnectToHost)
        } else {
            XCTFail("Expected .connectionFailed, got \(result)")
        }
    }

    func testMapNetworkError_networkConnectionLost_returnsConnectionFailed() {
        let urlError = URLError(.networkConnectionLost)
        let result = api.mapNetworkError(urlError)

        if case .connectionFailed(let error) = result {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .networkConnectionLost)
        } else {
            XCTFail("Expected .connectionFailed, got \(result)")
        }
    }

    func testMapNetworkError_dnsLookupFailed_returnsConnectionFailed() {
        let urlError = URLError(.dnsLookupFailed)
        let result = api.mapNetworkError(urlError)

        if case .connectionFailed(let error) = result {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .dnsLookupFailed)
        } else {
            XCTFail("Expected .connectionFailed, got \(result)")
        }
    }

    func testMapNetworkError_notConnectedToInternet_returnsConnectionFailed() {
        let urlError = URLError(.notConnectedToInternet)
        let result = api.mapNetworkError(urlError)

        if case .connectionFailed(let error) = result {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        } else {
            XCTFail("Expected .connectionFailed, got \(result)")
        }
    }

    func testMapNetworkError_timedOut_returnsConnectionFailed() {
        let urlError = URLError(.timedOut)
        let result = api.mapNetworkError(urlError)

        if case .connectionFailed(let error) = result {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .timedOut)
        } else {
            XCTFail("Expected .connectionFailed, got \(result)")
        }
    }

    // MARK: - Other URLError Codes

    func testMapNetworkError_badURL_returnsUnknownError() {
        let urlError = URLError(.badURL)
        let result = api.mapNetworkError(urlError)

        if case .unknownError(let error) = result {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .badURL)
        } else {
            XCTFail("Expected .unknownError, got \(result)")
        }
    }

    func testMapNetworkError_cancelled_returnsUnknownError() {
        let urlError = URLError(.cancelled)
        let result = api.mapNetworkError(urlError)

        if case .unknownError(let error) = result {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
        } else {
            XCTFail("Expected .unknownError, got \(result)")
        }
    }

    func testMapNetworkError_dataLengthExceedsMaximum_returnsUnknownError() {
        let urlError = URLError(.dataLengthExceedsMaximum)
        let result = api.mapNetworkError(urlError)

        if case .unknownError(let error) = result {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .dataLengthExceedsMaximum)
        } else {
            XCTFail("Expected .unknownError, got \(result)")
        }
    }

    // MARK: - Non-URLError Errors

    func testMapNetworkError_nonURLError_returnsUnknownError() {
        let customError = NSError(domain: "TestDomain", code: 999, userInfo: nil)
        let result = api.mapNetworkError(customError)

        if case .unknownError(let error) = result {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "TestDomain")
            XCTAssertEqual(nsError.code, 999)
        } else {
            XCTFail("Expected .unknownError, got \(result)")
        }
    }

    func testMapNetworkError_genericError_returnsUnknownError() {
        enum TestError: Error {
            case testCase
        }

        let result = api.mapNetworkError(TestError.testCase)

        if case .unknownError(let error) = result {
            XCTAssertTrue(error is TestError)
        } else {
            XCTFail("Expected .unknownError, got \(result)")
        }
    }
}

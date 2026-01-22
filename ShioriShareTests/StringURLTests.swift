import XCTest
@testable import ShioriShare

final class StringURLTests: XCTestCase {
    
    // MARK: - isValidURL
    
    func testIsValidURL_withValidHTTPSURL_returnsTrue() {
        XCTAssertTrue("https://example.com".isValidURL)
    }
    
    func testIsValidURL_withValidHTTPURL_returnsTrue() {
        XCTAssertTrue("http://example.com".isValidURL)
    }
    
    func testIsValidURL_withPathAndQuery_returnsTrue() {
        XCTAssertTrue("https://example.com/path?query=1".isValidURL)
    }
    
    func testIsValidURL_withoutScheme_returnsFalse() {
        XCTAssertFalse("example.com".isValidURL)
    }
    
    func testIsValidURL_withEmptyString_returnsFalse() {
        XCTAssertFalse("".isValidURL)
    }
    
    func testIsValidURL_withWhitespace_returnsFalse() {
        XCTAssertFalse("   ".isValidURL)
    }
    
    // MARK: - isValidHTTPURL
    
    func testIsValidHTTPURL_withHTTPS_returnsTrue() {
        XCTAssertTrue("https://example.com".isValidHTTPURL)
    }
    
    func testIsValidHTTPURL_withHTTP_returnsTrue() {
        XCTAssertTrue("http://example.com".isValidHTTPURL)
    }
    
    func testIsValidHTTPURL_withFTP_returnsFalse() {
        XCTAssertFalse("ftp://example.com".isValidHTTPURL)
    }
    
    func testIsValidHTTPURL_withFileScheme_returnsFalse() {
        XCTAssertFalse("file:///path/to/file".isValidHTTPURL)
    }
    
    func testIsValidHTTPURL_withoutScheme_returnsFalse() {
        XCTAssertFalse("example.com".isValidHTTPURL)
    }
    
    // MARK: - normalizedServerURL
    
    func testNormalizedServerURL_addsHTTPS_whenNoScheme() {
        XCTAssertEqual("example.com".normalizedServerURL, "https://example.com")
    }
    
    func testNormalizedServerURL_preservesHTTPS() {
        XCTAssertEqual("https://example.com".normalizedServerURL, "https://example.com")
    }
    
    func testNormalizedServerURL_preservesHTTP() {
        XCTAssertEqual("http://example.com".normalizedServerURL, "http://example.com")
    }
    
    func testNormalizedServerURL_stripsTrailingSlash() {
        XCTAssertEqual("https://example.com/".normalizedServerURL, "https://example.com")
    }
    
    func testNormalizedServerURL_stripsMultipleTrailingSlashes() {
        XCTAssertEqual("https://example.com///".normalizedServerURL, "https://example.com")
    }
    
    func testNormalizedServerURL_trimsWhitespace() {
        XCTAssertEqual("  https://example.com  ".normalizedServerURL, "https://example.com")
    }
    
    func testNormalizedServerURL_handlesComplexURL() {
        XCTAssertEqual("example.com:8080/shiori/".normalizedServerURL, "https://example.com:8080/shiori")
    }
    
    // MARK: - extractedURL
    
    func testExtractedURL_withDirectURL_returnsURL() {
        let result = "https://example.com".extractedURL
        XCTAssertEqual(result?.absoluteString, "https://example.com")
    }
    
    func testExtractedURL_withEmbeddedURL_extractsURL() {
        let result = "Check out https://example.com for more info".extractedURL
        XCTAssertEqual(result?.absoluteString, "https://example.com")
    }
    
    func testExtractedURL_withNoURL_returnsNil() {
        XCTAssertNil("No URL here".extractedURL)
    }
    
    func testExtractedURL_withEmptyString_returnsNil() {
        XCTAssertNil("".extractedURL)
    }
}

// MARK: - URL Extension Tests

final class URLExtensionTests: XCTestCase {
    
    func testIsHTTP_withHTTPS_returnsTrue() {
        let url = URL(string: "https://example.com")!
        XCTAssertTrue(url.isHTTP)
    }
    
    func testIsHTTP_withHTTP_returnsTrue() {
        let url = URL(string: "http://example.com")!
        XCTAssertTrue(url.isHTTP)
    }
    
    func testIsHTTP_withFTP_returnsFalse() {
        let url = URL(string: "ftp://example.com")!
        XCTAssertFalse(url.isHTTP)
    }
    
    func testAppendingPathSafely_withLeadingSlash_removesSlash() {
        let base = URL(string: "https://example.com")!
        let result = base.appendingPathSafely("/api/v1")
        XCTAssertEqual(result.absoluteString, "https://example.com/api/v1")
    }
    
    func testAppendingPathSafely_withoutLeadingSlash_appendsPath() {
        let base = URL(string: "https://example.com")!
        let result = base.appendingPathSafely("api/v1")
        XCTAssertEqual(result.absoluteString, "https://example.com/api/v1")
    }
}

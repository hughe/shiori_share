import XCTest
@testable import ShioriShare

final class ParseKeywordsTests: XCTestCase {
    
    let api = ShioriAPI.shared
    
    // MARK: - Basic Parsing
    
    func testParseKeywords_singleTag_returnsSingleTag() {
        let result = api.parseKeywords("swift")
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?.first?.name, "swift")
    }
    
    func testParseKeywords_multipleTags_returnsAllTags() {
        let result = api.parseKeywords("swift, ios, mac")
        XCTAssertEqual(result?.count, 3)
        XCTAssertEqual(result?[0].name, "swift")
        XCTAssertEqual(result?[1].name, "ios")
        XCTAssertEqual(result?[2].name, "mac")
    }
    
    // MARK: - Whitespace Handling
    
    func testParseKeywords_extraWhitespace_trimsWhitespace() {
        let result = api.parseKeywords("  swift  ,  ios  ")
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[0].name, "swift")
        XCTAssertEqual(result?[1].name, "ios")
    }
    
    func testParseKeywords_leadingTrailingWhitespace_trimsOuter() {
        let result = api.parseKeywords("   swift, ios   ")
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[0].name, "swift")
        XCTAssertEqual(result?[1].name, "ios")
    }
    
    // MARK: - Empty String Handling
    
    func testParseKeywords_emptyStrings_filtersEmpty() {
        let result = api.parseKeywords("swift,,ios")
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[0].name, "swift")
        XCTAssertEqual(result?[1].name, "ios")
    }
    
    func testParseKeywords_onlyCommas_returnsNil() {
        let result = api.parseKeywords(",,,")
        XCTAssertNil(result)
    }
    
    func testParseKeywords_onlyWhitespace_returnsNil() {
        let result = api.parseKeywords("   ")
        XCTAssertNil(result)
    }
    
    func testParseKeywords_emptyString_returnsNil() {
        let result = api.parseKeywords("")
        XCTAssertNil(result)
    }
    
    func testParseKeywords_nil_returnsNil() {
        let result = api.parseKeywords(nil)
        XCTAssertNil(result)
    }
    
    // MARK: - Case Handling
    
    func testParseKeywords_mixedCase_lowercasesAll() {
        let result = api.parseKeywords("Swift, IOS, MacOS")
        XCTAssertEqual(result?.count, 3)
        XCTAssertEqual(result?[0].name, "swift")
        XCTAssertEqual(result?[1].name, "ios")
        XCTAssertEqual(result?[2].name, "macos")
    }
    
    // MARK: - Edge Cases
    
    func testParseKeywords_trailingComma_ignoresEmpty() {
        let result = api.parseKeywords("swift, ios,")
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[0].name, "swift")
        XCTAssertEqual(result?[1].name, "ios")
    }
    
    func testParseKeywords_leadingComma_ignoresEmpty() {
        let result = api.parseKeywords(",swift, ios")
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[0].name, "swift")
        XCTAssertEqual(result?[1].name, "ios")
    }
    
    func testParseKeywords_spacesInTag_preservesSpaces() {
        let result = api.parseKeywords("web development, machine learning")
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?[0].name, "web development")
        XCTAssertEqual(result?[1].name, "machine learning")
    }
}

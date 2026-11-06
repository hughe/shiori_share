import XCTest
@testable import ShioriShare

final class SettingsManagerTests: XCTestCase {

    var settingsManager: SettingsManager!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Create a test-specific UserDefaults that won't interfere with actual app settings
        testDefaults = UserDefaults(suiteName: "test.settings.manager.\(UUID().uuidString)")!
        settingsManager = SettingsManager(defaults: testDefaults)
    }

    override func tearDown() {
        // Clean up test UserDefaults
        testDefaults.removePersistentDomain(forName: testDefaults.persistentDomain(forName: "test.settings.manager")?.keys.first ?? "")
        testDefaults = nil
        settingsManager = nil
        super.tearDown()
    }

    // MARK: - Default Values

    func testDefaultCreateArchive_whenNotSet_returnsDefaultTrue() {
        XCTAssertTrue(settingsManager.defaultCreateArchive)
    }

    func testDefaultMakePublic_whenNotSet_returnsDefaultFalse() {
        XCTAssertFalse(settingsManager.defaultMakePublic)
    }

    func testTrustSelfSignedCerts_whenNotSet_returnsDefaultFalse() {
        XCTAssertFalse(settingsManager.trustSelfSignedCerts)
    }

    func testDebugLoggingEnabled_whenNotSet_returnsDefaultFalse() {
        XCTAssertFalse(settingsManager.debugLoggingEnabled)
    }

    func testRecentTags_whenNotSet_returnsEmptyArray() {
        XCTAssertEqual(settingsManager.recentTags, [])
    }

    // MARK: - Setting and Retrieving Values

    func testServerURL_setAndGet() {
        settingsManager.serverURL = "https://example.com"
        XCTAssertEqual(settingsManager.serverURL, "https://example.com")
    }

    func testUsername_setAndGet() {
        settingsManager.username = "testuser"
        XCTAssertEqual(settingsManager.username, "testuser")
    }

    func testDefaultCreateArchive_setAndGet() {
        settingsManager.defaultCreateArchive = false
        XCTAssertFalse(settingsManager.defaultCreateArchive)

        settingsManager.defaultCreateArchive = true
        XCTAssertTrue(settingsManager.defaultCreateArchive)
    }

    func testDefaultMakePublic_setAndGet() {
        settingsManager.defaultMakePublic = true
        XCTAssertTrue(settingsManager.defaultMakePublic)

        settingsManager.defaultMakePublic = false
        XCTAssertFalse(settingsManager.defaultMakePublic)
    }

    func testTrustSelfSignedCerts_setAndGet() {
        settingsManager.trustSelfSignedCerts = true
        XCTAssertTrue(settingsManager.trustSelfSignedCerts)

        settingsManager.trustSelfSignedCerts = false
        XCTAssertFalse(settingsManager.trustSelfSignedCerts)
    }

    func testDebugLoggingEnabled_setAndGet() {
        settingsManager.debugLoggingEnabled = true
        XCTAssertTrue(settingsManager.debugLoggingEnabled)

        settingsManager.debugLoggingEnabled = false
        XCTAssertFalse(settingsManager.debugLoggingEnabled)
    }

    // MARK: - Recent Tags

    func testRecentTags_setAndGet() {
        settingsManager.recentTags = ["swift", "ios", "testing"]
        XCTAssertEqual(settingsManager.recentTags, ["swift", "ios", "testing"])
    }

    func testAddRecentTag_addsTagToFront() {
        settingsManager.addRecentTag("swift")
        XCTAssertEqual(settingsManager.recentTags, ["swift"])

        settingsManager.addRecentTag("ios")
        XCTAssertEqual(settingsManager.recentTags, ["ios", "swift"])
    }

    func testAddRecentTag_movesExistingTagToFront() {
        settingsManager.recentTags = ["swift", "ios", "macos"]

        settingsManager.addRecentTag("ios")
        XCTAssertEqual(settingsManager.recentTags, ["ios", "swift", "macos"])
    }

    func testAddRecentTag_doesNotDuplicate() {
        settingsManager.addRecentTag("swift")
        settingsManager.addRecentTag("swift")
        XCTAssertEqual(settingsManager.recentTags, ["swift"])
    }

    func testAddRecentTags_preservesOrder() {
        settingsManager.addRecentTags(["swift", "ios", "macos"])
        // addRecentTags processes in reverse, so the first tag ends up at the front
        XCTAssertEqual(settingsManager.recentTags, ["swift", "ios", "macos"])
    }

    func testAddRecentTags_movesExistingTagsToFront() {
        settingsManager.recentTags = ["testing", "xcode"]

        settingsManager.addRecentTags(["swift", "testing"])
        XCTAssertEqual(settingsManager.recentTags, ["swift", "testing", "xcode"])
    }

    func testRecentTags_limitedToMaxRecentTags() {
        // Create array with more than maxRecentTags (50)
        let tags = (0..<60).map { "tag\($0)" }

        settingsManager.recentTags = tags
        XCTAssertEqual(settingsManager.recentTags.count, AppConstants.Defaults.maxRecentTags)
        XCTAssertEqual(settingsManager.recentTags.count, 50)
    }

    func testAddRecentTag_respectsMaxLimit() {
        // Fill up to max
        let tags = (0..<50).map { "tag\($0)" }
        settingsManager.recentTags = tags

        // Add one more
        settingsManager.addRecentTag("newtag")

        // Should still be at max, with new tag at front
        XCTAssertEqual(settingsManager.recentTags.count, 50)
        XCTAssertEqual(settingsManager.recentTags.first, "newtag")
    }

    // MARK: - Token Cache

    func testLegacySessionCacheIsIgnoredOnUpgrade() {
        testDefaults.set("legacy-session", forKey: "cachedSessionID")
        testDefaults.set(Date(), forKey: "sessionTimestamp")
        XCTAssertNil(settingsManager.cachedToken)
        XCTAssertFalse(settingsManager.isTokenValid)
    }

    func testCachedToken_setAndGet() {
        settingsManager.cachedToken = "jwt123"
        XCTAssertEqual(settingsManager.cachedToken, "jwt123")
    }

    func testTokenTimestamp_setAndGet() {
        let now = Date()
        settingsManager.tokenTimestamp = now
        XCTAssertNotNil(settingsManager.tokenTimestamp)
        if let timestamp = settingsManager.tokenTimestamp {
            XCTAssertEqual(timestamp.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
        }
    }

    func testIsTokenValid_withNoToken_returnsFalse() {
        XCTAssertFalse(settingsManager.isTokenValid)
    }

    func testIsTokenValid_withNoTimestamp_returnsFalse() {
        settingsManager.cachedToken = "jwt123"
        XCTAssertFalse(settingsManager.isTokenValid)
    }

    func testIsTokenValid_withRecentTimestamp_returnsTrue() {
        settingsManager.cachedToken = "jwt123"
        settingsManager.tokenTimestamp = Date()
        XCTAssertTrue(settingsManager.isTokenValid)
    }

    func testIsTokenValid_withExpiredTimestamp_returnsFalse() {
        settingsManager.cachedToken = "jwt123"
        // Set timestamp to more than tokenCacheExpiry (3600 seconds) ago
        settingsManager.tokenTimestamp = Date().addingTimeInterval(-3601)
        XCTAssertFalse(settingsManager.isTokenValid)
    }

    func testIsTokenValid_withTimestampJustBeforeExpiry_returnsTrue() {
        settingsManager.cachedToken = "jwt123"
        // Set timestamp to just under tokenCacheExpiry (3600 seconds) ago
        settingsManager.tokenTimestamp = Date().addingTimeInterval(-3599)
        XCTAssertTrue(settingsManager.isTokenValid)
    }

    func testClearToken_clearsToken() {
        settingsManager.cachedToken = "jwt123"
        settingsManager.tokenTimestamp = Date()

        settingsManager.clearToken()

        XCTAssertNil(settingsManager.cachedToken)
    }

    func testClearToken_clearsTimestamp() {
        settingsManager.cachedToken = "jwt123"
        settingsManager.tokenTimestamp = Date()

        settingsManager.clearToken()

        XCTAssertNil(settingsManager.tokenTimestamp)
    }

    func testClearToken_invalidatesToken() {
        settingsManager.cachedToken = "jwt123"
        settingsManager.tokenTimestamp = Date()

        settingsManager.clearToken()

        XCTAssertFalse(settingsManager.isTokenValid)
    }

    // MARK: - Reset to Defaults

    func testResetToDefaults_restoresDefaultCreateArchive() {
        settingsManager.defaultCreateArchive = false
        settingsManager.resetToDefaults()
        XCTAssertTrue(settingsManager.defaultCreateArchive)
    }

    func testResetToDefaults_restoresDefaultMakePublic() {
        settingsManager.defaultMakePublic = true
        settingsManager.resetToDefaults()
        XCTAssertFalse(settingsManager.defaultMakePublic)
    }

    func testResetToDefaults_restoresTrustSelfSignedCerts() {
        settingsManager.trustSelfSignedCerts = true
        settingsManager.resetToDefaults()
        XCTAssertFalse(settingsManager.trustSelfSignedCerts)
    }

    func testResetToDefaults_restoresDebugLoggingEnabled() {
        settingsManager.debugLoggingEnabled = true
        settingsManager.resetToDefaults()
        XCTAssertFalse(settingsManager.debugLoggingEnabled)
    }

    func testResetToDefaults_clearsRecentTags() {
        settingsManager.recentTags = ["swift", "ios", "macos"]
        settingsManager.resetToDefaults()
        XCTAssertEqual(settingsManager.recentTags, [])
    }

    func testResetToDefaults_clearsToken() {
        settingsManager.cachedToken = "jwt123"
        settingsManager.tokenTimestamp = Date()

        settingsManager.resetToDefaults()

        XCTAssertNil(settingsManager.cachedToken)
        XCTAssertNil(settingsManager.tokenTimestamp)
        XCTAssertFalse(settingsManager.isTokenValid)
    }
}

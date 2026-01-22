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

    // MARK: - Session Cache

    func testCachedSessionID_setAndGet() {
        settingsManager.cachedSessionID = "session123"
        XCTAssertEqual(settingsManager.cachedSessionID, "session123")
    }

    func testSessionTimestamp_setAndGet() {
        let now = Date()
        settingsManager.sessionTimestamp = now
        XCTAssertNotNil(settingsManager.sessionTimestamp)
        if let timestamp = settingsManager.sessionTimestamp {
            XCTAssertEqual(timestamp.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
        }
    }

    func testIsSessionValid_withNoSession_returnsFalse() {
        XCTAssertFalse(settingsManager.isSessionValid)
    }

    func testIsSessionValid_withNoTimestamp_returnsFalse() {
        settingsManager.cachedSessionID = "session123"
        XCTAssertFalse(settingsManager.isSessionValid)
    }

    func testIsSessionValid_withRecentTimestamp_returnsTrue() {
        settingsManager.cachedSessionID = "session123"
        settingsManager.sessionTimestamp = Date()
        XCTAssertTrue(settingsManager.isSessionValid)
    }

    func testIsSessionValid_withExpiredTimestamp_returnsFalse() {
        settingsManager.cachedSessionID = "session123"
        // Set timestamp to more than sessionCacheExpiry (3600 seconds) ago
        settingsManager.sessionTimestamp = Date().addingTimeInterval(-3601)
        XCTAssertFalse(settingsManager.isSessionValid)
    }

    func testIsSessionValid_withTimestampJustBeforeExpiry_returnsTrue() {
        settingsManager.cachedSessionID = "session123"
        // Set timestamp to just under sessionCacheExpiry (3600 seconds) ago
        settingsManager.sessionTimestamp = Date().addingTimeInterval(-3599)
        XCTAssertTrue(settingsManager.isSessionValid)
    }

    func testClearSession_clearsSessionID() {
        settingsManager.cachedSessionID = "session123"
        settingsManager.sessionTimestamp = Date()

        settingsManager.clearSession()

        XCTAssertNil(settingsManager.cachedSessionID)
    }

    func testClearSession_clearsTimestamp() {
        settingsManager.cachedSessionID = "session123"
        settingsManager.sessionTimestamp = Date()

        settingsManager.clearSession()

        XCTAssertNil(settingsManager.sessionTimestamp)
    }

    func testClearSession_invalidatesSession() {
        settingsManager.cachedSessionID = "session123"
        settingsManager.sessionTimestamp = Date()

        settingsManager.clearSession()

        XCTAssertFalse(settingsManager.isSessionValid)
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

    func testResetToDefaults_clearsSession() {
        settingsManager.cachedSessionID = "session123"
        settingsManager.sessionTimestamp = Date()

        settingsManager.resetToDefaults()

        XCTAssertNil(settingsManager.cachedSessionID)
        XCTAssertNil(settingsManager.sessionTimestamp)
        XCTAssertFalse(settingsManager.isSessionValid)
    }
}

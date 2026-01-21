import Foundation

enum AppConstants {
    
    // MARK: - Bundle Identifiers
    static let mainAppBundleID = "net.emberson.shiorishare"
    static let shareExtensionBundleID = "net.emberson.shiorishare.ShareExtension"
    
    // MARK: - Shared Access Groups
    static let appGroupID = "group.net.emberson.shiorishare"
    static let keychainAccessGroup = "net.emberson.shiorishare.shared"
    
    // MARK: - Keychain Keys
    enum KeychainKey {
        static let serverURL = "shiori.serverURL"
        static let username = "shiori.username"
        static let password = "shiori.password"
    }
    
    // MARK: - UserDefaults Keys
    enum DefaultsKey {
        static let defaultCreateArchive = "defaultCreateArchive"
        static let defaultMakePublic = "defaultMakePublic"
        static let recentTags = "recentTags"
        static let trustSelfSignedCerts = "trustSelfSignedCerts"
        static let debugLoggingEnabled = "debugLoggingEnabled"
        static let cachedSessionID = "cachedSessionID"
        static let sessionTimestamp = "sessionTimestamp"
    }
    
    // MARK: - Default Values
    enum Defaults {
        static let createArchive = true
        static let makePublic = false
        static let trustSelfSignedCerts = false
        static let debugLoggingEnabled = false
        static let maxRecentTags = 50
    }
    
    // MARK: - API Endpoints
    // Login uses v1 API, bookmarks use legacy API (more stable)
    enum API {
        static let loginPath = "/api/v1/auth/login"
        static let bookmarksPath = "/api/bookmarks"
        static let tagsPath = "/api/tags"
        static let logoutPath = "/api/logout"
    }
    
    // MARK: - Timing
    enum Timing {
        static let successAutoCloseDelay: TimeInterval = 1.5
        static let sessionCacheExpiry: TimeInterval = 3600 // 1 hour
        static let networkTimeout: TimeInterval = 30
        static let debugLogRetentionDays = 7
    }
}

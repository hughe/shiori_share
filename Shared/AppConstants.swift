import Foundation
import Security

enum AppConstants {
    
    // MARK: - Bundle Identifiers
    static let mainAppBundleID = "net.emberson.shiorishare"
    static let shareExtensionBundleID = "net.emberson.shiorishare.ShareExtension"
    
    // MARK: - Shared Access Groups
    static let appGroupID = "group.net.emberson.shiorishare"
    static let keychainAccessGroup: String = {
        guard let teamID = getTeamID() else {
            return "net.emberson.shiorishare.shared"
        }
        return "\(teamID).net.emberson.shiorishare.shared"
    }()
    
    private static func getTeamID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "teamid.probe",
            kSecAttrService as String: "teamid.probe",
            kSecReturnAttributes as String: true
        ]
        
        var result: AnyObject?
        var status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "teamid.probe",
                kSecAttrService as String: "teamid.probe",
                kSecValueData as String: "probe".data(using: .utf8)!
            ]
            status = SecItemAdd(addQuery as CFDictionary, nil)
            guard status == errSecSuccess else { return nil }
            status = SecItemCopyMatching(query as CFDictionary, &result)
        }
        
        guard status == errSecSuccess,
              let attributes = result as? [String: Any],
              let accessGroup = attributes[kSecAttrAccessGroup as String] as? String else {
            return nil
        }
        
        let components = accessGroup.split(separator: ".")
        guard let teamID = components.first else { return nil }
        return String(teamID)
    }
    
    // MARK: - Keychain Keys (password only - other settings use UserDefaults)
    enum KeychainKey {
        static let password = "shiori.password"
    }
    
    // MARK: - UserDefaults Keys
    enum DefaultsKey {
        static let serverURL = "serverURL"
        static let username = "username"
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
        static let displayedTagChips = 10
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

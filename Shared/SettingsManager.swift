import Foundation

final class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults: UserDefaults
    
    private init() {
        defaults = UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard
    }
    
    // MARK: - Bookmark Defaults
    
    var defaultCreateArchive: Bool {
        get {
            if defaults.object(forKey: AppConstants.DefaultsKey.defaultCreateArchive) == nil {
                return AppConstants.Defaults.createArchive
            }
            return defaults.bool(forKey: AppConstants.DefaultsKey.defaultCreateArchive)
        }
        set {
            defaults.set(newValue, forKey: AppConstants.DefaultsKey.defaultCreateArchive)
        }
    }
    
    var defaultMakePublic: Bool {
        get {
            if defaults.object(forKey: AppConstants.DefaultsKey.defaultMakePublic) == nil {
                return AppConstants.Defaults.makePublic
            }
            return defaults.bool(forKey: AppConstants.DefaultsKey.defaultMakePublic)
        }
        set {
            defaults.set(newValue, forKey: AppConstants.DefaultsKey.defaultMakePublic)
        }
    }
    
    // MARK: - Security Settings
    
    var trustSelfSignedCerts: Bool {
        get {
            if defaults.object(forKey: AppConstants.DefaultsKey.trustSelfSignedCerts) == nil {
                return AppConstants.Defaults.trustSelfSignedCerts
            }
            return defaults.bool(forKey: AppConstants.DefaultsKey.trustSelfSignedCerts)
        }
        set {
            defaults.set(newValue, forKey: AppConstants.DefaultsKey.trustSelfSignedCerts)
        }
    }
    
    // MARK: - Debug Settings
    
    var debugLoggingEnabled: Bool {
        get {
            if defaults.object(forKey: AppConstants.DefaultsKey.debugLoggingEnabled) == nil {
                return AppConstants.Defaults.debugLoggingEnabled
            }
            return defaults.bool(forKey: AppConstants.DefaultsKey.debugLoggingEnabled)
        }
        set {
            defaults.set(newValue, forKey: AppConstants.DefaultsKey.debugLoggingEnabled)
        }
    }
    
    // MARK: - Recent Tags
    
    var recentTags: [String] {
        get {
            defaults.stringArray(forKey: AppConstants.DefaultsKey.recentTags) ?? []
        }
        set {
            let limited = Array(newValue.prefix(AppConstants.Defaults.maxRecentTags))
            defaults.set(limited, forKey: AppConstants.DefaultsKey.recentTags)
        }
    }
    
    func addRecentTag(_ tag: String) {
        var tags = recentTags.filter { $0 != tag }
        tags.insert(tag, at: 0)
        recentTags = tags
    }
    
    func addRecentTags(_ newTags: [String]) {
        for tag in newTags.reversed() {
            addRecentTag(tag)
        }
    }
    
    // MARK: - Session Cache
    
    var cachedSessionID: String? {
        get { defaults.string(forKey: AppConstants.DefaultsKey.cachedSessionID) }
        set { defaults.set(newValue, forKey: AppConstants.DefaultsKey.cachedSessionID) }
    }
    
    var sessionTimestamp: Date? {
        get { defaults.object(forKey: AppConstants.DefaultsKey.sessionTimestamp) as? Date }
        set { defaults.set(newValue, forKey: AppConstants.DefaultsKey.sessionTimestamp) }
    }
    
    var isSessionValid: Bool {
        guard cachedSessionID != nil,
              let timestamp = sessionTimestamp else {
            return false
        }
        return Date().timeIntervalSince(timestamp) < AppConstants.Timing.sessionCacheExpiry
    }
    
    func clearSession() {
        cachedSessionID = nil
        sessionTimestamp = nil
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        defaultCreateArchive = AppConstants.Defaults.createArchive
        defaultMakePublic = AppConstants.Defaults.makePublic
        trustSelfSignedCerts = AppConstants.Defaults.trustSelfSignedCerts
        debugLoggingEnabled = AppConstants.Defaults.debugLoggingEnabled
        recentTags = []
        clearSession()
    }
}

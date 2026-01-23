import Foundation

final class SettingsManager {
    static let shared = SettingsManager()

    private let defaults: UserDefaults
    private let standardDefaults = UserDefaults.standard

    private init() {
        defaults = UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard
        registerDefaults()
        #if !SHARE_EXTENSION
        syncFromSettingsBundle()
        #endif
    }

    // Internal initializer for testing
    internal init(defaults: UserDefaults) {
        self.defaults = defaults
    }
    
    private func registerDefaults() {
        let defaultValues: [String: Any] = [
            AppConstants.DefaultsKey.defaultCreateArchive: AppConstants.Defaults.createArchive,
            AppConstants.DefaultsKey.defaultMakePublic: AppConstants.Defaults.makePublic,
            AppConstants.DefaultsKey.trustSelfSignedCerts: AppConstants.Defaults.trustSelfSignedCerts,
            AppConstants.DefaultsKey.debugLoggingEnabled: AppConstants.Defaults.debugLoggingEnabled,
            AppConstants.DefaultsKey.resetPassword: false
        ]
        defaults.register(defaults: defaultValues)
        standardDefaults.register(defaults: defaultValues)
    }
    
    #if !SHARE_EXTENSION
    func syncFromSettingsBundle() {
        let keys = [
            AppConstants.DefaultsKey.serverURL,
            AppConstants.DefaultsKey.username,
            AppConstants.DefaultsKey.defaultCreateArchive,
            AppConstants.DefaultsKey.defaultMakePublic,
            AppConstants.DefaultsKey.trustSelfSignedCerts,
            AppConstants.DefaultsKey.debugLoggingEnabled,
            AppConstants.DefaultsKey.resetPassword
        ]
        
        for key in keys {
            if let value = standardDefaults.object(forKey: key) {
                defaults.set(value, forKey: key)
            }
        }
    }
    #endif
    
    // MARK: - Server Credentials (non-secret)
    
    var serverURL: String? {
        get { defaults.string(forKey: AppConstants.DefaultsKey.serverURL) }
        set { defaults.set(newValue, forKey: AppConstants.DefaultsKey.serverURL) }
    }
    
    var username: String? {
        get { defaults.string(forKey: AppConstants.DefaultsKey.username) }
        set { defaults.set(newValue, forKey: AppConstants.DefaultsKey.username) }
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
    
    // MARK: - Password Reset Flag
    
    var resetPassword: Bool {
        get { defaults.bool(forKey: AppConstants.DefaultsKey.resetPassword) }
        set {
            defaults.set(newValue, forKey: AppConstants.DefaultsKey.resetPassword)
            standardDefaults.set(newValue, forKey: AppConstants.DefaultsKey.resetPassword)
        }
    }
    
    func checkAndClearPasswordResetFlag() -> Bool {
        if resetPassword {
            resetPassword = false
            return true
        }
        return false
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

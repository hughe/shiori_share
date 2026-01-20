import Foundation
import Security

enum KeychainError: LocalizedError {
    case unableToSave(OSStatus)
    case unableToRead(OSStatus)
    case unableToDelete(OSStatus)
    case unexpectedData
    case itemNotFound
    
    var errorDescription: String? {
        switch self {
        case .unableToSave(let status):
            return "Unable to save to Keychain (OSStatus: \(status))"
        case .unableToRead(let status):
            return "Unable to read from Keychain (OSStatus: \(status))"
        case .unableToDelete(let status):
            return "Unable to delete from Keychain (OSStatus: \(status))"
        case .unexpectedData:
            return "Unexpected data format in Keychain"
        case .itemNotFound:
            return "Item not found in Keychain"
        }
    }
}

final class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let accessGroup = AppConstants.keychainAccessGroup
    private let service = AppConstants.mainAppBundleID
    
    private init() {}
    
    // MARK: - Save
    
    func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        try delete(forKey: key)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        #if !targetEnvironment(simulator)
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }
    
    // MARK: - Read
    
    func read(forKey key: String) throws -> String {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        #if !targetEnvironment(simulator)
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToRead(status)
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        return string
    }
    
    func readOptional(forKey key: String) -> String? {
        try? read(forKey: key)
    }
    
    // MARK: - Delete
    
    @discardableResult
    func delete(forKey key: String) throws -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        #if !targetEnvironment(simulator)
        query[kSecAttrAccessGroup as String] = accessGroup
        #endif
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
        
        return status == errSecSuccess
    }
    
    // MARK: - Convenience Methods for Shiori Credentials
    
    var serverURL: String? {
        get { readOptional(forKey: AppConstants.KeychainKey.serverURL) }
        set {
            if let value = newValue {
                try? save(value, forKey: AppConstants.KeychainKey.serverURL)
            } else {
                try? delete(forKey: AppConstants.KeychainKey.serverURL)
            }
        }
    }
    
    var username: String? {
        get { readOptional(forKey: AppConstants.KeychainKey.username) }
        set {
            if let value = newValue {
                try? save(value, forKey: AppConstants.KeychainKey.username)
            } else {
                try? delete(forKey: AppConstants.KeychainKey.username)
            }
        }
    }
    
    var password: String? {
        get { readOptional(forKey: AppConstants.KeychainKey.password) }
        set {
            if let value = newValue {
                try? save(value, forKey: AppConstants.KeychainKey.password)
            } else {
                try? delete(forKey: AppConstants.KeychainKey.password)
            }
        }
    }
    
    var hasCredentials: Bool {
        serverURL != nil && username != nil && password != nil
    }
    
    func clearAllCredentials() {
        try? delete(forKey: AppConstants.KeychainKey.serverURL)
        try? delete(forKey: AppConstants.KeychainKey.username)
        try? delete(forKey: AppConstants.KeychainKey.password)
    }
}

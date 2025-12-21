// KeychainManager.swift
// Falla - iOS 26 Fortune Telling App
// Secure token storage using iOS Keychain

import Foundation
import Security

// MARK: - Keychain Manager
/// Secure storage for authentication tokens and sensitive data
final class KeychainManager {
    // MARK: - Singleton
    static let shared = KeychainManager()
    
    // MARK: - Constants
    private let serviceName = "com.falla.app"
    
    private enum KeychainKey: String {
        case authToken = "auth_token"
        case refreshToken = "refresh_token"
        case userId = "user_id"
        case fcmToken = "fcm_token"
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save authentication token
    func saveAuthToken(_ token: String) throws {
        try save(token, for: .authToken)
    }
    
    /// Get authentication token
    func getAuthToken() -> String? {
        return get(for: .authToken)
    }
    
    /// Delete authentication token
    func deleteAuthToken() throws {
        try delete(for: .authToken)
    }
    
    /// Save refresh token
    func saveRefreshToken(_ token: String) throws {
        try save(token, for: .refreshToken)
    }
    
    /// Get refresh token
    func getRefreshToken() -> String? {
        return get(for: .refreshToken)
    }
    
    /// Delete refresh token
    func deleteRefreshToken() throws {
        try delete(for: .refreshToken)
    }
    
    /// Save user ID
    func saveUserId(_ userId: String) throws {
        try save(userId, for: .userId)
    }
    
    /// Get user ID
    func getUserId() -> String? {
        return get(for: .userId)
    }
    
    /// Save FCM token
    func saveFCMToken(_ token: String) throws {
        try save(token, for: .fcmToken)
    }
    
    /// Get FCM token
    func getFCMToken() -> String? {
        return get(for: .fcmToken)
    }
    
    /// Clear all stored data
    func clearAll() throws {
        try delete(for: .authToken)
        try delete(for: .refreshToken)
        try delete(for: .userId)
        try delete(for: .fcmToken)
    }
    
    // MARK: - Private Methods
    
    private func save(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        // First try to update existing item
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        var status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if status == errSecItemNotFound {
            // Item doesn't exist, add it
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key.rawValue,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    private func get(for key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Keychain Error
enum KeychainError: LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case readFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for keychain"
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        case .readFailed(let status):
            return "Failed to read from keychain: \(status)"
        }
    }
}

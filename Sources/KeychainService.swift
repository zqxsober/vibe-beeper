import Foundation
import Security

/// Secure Keychain wrapper for API key storage.
/// Keys are stored as generic passwords under the app's service identifier.
/// iCloud sync is explicitly disabled to prevent third-party keys from leaving the device.
enum KeychainService {
    private static let service = "com.vecartier.cc-beeper.apikeys"
    // Migration: old service identifier used before the CC-Beeper rename
    private static let legacyService = "com.claumagotchi.apikeys"

    // MARK: - Account Constants

    static let groqAccount = "groq"
    static let openAIAccount = "openai"

    // MARK: - CRUD

    /// Save a value to the Keychain for the given account.
    /// If value is empty, the entry is deleted instead of storing an empty string.
    /// Uses upsert pattern: tries SecItemAdd first; on errSecDuplicateItem, uses SecItemUpdate.
    static func save(_ value: String, account: String) {
        guard !value.isEmpty else {
            delete(account: account)
            return
        }
        guard let data = value.data(using: .utf8) else { return }
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false // do not sync to iCloud Keychain
        ]
        var add = base
        add[kSecValueData as String] = data
        let status = SecItemAdd(add as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let attrs: [String: Any] = [kSecValueData as String: data]
            SecItemUpdate(base as CFDictionary, attrs as CFDictionary)
        }
    }

    /// Load a value from the Keychain for the given account.
    /// Falls back to legacy service identifier (com.claumagotchi.apikeys) for migration.
    /// If found in legacy service, migrates the value to the new service and deletes the old entry.
    /// Returns nil if the entry does not exist or is empty.
    static func load(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: false
        ]
        var result: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8),
           !value.isEmpty {
            return value
        }

        // Migration: check old service identifier from pre-rename Claumagotchi app
        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: legacyService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: false
        ]
        var legacyResult: CFTypeRef?
        guard SecItemCopyMatching(legacyQuery as CFDictionary, &legacyResult) == errSecSuccess,
              let legacyData = legacyResult as? Data,
              let legacyValue = String(data: legacyData, encoding: .utf8),
              !legacyValue.isEmpty else { return nil }

        // Migrate to new service and remove legacy entry
        save(legacyValue, account: account)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: legacyService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        return legacyValue
    }

    /// Delete the Keychain entry for the given account.
    /// Safe to call even if the entry does not exist.
    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

//
//  KeychainHelper.swift
//  BattleBuddy
//
//  Secure storage for API keys and sensitive data
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    // MARK: - Save
    func save(_ data: String, forKey key: String) -> Bool {
        guard let data = data.data(using: .utf8) else { return false }

        // Delete any existing item
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Retrieve
    func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    // MARK: - Delete
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Convenience for OpenAI API Key
    var openAIKey: String? {
        get { retrieve(forKey: "openai_api_key") }
        set {
            if let newValue = newValue {
                _ = save(newValue, forKey: "openai_api_key")
            } else {
                _ = delete(forKey: "openai_api_key")
            }
        }
    }
}

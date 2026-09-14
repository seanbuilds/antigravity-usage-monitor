// Sources/SharedQuotaKit/Security/KeychainHelper.swift
import Foundation
import Security

public enum KeychainHelper {
    public static func readPassword(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public static func savePassword(service: String, account: String, password: String) -> Bool {
        guard let data = password.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if status == errSecSuccess {
            return true
        } else if status == errSecItemNotFound {
            var newQuery = query
            newQuery[kSecValueData as String] = data
            return SecItemAdd(newQuery as CFDictionary, nil) == errSecSuccess
        }
        return false
    }
}

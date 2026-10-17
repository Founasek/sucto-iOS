//
//  KeychainStore.swift
//  SuctoApp
//

import Foundation
import Security

enum KeychainStore {
    private static let service = "cz.sucto.SuctoApp"

    static func read(_ key: String) -> String? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Vrací `false`, pokud se hodnotu nepodařilo uložit (volající tak ví, že po restartu nebude k dispozici).
    @discardableResult
    static func write(_ value: String, for key: String) -> Bool {
        let data = Data(value.utf8)
        let status = SecItemUpdate(baseQuery(key) as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecSuccess { return true }
        // Chybějící nebo poškozená položka: smazat a založit znovu.
        SecItemDelete(baseQuery(key) as CFDictionary)
        var add = baseQuery(key)
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func delete(_ key: String) {
        SecItemDelete(baseQuery(key) as CFDictionary)
    }

    private static func baseQuery(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}

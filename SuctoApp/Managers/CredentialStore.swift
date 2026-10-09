//
//  CredentialStore.swift
//  SuctoApp
//

import Foundation
import LocalAuthentication
import Security

/// Přihlašovací údaje pro rychlé přihlášení Face ID / Touch ID.
/// Uložené jsou v Keychainu jen na tomto zařízení (nesynchronizují se do iCloudu) a čtení vyžaduje ověření
/// (biometrie, nebo kód zařízení). Nikdy se neloguje ani nezapisuje jinam.
enum CredentialStore {
    struct Credentials {
        let email: String
        let password: String
    }

    private static let service = "cz.sucto.SuctoApp.credentials"
    private static let declinedKey = "credentialSaveDeclined"

    /// Uživatel si vybral „Nikdy“ u nabídky uložení.
    static var offerDeclined: Bool {
        get { UserDefaults.standard.bool(forKey: declinedKey) }
        set { UserDefaults.standard.set(newValue, forKey: declinedKey) }
    }

    /// Zda jsou uložené údaje. Dotaz je nastavený tak, aby nikdy nevyvolal Face ID (ověření se žádá až při čtení hesla).
    static func hasSavedLogin() -> Bool {
        let context = LAContext()
        context.interactionNotAllowed = true
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    /// Uloží údaje (nahradí případné dřívější). Vrací `false`, pokud se to nepovedlo (např. zařízení nemá nastavený kód).
    @discardableResult
    static func save(_ credentials: Credentials) -> Bool {
        delete()
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .userPresence,
            nil,
        ) else { return false }

        let item: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentials.email,
            kSecValueData as String: Data(credentials.password.utf8),
            kSecAttrAccessControl as String: access,
        ]
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    /// Načte údaje; systém při tom vyžádá Face ID / Touch ID / kód. Vrací `nil` při zrušení nebo chybě.
    static func load(reason: String) async -> Credentials? {
        await Task.detached(priority: .userInitiated) {
            let context = LAContext()
            context.localizedReason = reason
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecReturnAttributes as String: true,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecUseAuthenticationContext as String: context,
            ]
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status != errSecSuccess { Log.debug("🔑 Uložené přihlášení se nepodařilo načíst (OSStatus \(status))") }
            guard status == errSecSuccess,
                  let attributes = result as? [String: Any],
                  let email = attributes[kSecAttrAccount as String] as? String,
                  let data = attributes[kSecValueData as String] as? Data,
                  let password = String(data: data, encoding: .utf8)
            else { return nil }
            return Credentials(email: email, password: password)
        }.value
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

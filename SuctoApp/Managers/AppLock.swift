//
//  AppLock.swift
//  SuctoApp
//

import LocalAuthentication
import SwiftUI

/// Zámek aplikace přes Face ID / Touch ID (s kódem zařízení jako zálohou).
/// Zamyká se při odchodu do pozadí a při studeném startu.
@MainActor
final class AppLock: ObservableObject {
    private static let enabledKey = "appLockEnabled"

    @Published private(set) var isLocked: Bool
    @Published private(set) var isEnabled: Bool
    @Published private(set) var errorMessage: String?

    /// Probíhá systémové ověření (Face ID / Touch ID / kód) – zamčená obrazovka pak neukazuje tlačítko.
    @Published private(set) var isAuthenticating = false

    init() {
        let defaults = UserDefaults.standard
        // Výchozí stav: zapnuto, pokud zařízení umí ověření (kód / biometrie).
        if defaults.object(forKey: Self.enabledKey) == nil {
            defaults.set(Self.canAuthenticate, forKey: Self.enabledKey)
        }
        let enabled = defaults.bool(forKey: Self.enabledKey) && Self.canAuthenticate
        isEnabled = enabled
        isLocked = enabled
    }

    static var canAuthenticate: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    /// „Face ID“, „Touch ID“ nebo „kód“ – podle zařízení.
    var methodName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "kód zařízení"
        }
    }

    /// SF Symbol odpovídající dostupné metodě ověření.
    var symbolName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.open.fill"
        }
    }

    /// Automatické ověření (po návratu z pozadí / při startu) už pro tohle zamčení proběhlo. Zabraňuje smyčce:
    /// zavření systémového okna Face ID vyvolá další přechod scény do stavu „aktivní“, který by ověření spustil znovu.
    private var autoPromptUsed = false

    func lock() {
        guard isEnabled, !isAuthenticating else { return }
        autoPromptUsed = false
        isLocked = true
    }

    /// Spustí ověření automaticky, ale jen jednou na jedno zamčení. Po zrušení se čeká na klepnutí na tlačítko.
    func unlockAutomatically() async {
        guard isLocked, !isAuthenticating, !autoPromptUsed else { return }
        autoPromptUsed = true
        await unlock()
    }

    /// Po čerstvém přihlášení heslem se znovu ověřovat nemusí.
    func markUnlocked() {
        isLocked = false
        errorMessage = nil
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        if await authenticate(reason: "Odemkněte aplikaci sÚčto.") {
            isLocked = false
            errorMessage = nil
        }
    }

    /// Zapnutí vyžaduje úspěšné ověření, aby si zámek nešlo omylem (nebo cizí rukou) vypnout/zapnout bez něj.
    func setEnabled(_ enabled: Bool) async {
        guard enabled != isEnabled else { return }
        guard Self.canAuthenticate else {
            errorMessage = "Na zařízení není nastavený kód ani Face ID / Touch ID."
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        let reason = enabled ? "Zapnutí zámku aplikace." : "Vypnutí zámku aplikace."
        guard await authenticate(reason: reason) else { return }
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.enabledKey)
        errorMessage = nil
    }

    private func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch let error as LAError where error.code == .userCancel || error.code == .appCancel || error.code == .systemCancel {
            return false
        } catch {
            errorMessage = "Ověření se nezdařilo."
            return false
        }
    }
}

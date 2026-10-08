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

    private var isAuthenticating = false

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

    func lock() {
        guard isEnabled, !isAuthenticating else { return }
        isLocked = true
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

/// Překryv, který skryje obsah aplikace (zámek i náhled v přepínači aplikací).
struct AppLockOverlay: View {
    @ObservedObject var lock: AppLock
    let isCovered: Bool

    var body: some View {
        ZStack {
            if lock.isEnabled, lock.isLocked || isCovered {
                ZStack {
                    Theme.background

                    VStack(spacing: Theme.Spacing.l) {
                        Image("logo-sucto")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .black.opacity(0.2), radius: 14, y: 6)
                            .accessibilityHidden(true)
                        if lock.isLocked {
                            Text("sÚčto je zamčené")
                                .font(.title3.weight(.semibold))
                            if let message = lock.errorMessage {
                                Text(message)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Button {
                                Task { await lock.unlock() }
                            } label: {
                                Label("Odemknout (\(lock.methodName))", systemImage: "faceid")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, Theme.Spacing.xxl)
                        }
                    }
                }
                .ignoresSafeArea()
                .accessibilityAddTraits(.isModal)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: lock.isLocked)
        .animation(.easeInOut(duration: 0.2), value: isCovered)
    }
}

//
//  LoginView+Actions.swift
//  SuctoApp
//

import SwiftUI

/// Přihlašovací akce: ruční přihlášení, rychlé přihlášení Face ID a nabídka uložení údajů.
extension LoginView {
    /// Tlačítko rychlého přihlášení a možnost uložené údaje zapomenout.
    var savedLoginControls: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Button(action: loginWithSaved) {
                Label("Přihlásit se přes \(appLock.methodName)", systemImage: "faceid")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            }
            .disabled(viewModel.isLoading || isBiometricInProgress)
            .accessibilityHint("Přihlásí uloženým účtem")

            Button("Zapomenout uložené přihlášení") {
                CredentialStore.delete()
                hasSavedLogin = false
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
            .padding(.top, Theme.Spacing.xs)
        }
    }

    func submit() {
        guard canSubmit else { return }
        focusedField = nil
        let credentials = CredentialStore.Credentials(email: email, password: password)
        Task {
            guard let token = await viewModel.login(email: credentials.email, password: credentials.password) else { return }
            if !hasSavedLogin, !CredentialStore.offerDeclined {
                pendingLogin = PendingLogin(token: token, credentials: credentials)
                return
            }
            // Změněné heslo u už uloženého účtu se tiše aktualizuje, ať Face ID přihlášení dál funguje.
            if hasSavedLogin { CredentialStore.save(credentials) }
            finish(token: token)
        }
    }

    /// Face ID se vyvolá jen klepnutím na tlačítko, nikdy samo.
    func loginWithSaved() {
        guard !isBiometricInProgress else { return }
        isBiometricInProgress = true
        Task {
            defer { isBiometricInProgress = false }
            guard let credentials = await CredentialStore.load(reason: "Přihlášení do sÚčta") else { return }
            if let token = await viewModel.login(email: credentials.email, password: credentials.password) {
                finish(token: token)
            }
        }
    }

    func finishPendingLogin(save: Bool) {
        guard let pending = pendingLogin else { return }
        pendingLogin = nil
        if save {
            if CredentialStore.save(pending.credentials) {
                hasSavedLogin = true
            } else {
                showSaveFailed = true
            }
        }
        finish(token: pending.token)
    }

    func finish(token: String) {
        // Odemknout dřív než se přepne obrazovka, aby zamčený překryv ani na okamžik neproblikl.
        appLock.markUnlocked()
        session.login(token: token)
    }
}

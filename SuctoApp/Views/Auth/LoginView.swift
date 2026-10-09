//
//  LoginView.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var email = DevCredentials.email
    @State private var password = DevCredentials.password
    @FocusState private var focusedField: Field?
    /// Jsou uložené údaje pro Face ID přihlášení? Zjišťuje se jednou při zobrazení, ne při každém překreslení.
    @State private var hasSavedLogin = false
    /// Po úspěšném ručním přihlášení čeká na odpověď na „Uložit přihlášení?“.
    @State private var pendingLogin: PendingLogin?
    @State private var showSaveFailed = false
    /// Ověření Face ID právě probíhá – další klepnutí se ignorují (jinak by se dotazy hromadily).
    @State private var isBiometricInProgress = false

    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var appLock: AppLock

    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 22

    private enum Field { case email, password }

    private struct PendingLogin {
        let token: String
        let credentials: CredentialStore.Credentials
    }

    private var canSubmit: Bool {
        !viewModel.isLoading && !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        ZStack {
            background

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        header
                            .padding(.top, 72)

                        Spacer(minLength: Theme.Spacing.xl)

                        formCard
                            .appear(delay: 0.35, offset: 80, scale: 1)
                            .padding(.horizontal, Theme.Spacing.l)
                            .padding(.bottom, Theme.Spacing.l)
                    }
                    .frame(minHeight: proxy.size.height)
                    .animation(.snappy, value: viewModel.errorMessage)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { hasSavedLogin = CredentialStore.hasSavedLogin() }
        .alert("Uložit přihlášení?", isPresented: Binding(
            get: { pendingLogin != nil },
            set: { if !$0 { finishPendingLogin(save: false) } },
        )) {
            Button("Uložit") { finishPendingLogin(save: true) }
            Button("Teď ne", role: .cancel) { finishPendingLogin(save: false) }
            Button("Nikdy", role: .destructive) {
                CredentialStore.offerDeclined = true
                finishPendingLogin(save: false)
            }
        } message: {
            Text("Příště se přihlásíte přes \(appLock.methodName). Údaje se uloží jen do zabezpečeného úložiště tohoto zařízení.")
        }
        .alert("Přihlášení se nepodařilo uložit", isPresented: $showSaveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Uložení vyžaduje, aby bylo na zařízení nastavené heslo nebo Face ID / Touch ID.")
        }
    }

    // MARK: - Části

    private var background: some View {
        AnimatedMeshBackground()
    }

    private var formCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            field(icon: "envelope") {
                TextField("E-mail", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }

            field(icon: "lock") {
                SecureField("Heslo", text: $password)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit(submit)
            }

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(Theme.Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.55), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Button(action: submit) {
                ZStack {
                    Text("Přihlásit se").opacity(viewModel.isLoading ? 0 : 1)
                    if viewModel.isLoading { ProgressView().tint(.white) }
                }
            }
            .buttonStyle(.primary)
            .disabled(!canSubmit)
            .padding(.top, Theme.Spacing.s)

            if hasSavedLogin {
                savedLoginControls
            }
        }
        .padding(Theme.Spacing.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.18), lineWidth: 0.5))
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image("logo-sucto")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
                .appear(delay: 0.05, offset: 0, scale: 0.5)
                .accessibilityHidden(true)

            Text("Vítejte zpět")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .appear(delay: 0.18, offset: 14)
            Text("Přihlaste se do svého účetnictví sÚčto")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .appear(delay: 0.26, offset: 14)
        }
    }

    private func field(icon: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            content()
                .foregroundStyle(.white)
                .tint(Theme.brand)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .frame(minHeight: 54)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    /// Tlačítko rychlého přihlášení a možnost uložené údaje zapomenout.
    private var savedLoginControls: some View {
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

    private func submit() {
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
    private func loginWithSaved() {
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

    private func finishPendingLogin(save: Bool) {
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

    private func finish(token: String) {
        // Odemknout dřív než se přepne obrazovka, aby zamčený překryv ani na okamžik neproblikl.
        appLock.markUnlocked()
        session.login(token: token)
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionManager())
        .environmentObject(AppLock())
}

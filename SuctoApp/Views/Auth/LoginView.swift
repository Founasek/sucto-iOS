//
//  LoginView.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    @State var email = DevCredentials.email
    @State var password = DevCredentials.password
    @FocusState var focusedField: Field?
    /// Jsou uložené údaje pro Face ID přihlášení? Zjišťuje se jednou při zobrazení, ne při každém překreslení.
    @State var hasSavedLogin = false
    /// Po úspěšném ručním přihlášení čeká na odpověď na „Uložit přihlášení?“.
    @State var pendingLogin: PendingLogin?
    @State var showSaveFailed = false
    /// Ověření Face ID právě probíhá – další klepnutí se ignorují (jinak by se dotazy hromadily).
    @State var isBiometricInProgress = false

    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var appLock: AppLock

    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 22

    enum Field { case email, password }

    struct PendingLogin {
        let token: String
        let credentials: CredentialStore.Credentials
    }

    var canSubmit: Bool {
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
}

#Preview {
    LoginView()
        .environmentObject(SessionManager())
        .environmentObject(AppLock())
}

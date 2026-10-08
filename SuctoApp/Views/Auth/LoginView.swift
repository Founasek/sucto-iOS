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

    @EnvironmentObject private var session: SessionManager

    private enum Field { case email, password }

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
                .frame(width: 22)
            content()
                .foregroundStyle(.white)
                .tint(Theme.brand)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .frame(height: 54)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    private func submit() {
        guard canSubmit else { return }
        focusedField = nil
        Task {
            if let token = await viewModel.login(email: email, password: password) {
                session.login(token: token)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionManager())
}

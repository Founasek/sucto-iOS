//
//  LoginView.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var email = "honzafoune@seznam.cz"
    @State private var password = "0702090071Cfbu"

    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject private var session: SessionManager
    @AppStorage("authToken") private var authToken: String?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("logo-text-sucto")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 50)
                .padding(.bottom, 40)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            SecureField("Heslo", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            Spacer()

            Button {
                Task {
                    await viewModel.login(email: email, password: password)
                    if let token = viewModel.token {
                        session.login(token: token)
                    }
                }
            } label: {
                Text("Přihlásit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(NavigationManager())
    }
}

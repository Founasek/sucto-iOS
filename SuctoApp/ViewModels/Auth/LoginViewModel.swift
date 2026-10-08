//
//  LoginViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false

    private struct Credentials: Encodable {
        let email: String
        let password: String
    }

    /// Vrací token při úspěšném přihlášení.
    func login(email: String, password: String) async -> String? {
        isLoading = true
        defer { isLoading = false }
        do {
            let body = try JSONEncoder().encode(Credentials(email: email, password: password))
            let response: LoginResponse = try await APIService.shared.request(
                endpoint: APIConstants.loginEndpoint,
                method: .POST,
                body: body,
            )
            errorMessage = nil
            return response.authenticationToken
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

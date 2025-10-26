//
//  LoginViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//


import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    @Published var token: String?
    @Published var errorMessage: String?

    func login(email: String, password: String) async {
        let body = ["email": email, "password": password]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            let response: LoginResponse = try await APIService.shared.request(
                endpoint: APIConstants.loginEndpoint,
                method: .POST,
                body: jsonData
            )
            token = response.authentication_token
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


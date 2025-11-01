//
//  AccountsViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 07.10.2025.
//

import SwiftUI

@MainActor
class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var errorMessage: String?

    private var companyId: Int
    private var session: SessionManager

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    func fetchAccounts() async {
        guard let token = session.authToken else {
            errorMessage = "Token není k dispozici"
            return
        }

        do {
            let result: [Account] = try await APIService.shared.request(
                endpoint: "companies/\(companyId)/accounts",
                method: .GET,
                token: token
            )
            accounts = result
            errorMessage = nil
        } catch APIError.unauthorized {
            session.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

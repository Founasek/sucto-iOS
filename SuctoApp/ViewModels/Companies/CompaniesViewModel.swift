//
//  CompaniesViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

@MainActor
class CompaniesViewModel: ObservableObject {
    @Published var companies: [Company] = []
    @Published var errorMessage: String?

    private var session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    func fetchCompanies() async {
        guard let token = session.authToken else {
            errorMessage = "Token není k dispozici"
            return
        }

        do {
            let result: [Company] = try await APIService.shared.request(
                endpoint: APIConstants.getCompanies(),
                method: .GET,
                token: token
            )
            companies = result
            errorMessage = nil
        } catch APIError.unauthorized {
            session.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectCompany(_ company: Company) {
        session.selectedCompanyId = company.id
    }
}

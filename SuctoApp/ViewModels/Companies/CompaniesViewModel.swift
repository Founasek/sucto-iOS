//
//  CompaniesViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

@MainActor
final class CompaniesViewModel: ObservableObject {
    @Published var companies: [Company] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    func fetchCompanies() async {
        // Při pull-to-refresh nechceme zahodit už zobrazený seznam.
        isLoading = companies.isEmpty
        defer { isLoading = false }

        do {
            companies = try await session.send(APIConstants.companies)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectCompany(_ company: Company) {
        session.selectedCompany = company
    }
}

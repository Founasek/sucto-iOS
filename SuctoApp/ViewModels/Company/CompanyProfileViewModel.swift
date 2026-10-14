//
//  CompanyProfileViewModel.swift
//  SuctoApp
//

import SwiftUI

/// Profil vybrané firmy: detail firmy (účty drží `AccountsViewModel`).
@MainActor
final class CompanyProfileViewModel: ObservableObject {
    @Published private(set) var detail: CompanyDetail?
    @Published private(set) var errorMessage: String?

    let companyId: Int
    private let session: SessionManager

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    func load() async {
        async let loadedDetail: CompanyDetail = session.send(APIConstants.company(companyId: companyId))
        do {
            detail = try await loadedDetail
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

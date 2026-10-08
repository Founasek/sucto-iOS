//
//  AccountsViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 07.10.2025.
//

import SwiftUI

@MainActor
final class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published private(set) var currencies: [Currency] = []
    @Published var errorMessage: String?

    private let companyId: Int
    private let session: SessionManager

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    func currencySymbol(for account: Account) -> String? {
        currencies.first { $0.id == account.currencyId }.flatMap { $0.symbol ?? $0.isoCode }
    }

    func fetchAccounts() async {
        do {
            async let loadedAccounts: [Account] = session.send(APIConstants.bankAccounts(companyId: companyId))
            // Měny jsou jen doplněk (symbol u zůstatku), jejich selhání nesmí shodit seznam účtů.
            async let loadedCurrencies: [Currency]? = try? session.send(APIConstants.currencies)
            accounts = try await loadedAccounts
            currencies = await loadedCurrencies ?? currencies
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

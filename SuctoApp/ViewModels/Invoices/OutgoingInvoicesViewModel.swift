//
//  InvoicesViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import SwiftUI

@MainActor
class OutgoingInvoicesViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var successMessage: String?
    @Published var errorMessage: String?
    @Published var isLoadingPage = false
    @Published var hasMorePages = true

    private var currentPage = 1
    let companyId: Int
    var session: SessionManager

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    func resetPagination() {
        currentPage = 1
        hasMorePages = true
        invoices.removeAll()
    }

    func fetchInvoices(page: Int? = nil) async {
        guard let token = session.authToken else {
            errorMessage = "Token není k dispozici"
            return
        }

        guard !isLoadingPage && hasMorePages else { return }

        isLoadingPage = true

        let pageToLoad = page ?? currentPage

        do {
            let result: [Invoice] = try await APIService.shared.request(
                endpoint: "companies/\(companyId)/actuarials_outs?page=\(pageToLoad)",
                method: .GET,
                token: token
            )

            if result.isEmpty {
                hasMorePages = false
            } else {
                if pageToLoad == 1 {
                    invoices = result
                } else {
                    invoices.append(contentsOf: result)
                }
                currentPage += 1
            }

            errorMessage = nil
            print("✅ Načtena stránka \(pageToLoad), počet faktur: \(result.count)")
        } catch APIError.unauthorized {
            session.logout()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingPage = false
    }

    func payInvoice(invoiceId: Int) async {
        guard let token = session.authToken else {
            errorMessage = "Token není k dispozici"
            return
        }

        do {
            let result: PayInvoiceResponse = try await APIService.shared.request(
                endpoint: APIConstants.payInvoiceEndpoint(companyId: companyId, invoiceId: invoiceId),
                method: .GET,
                token: token
            )
            successMessage = "Faktura byla úspěšně zaplacena. Doklad č. \(result.cashVoucherId)"
            errorMessage = nil
            print("✅ Faktura zaplacena, doklad ID: \(result.cashVoucherId)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


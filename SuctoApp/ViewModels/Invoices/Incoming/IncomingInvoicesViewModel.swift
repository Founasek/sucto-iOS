//
//  IncomingInvoicesViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import SwiftUI

@MainActor
class IncomingInvoicesViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var selectedInvoice: Invoice?

    @Published var successMessage: String?
    @Published var errorMessage: String?

    @Published var isLoadingPage = false
    @Published var isLoadingDetail = false

    @Published var hasMorePages = true
    private var currentPage = 1


    let companyId: Int
    private var session: SessionManager

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

        guard !isLoadingPage, hasMorePages else { return }

        isLoadingPage = true

        let pageToLoad = page ?? currentPage

        do {
            let result: [Invoice] = try await APIService.shared.request(
                endpoint: "companies/\(companyId)/actuarials_ins?page=\(pageToLoad)",
                method: .GET,
                token: token,
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
    
    func fetchInvoiceDetail(invoiceId: Int) async {
        guard let token = session.authToken else {
            errorMessage = "Token není k dispozici"
            return
        }

        isLoadingDetail = true

        do {
            let invoice: Invoice = try await APIService.shared.request(
                endpoint: APIConstants.GetIncomingInvoiceDetail(companyId: companyId, invoiceId: invoiceId),
                method: .GET,
                token: token,
            )

            selectedInvoice = invoice
            errorMessage = nil
        } catch APIError.unauthorized {
            session.logout()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingDetail = false
    }
}

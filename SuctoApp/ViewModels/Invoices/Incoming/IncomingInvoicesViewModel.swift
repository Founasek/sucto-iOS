//
//  IncomingInvoicesViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import SwiftUI

@MainActor
final class IncomingInvoicesViewModel: PagedInvoicesViewModel {
    override func listEndpoint(page: Int, query: InvoiceQuery) -> String {
        query.path("companies/\(companyId)/actuarials_ins", page: page)
    }

    func fetchInvoiceDetail(invoiceId: Int) async {
        // Nezobrazuj detail dříve prohlížené faktury, než se načte ta aktuální.
        if selectedInvoice?.id != invoiceId { selectedInvoice = nil }
        isLoadingDetail = true
        defer { isLoadingDetail = false }

        do {
            selectedInvoice = try await session.send(
                APIConstants.incomingInvoiceDetail(companyId: companyId, invoiceId: invoiceId),
            )
            detailErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            detailErrorMessage = error.localizedDescription
        }
    }
}

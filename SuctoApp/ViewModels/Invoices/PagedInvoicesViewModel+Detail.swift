//
//  PagedInvoicesViewModel+Detail.swift
//  SuctoApp
//

import Foundation

/// Detail faktury.
extension PagedInvoicesViewModel {
    /// Načte detail faktury (společné pro vydané i přijaté).
    func fetchInvoiceDetail(invoiceId: Int) async {
        // Nezobrazuj detail dříve prohlížené faktury, než se načte ta aktuální.
        if selectedInvoice?.id != invoiceId { selectedInvoice = nil }
        isLoadingDetail = true
        defer { isLoadingDetail = false }

        let endpoint = direction == .outgoing
            ? APIConstants.outgoingInvoiceDetail(companyId: companyId, invoiceId: invoiceId)
            : APIConstants.incomingInvoiceDetail(companyId: companyId, invoiceId: invoiceId)
        do {
            selectedInvoice = try await session.send(endpoint)
            detailErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            detailErrorMessage = error.localizedDescription
        }
    }
}

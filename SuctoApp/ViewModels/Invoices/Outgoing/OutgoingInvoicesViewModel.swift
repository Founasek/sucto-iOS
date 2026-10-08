//
//  OutgoingInvoicesViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import SwiftUI

@MainActor
final class OutgoingInvoicesViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var selectedInvoice: Invoice?

    /// Chyba načtení seznamu.
    @Published var errorMessage: String?
    /// Chyba načtení detailu (oddělená od seznamu, aby se nepřenášela mezi obrazovkami).
    @Published var detailErrorMessage: String?
    /// Chyba akce (např. úhrady) zobrazená v alertu.
    @Published var alertMessage: String?
    /// Text potvrzení po úspěšné úhradě; dokud je nastavený, ukazuje se animace úspěchu.
    @Published var paymentConfirmation: String?

    @Published var isLoadingPage = false
    @Published var isLoadingDetail = false
    @Published var hasMorePages = true

    private var currentPage = 1

    let companyId: Int
    private let session: SessionManager

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    /// Načte první stránku znovu (pull-to-refresh, návrat na obrazovku).
    func refresh() async {
        currentPage = 1
        hasMorePages = true
        await fetchNextPage()
    }

    func fetchNextPage() async {
        guard !isLoadingPage, hasMorePages else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }

        let pageToLoad = currentPage
        do {
            let result: [Invoice] = try await session.send(
                APIConstants.outgoingInvoices(companyId: companyId, page: pageToLoad),
            )
            if pageToLoad == 1 {
                invoices = result
            } else {
                invoices.append(contentsOf: result)
            }
            hasMorePages = !result.isEmpty
            currentPage = pageToLoad + 1
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchInvoiceDetail(invoiceId: Int) async {
        // Nezobrazuj detail dříve prohlížené faktury, než se načte ta aktuální.
        if selectedInvoice?.id != invoiceId { selectedInvoice = nil }
        isLoadingDetail = true
        defer { isLoadingDetail = false }

        do {
            selectedInvoice = try await session.send(
                APIConstants.outgoingInvoiceDetail(companyId: companyId, invoiceId: invoiceId),
            )
            detailErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            detailErrorMessage = error.localizedDescription
        }
    }

    func markOutgoingInvoiceAsPaid(invoiceId: Int) async {
        do {
            let result: PayInvoiceResponse = try await session.send(
                APIConstants.outgoingInvoiceMarkAsPaid(companyId: companyId, invoiceId: invoiceId),
            )
            withAnimation(Motion.bouncy) {
                paymentConfirmation = "Doklad č. \(result.cashVoucherId)"
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(Motion.standard) { paymentConfirmation = nil }
            }
            await fetchInvoiceDetail(invoiceId: invoiceId)
            await refresh()
        } catch is CancellationError {
            return
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

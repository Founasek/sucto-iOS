//
//  OutgoingInvoicesViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import SwiftUI

@MainActor
final class OutgoingInvoicesViewModel: PagedInvoicesViewModel {
    /// Chyba akce (např. úhrady) zobrazená v alertu.
    @Published var alertMessage: String?
    /// Potvrzení úspěšné akce (úhrada, odeslání); dokud je nastavené, ukazuje se animace úspěchu.
    @Published var confirmation: Confirmation?

    struct Confirmation: Equatable {
        let title: String
        let message: String
    }

    init(companyId: Int, session: SessionManager) {
        super.init(companyId: companyId, session: session, direction: .outgoing)
    }

    /// Pošle fakturu e-mailem. Vrací text chyby, nebo `nil` při úspěchu.
    func sendByEmail(invoiceId: Int, email: String, comment: String) async -> String? {
        struct Body: Encodable {
            let email: String
            let comment: String?
        }
        do {
            let body = try JSONEncoder().encode(Body(email: email, comment: comment.isEmpty ? nil : comment))
            let _: EmptyResponse = try await session.send(
                APIConstants.outgoingInvoiceSendToEmail(companyId: companyId, invoiceId: invoiceId),
                method: .PATCH,
                body: body,
            )
            showConfirmation(title: "Odesláno", message: email)
            return nil
        } catch is CancellationError {
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func markOutgoingInvoiceAsPaid(invoiceId: Int) async {
        do {
            let result: PayInvoiceResponse = try await session.send(
                APIConstants.outgoingInvoiceMarkAsPaid(companyId: companyId, invoiceId: invoiceId),
            )
            showConfirmation(title: "Zaplaceno", message: "Doklad č. \(result.cashVoucherId)")
            await fetchInvoiceDetail(invoiceId: invoiceId)
            await refresh()
        } catch is CancellationError {
            return
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func showConfirmation(title: String, message: String) {
        withAnimation(Motion.bouncy) {
            confirmation = Confirmation(title: title, message: message)
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(Motion.standard) { confirmation = nil }
        }
    }
}

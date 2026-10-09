//
//  OutgoingInvoiceDetailView+Actions.swift
//  SuctoApp
//

import SwiftUI

/// Akce detailu vydané faktury: úhrada, úprava položek a odeslání upomínky.
extension OutgoingInvoiceDetailView {
    @ViewBuilder
    var payBar: some View {
        if let invoice = viewModel.selectedInvoice, !invoice.isPaid, !viewModel.isLoadingDetail {
            Button {
                Task { await viewModel.markOutgoingInvoiceAsPaid(invoiceId: invoice.id) }
            } label: {
                Label("Uhradit fakturu", systemImage: "checkmark.circle")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
            .background(.bar)
        }
    }

    /// Úprava položek je jen pro uživatele s právem `update` a u faktur, které nejsou stornované.
    func itemEditing(for invoice: Invoice) -> InvoiceItemEditing? {
        guard permissions.can(.update, InvoiceDirection.outgoing.permissionResource, companyId: viewModel.companyId),
              invoice.invoiceStatus != .storno
        else { return nil }
        return InvoiceItemEditing(
            onAdd: { lineSheet = LineSheet(item: nil) },
            onEdit: { item in lineSheet = LineSheet(item: item) },
        )
    }

    func reloadAfterLineChange() async {
        await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
        await viewModel.refresh()
    }

    /// Okno upomínky: příjemce a text jsou předvyplněné (z faktury a šablony) a lze je upravit.
    func reminderSheet(for invoice: Invoice) -> some View {
        let last = ReminderLog.lastSent(invoiceId: invoice.id).map {
            " Poslední upomínka byla odeslána \($0.formatted(.dateTime.day().month().year().locale(Locale(identifier: "cs_CZ"))))."
        } ?? ""
        return SendEmailSheet(
            invoiceNumber: invoice.actuarialNumber,
            title: "Odeslat upomínku",
            sendTitle: "Odeslat",
            commentHeader: "Text upomínky",
            commentFooter: "Zpráva se odešle zákazníkovi spolu s fakturou. Výchozí text změníte v Nastavení." + last,
            commentLines: 8 ... 16,
            initialEmail: invoice.customer?.email ?? "",
            initialComment: ReminderSettings.render(
                ReminderSettings.template,
                invoice: invoice,
                companyName: viewModel.session.selectedCompany?.name,
            ),
        ) { email, comment in
            let error = await viewModel.sendByEmail(invoiceId: invoiceId, email: email, comment: comment)
            if error == nil { ReminderLog.record(invoiceId: invoice.id) }
            return error
        }
    }
}

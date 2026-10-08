//
//  IncomingInvoiceDetailView.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import SwiftUI

struct IncomingInvoiceDetailView: View {
    let invoiceId: Int
    @EnvironmentObject var viewModel: IncomingInvoicesViewModel

    var body: some View {
        ScrollView {
            if viewModel.isLoadingDetail {
                LoadingStateView(message: "Načítám fakturu…")
            } else if let error = viewModel.detailErrorMessage {
                ErrorStateView(message: error) {
                    Task { await viewModel.fetchInvoiceDetail(invoiceId: invoiceId) }
                }
            } else if let invoice = viewModel.selectedInvoice {
                content(for: invoice)
            } else {
                EmptyStateView(
                    systemImage: "doc.text.magnifyingglass",
                    message: "Faktura není k dispozici.",
                )
            }
        }
        .navigationTitle("Detail faktury")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.background)
        .task {
            await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
        }
        .refreshable {
            await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
        }
    }

    private func content(for invoice: Invoice) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            InvoiceHeroCard(
                invoice: invoice,
                counterparty: invoice.supplier?.name,
                showBasePrice: invoice.supplier?.isTaxable == true,
            )

            DetailCard(title: "Základní informace", systemImage: "info.circle") {
                DetailRow(label: "Externí číslo", value: invoice.externalNumber, hideWhenEmpty: true)
                DetailRow(label: "Číslo objednávky", value: invoice.orderNumber, hideWhenEmpty: true)
                DetailRow(label: "Variabilní symbol", value: invoice.variableSymbol, hideWhenEmpty: true)
            }

            DetailCard(title: "Dodavatel", systemImage: "building.2") {
                DetailRow(label: "Název", value: invoice.supplier?.name)
                DetailRow(label: "IČO", value: invoice.supplier?.ic, hideWhenEmpty: true)
                DetailRow(label: "DIČ", value: invoice.supplier?.dic, hideWhenEmpty: true)
                DetailRow(label: "Plátce DPH", value: invoice.supplier?.isTaxable == true ? "Ano" : "Ne")
            }

            InvoiceDatesCard(invoice: invoice)
            InvoiceItemsCard(invoice: invoice)
        }
        .padding(Theme.Spacing.l)
    }
}

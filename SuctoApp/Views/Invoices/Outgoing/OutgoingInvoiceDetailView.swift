//
//  OutgoingInvoiceDetailView.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import SwiftUI

struct OutgoingInvoiceDetailView: View {
    let invoiceId: Int
    @EnvironmentObject var viewModel: OutgoingInvoicesViewModel

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
        .safeAreaInset(edge: .bottom) { payBar }
        .overlay {
            if let confirmation = viewModel.paymentConfirmation {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    PaymentSuccessOverlay(message: confirmation)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.paymentConfirmation) { _, new in new != nil }
        .task {
            await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
        }
        .refreshable {
            await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
        }
        .alert(
            "Úhradu se nepodařilo provést",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } },
            ),
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    private func content(for invoice: Invoice) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            InvoiceHeroCard(
                invoice: invoice,
                counterparty: invoice.customer?.name,
                showBasePrice: invoice.taxable == true,
            )

            DetailCard(title: "Základní informace", systemImage: "info.circle") {
                DetailRow(label: "Variabilní symbol", value: invoice.variableSymbol, hideWhenEmpty: true)
                DetailRow(label: "Externí číslo", value: invoice.externalNumber, hideWhenEmpty: true)
                DetailRow(label: "Číslo objednávky", value: invoice.orderNumber, hideWhenEmpty: true)
            }

            DetailCard(title: "Zákazník", systemImage: "person.crop.circle") {
                DetailRow(label: "Název", value: invoice.customer?.name)
                DetailRow(label: "IČO", value: invoice.customer?.ic)
                DetailRow(label: "DIČ", value: invoice.customer?.dic)
            }

            InvoiceDatesCard(invoice: invoice)
            InvoiceItemsCard(invoice: invoice)
        }
        .padding(Theme.Spacing.l)
    }

    @ViewBuilder
    private var payBar: some View {
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
}

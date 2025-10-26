//
//  OutgoingInvoicesView.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import SwiftUI

struct IncomingInvoicesView: View {
    @EnvironmentObject var viewModel: IncomingInvoicesViewModel
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        List {
            ForEach(viewModel.invoices) { invoice in
                NavigationLink(value: invoice) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(invoice.actuarialNumber)
                                .font(.headline)
                            Spacer()
                            Text(invoice.status)
                                .foregroundColor(invoice.statusId == 8 ? .green : .orange)
                        }
                        Text(invoice.supplier?.name ?? "")
                            .font(.subheadline)
                        Text(FormatterHelper.formatPrice(invoice.endPrice, currency: invoice.currency?.symbol))
                            .font(.subheadline)
                        Text("Datum vystavení: \(invoice.issueDateAt ?? "")")
                            .font(.caption)
                        Text("Datum splatnosti: \(invoice.dueDateAt ?? "")")
                            .font(.caption)
                    }
                    .padding(.vertical, 5)
                }
                .navigationLinkIndicatorVisibility(.hidden)
                // 👇 Jakmile se objeví poslední položka, načte se další stránka
                .onAppear {
                    if invoice == viewModel.invoices.last {
                        Task {
                            await viewModel.fetchInvoices()
                        }
                    }
                }
            }

            // 👇 Loading indikátor dole při načítání další stránky
            if viewModel.isLoadingPage {
                HStack {
                    Spacer()
                    ProgressView("Načítám další faktury...")
                    Spacer()
                }
            }
        }
        .navigationDestination(for: Invoice.self) { invoice in
            IncomingInvoiceDetailView(invoice: invoice)
                .environmentObject(viewModel)
        }
        .navigationTitle("Přijaté faktury")
        .overlay {
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .refreshable {
            viewModel.resetPagination()
            await viewModel.fetchInvoices(page: 1)
        }
        .task {
            // Načteme první stránku při prvním zobrazení
            if viewModel.invoices.isEmpty {
                await viewModel.fetchInvoices(page: 1)
            }
        }
    }
}

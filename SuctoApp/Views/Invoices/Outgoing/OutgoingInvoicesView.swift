//
//  OutgoingInvoicesView.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import SwiftUI

struct OutgoingInvoicesView: View {
    @EnvironmentObject var viewModel: OutgoingInvoicesViewModel
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        if viewModel.invoices.isEmpty {
            if viewModel.isLoadingPage {
                LoadingStateView(message: "Načítám faktury…")
            } else if let error = viewModel.errorMessage {
                ErrorStateView(
                    message: error,
                    retryAction: {
                        Task {
                            await viewModel.fetchInvoices(page: 1)
                        }
                    }
                )

            } else {
                ScrollView {
                    EmptyStateView(
                        systemImage: "doc.text.magnifyingglass",
                        message: "Žádné faktury nejsou k dispozici."
                    )
                }
                .refreshable {
                    viewModel.resetPagination()
                    Task {
                        await viewModel.fetchInvoices(page: 1)
                    }
                }
            }
        } else {
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
                            /*
                             if let status = invoice.invoiceStatus {
                                 Text(status.title)
                                     .foregroundColor(Color(hex: status.color))
                             }
                             */

                            Text(invoice.customer?.name ?? "")
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
                    .onAppear {
                        if invoice == viewModel.invoices.last {
                            Task {
                                await viewModel.fetchInvoices()
                            }
                        }
                    }
                }

                if viewModel.isLoadingPage {
                    HStack {
                        Spacer()
                        LoadingStateView(message: "Načítám další faktury…")
                            .frame(height: 60)
                        Spacer()
                    }
                }
            }
            .navigationDestination(for: Invoice.self) { invoice in
                OutgoingInvoiceDetailView(invoiceId: invoice.id)
                    .environmentObject(viewModel)
            }
            // .navigationTitle("Vydané faktury")
            .refreshable {
                viewModel.resetPagination()
                Task {
                    await viewModel.fetchInvoices(page: 1)
                }
            }
        }
    }
}

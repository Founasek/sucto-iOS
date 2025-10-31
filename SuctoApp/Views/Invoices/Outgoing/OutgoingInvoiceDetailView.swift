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
                ProgressView("Načítám fakturu…")
                    .padding()
            } else if let invoice = viewModel.selectedInvoice {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Základní informace

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Faktura č.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(invoice.actuarialNumber)
                                .font(.headline)
                        }

                        HStack {
                            Text("Stav:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(invoice.status)
                                .font(.headline)
                                .foregroundColor(invoice.statusId == 8 ? .green : .orange)
                        }

                        Divider()

                        Text("Zákazník")
                            .font(.headline)
                        Text(invoice.customer?.name ?? "-")
                            .font(.subheadline)

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Datum vystavení: \(invoice.issueDateAt ?? "-")")
                            Text("Splatnost: \(invoice.dueDateAt ?? "-")")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)

                    // MARK: - Poznámka

                    if let notice = invoice.printNotice, !notice.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Poznámka k faktuře")
                                .font(.headline)
                                .padding(.bottom, 4)
                            Text(notice)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }

                    // MARK: - Položky

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Položky")
                            .font(.headline)

                        ForEach(invoice.items ?? []) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    if let quantity = item.quantity, let unit = item.unitName {
                                        Text("\(quantity) \(unit)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if let price = item.totalPrice, let currency = invoice.currency?.symbol {
                                    Text("\(FormatterHelper.formatPrice(price, currency: currency))")
                                        .font(.subheadline)
                                }
                            }
                            Divider()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // MARK: - Částka a akce

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Částka k úhradě")
                                .font(.headline)
                            Text("\(FormatterHelper.formatPrice(invoice.endPrice, currency: invoice.currency?.symbol))")
                                .font(.title2)
                                .fontWeight(.semibold)

                            HStack(spacing: 5) {
                                Text("bez DPH")
                                    .font(.footnote)
                                    .foregroundStyle(Color.gray.opacity(0.8))
                                Text("\(FormatterHelper.formatPrice(invoice.basePrice, currency: invoice.currency?.symbol))")
                                    .font(.footnote)
                                    .foregroundStyle(Color.gray.opacity(0.8))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)

                        if invoice.statusId != 8 {
                            Button {
                                Task {
                                    await viewModel.payInvoice(invoiceId: invoice.id)
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Uhradit fakturu")
                                        .font(.headline)
                                        .padding()
                                    Spacer()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                        }
                    }

                    // MARK: - Stavové hlášky

                    if let success = viewModel.successMessage {
                        Text(success)
                            .foregroundColor(.green)
                            .padding(.top, 8)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }

                    Spacer()
                }
                .padding()
            } else {
                Text("Faktura není k dispozici")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .navigationTitle("Detail faktury")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task {
                await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
            }
        }
        .refreshable {
            Task {
                await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
            }
        }
    }
}

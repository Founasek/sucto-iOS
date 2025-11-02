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

            } else if let error = viewModel.errorMessage {
                ErrorStateView(
                    message: error,
                    retryAction: {
                        Task {
                            await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
                        }
                    }
                )

            } else if let invoice = viewModel.selectedInvoice {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Základní informace

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Základní informace")
                            .font(.headline)
                            .padding(.bottom, 4)
                            .foregroundStyle(Color.primary)

                        HStack {
                            Text("Faktura č.:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(invoice.actuarialNumber)
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                                .fontWeight(.bold)
                        }

                        HStack {
                            Text("Stav:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(invoice.status)
                                .font(.subheadline)
                                .foregroundColor(invoice.statusId == 8 ? .green : .orange)
                        }

                        if let variableSymbol = invoice.variableSymbol {
                            HStack {
                                Text("Variabilní symbol:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(variableSymbol)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary)
                            }
                        }

                        // 🆕 Externí číslo a číslo objednávky
                        if let externalNumber = invoice.externalNumber {
                            HStack {
                                Text("Externí číslo:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(externalNumber)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary)
                            }
                        }

                        if let orderNumber = invoice.orderNumber, !orderNumber.isEmpty {
                            HStack {
                                Text("Číslo objednávky:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(orderNumber)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // MARK: - Zákazník

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Zákazník")
                            .font(.headline)
                            .padding(.bottom, 4)
                            .foregroundStyle(Color.primary)

                        HStack {
                            Text("Název:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.customer?.name ?? "-")
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                        }

                        // 🆕 Daňové údaje zákazníka
                        HStack {
                            Text("IČO:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.customer?.ic ?? "-")
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                        }

                        HStack {
                            Text("DIČ:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.customer?.dic ?? "-")
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // MARK: - Časové údaje

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Časové údaje")
                            .font(.headline)
                            .padding(.bottom, 4)
                            .foregroundStyle(Color.primary)

                        HStack {
                            Text("Datum vystavení:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.issueDateAt ?? "-")
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                        }

                        HStack {
                            Text("Datum splatnosti:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.dueDateAt ?? "-")
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                        }

                        HStack {
                            Text("Datum UZP:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.uzpDateAt ?? "-")
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // MARK: - Položky a poznámka

                    VStack(alignment: .leading, spacing: 8) {
                        // 🆕 Poznámka k faktuře
                        if let notice = invoice.printNotice, !notice.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Poznámka a položky")
                                        .font(.headline)
                                        .padding(.bottom, 4)
                                    Spacer()
                                    Image(systemName: "bubble.right")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                }

                                Text(notice)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                        }

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
                        }
                        .padding(.top, 16)
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
                                .foregroundStyle(.accent)

                            // 🆕 zobrazit bez DPH jen pokud my jsme plátci
                            if invoice.taxable == true {
                                HStack(spacing: 5) {
                                    Text("bez DPH")
                                        .font(.footnote)
                                        .foregroundStyle(Color.gray.opacity(0.8))
                                    Text("\(FormatterHelper.formatPrice(invoice.basePrice, currency: invoice.currency?.symbol))")
                                        .font(.footnote)
                                        .foregroundStyle(Color.gray.opacity(0.8))
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)

                        if invoice.statusId != 8 {
                            Button {
                                Task {
                                    await viewModel.markOutgoingInvoiceAsPaid(invoiceId: invoice.id)
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
                }
                .padding()
            } else {
                EmptyStateView(
                    systemImage: "doc.text.magnifyingglass",
                    message: "Faktury není k dispozici."
                )
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

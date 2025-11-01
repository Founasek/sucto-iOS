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
                            Text("Faktura č.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(invoice.actuarialNumber)
                                .font(.headline)
                                .foregroundStyle(Color.primary)
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

                        // 🆕 Externí číslo a číslo objednávky
                        if let externalNumber = invoice.externalNumber {
                            HStack {
                                Text("Externí číslo:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(externalNumber)
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
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // MARK: - Dodavatel
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dodavatel")
                            .font(.headline)
                            .padding(.bottom, 4)
                            .foregroundStyle(Color.primary)

                        HStack {
                            Text("Název:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.supplier?.name ?? "-")
                                .foregroundStyle(Color.primary)
                        }

                        if let ic = invoice.supplier?.ic, !ic.isEmpty {
                            HStack {
                                Text("IČ:")
                                    .font(.subheadline)
                                Spacer()
                                Text(ic)
                                    .foregroundStyle(Color.primary)
                            }
                        }

                        if let dic = invoice.supplier?.dic, !dic.isEmpty {
                            HStack {
                                Text("DIČ:")
                                    .font(.subheadline)
                                Spacer()
                                Text(dic)
                                    .foregroundStyle(Color.primary)
                            }
                        }

                        // Daňové údaje dodavatele
                        HStack {
                            Text("Plátce DPH:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.supplier?.isTaxable == true ? "Ano" : "Ne")
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)




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
                                .foregroundStyle(Color.primary)

                        }

                        HStack {
                            Text("Datum splatnosti:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.dueDateAt ?? "-")
                                .foregroundStyle(Color.primary)

                        }

                        HStack {
                            Text("Datum UZP:")
                                .font(.subheadline)
                            Spacer()
                            Text(invoice.uzpDateAt ?? "-")
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // MARK: - Položky
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
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    


                    // MARK: - Částka
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Částka k úhradě")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "receipt")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                        }

                        Text("\(FormatterHelper.formatPrice(invoice.endPrice, currency: invoice.currency?.symbol))")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if invoice.supplier?.isTaxable == true {
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
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                }
                .padding()

            } else {
                EmptyStateView(
                    systemImage: "doc.text.magnifyingglass",
                    message: "Faktura není k dispozici."
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

//
//  InvoiceDetailView.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//


import SwiftUI

struct OutgoingInvoiceDetailView: View {
    let invoice: Invoice
    @EnvironmentObject var viewModel: OutgoingInvoicesViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // MARK: - Základní informace o faktuře
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
                
                // MARK: - Poznámka – přes celou šířku
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
                
                // MARK: - Cena a akce
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
                    
                    // ✅ Zobrazit tlačítko jen pokud není zaplaceno
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
                    } else {
                        // Volitelné – zobrazit info o zaplacení

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
        }
        .navigationTitle("Detail faktury")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

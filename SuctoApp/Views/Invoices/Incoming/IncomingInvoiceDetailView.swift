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
                ProgressView("Načítám fakturu…")
                    .padding()
            } else if let invoice = viewModel.selectedInvoice {
                
                
                VStack(alignment: .leading, spacing: 15) {
                    // Faktura a stav
                    HStack {
                        Text("\(invoice.actuarialNumber)")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text(invoice.status)
                            .foregroundColor(invoice.status == "Zaplaceno" ? .green : .orange)
                            .bold()
                    }
                    
                    Divider()
                    
                    // Zákazník
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Zákazník:")
                            .font(.headline)
                        Text(invoice.supplier?.name ?? "")
                    }
                    
                    // Termíny
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Termíny:")
                            .font(.headline)
                        Text("Datum vystavení: \(invoice.issueDateAt ?? "")")
                        Text("Datum splatnosti: \(invoice.dueDateAt ?? "")")
                    }
                    
                    // Cena
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Cena:")
                            .font(.headline)
                        Text("\(FormatterHelper.formatPrice(invoice.endPrice, currency: invoice.currency?.symbol))")
                            .font(.title3)
                            .bold()
                    }
                    
                    Divider()
                    
                    // Poznámka
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Poznámka k faktuře")
                            .font(.headline)
                        Text(invoice.printNotice ?? "")
                    }
                    
                    // Footer
                    if let foot = invoice.footNotice {
                        Divider()
                        Text(foot)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
                .navigationTitle("Detail faktury")
                .navigationBarTitleDisplayMode(.inline)
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

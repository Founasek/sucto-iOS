//
//  CreateOutgoingInvoiceView.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//


import SwiftUI

struct CreateOutgoingInvoiceView: View {
    
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var session: SessionManager
    
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: CreateOutgoingInvoiceViewModel


    init(companyId: Int) {
        _viewModel = StateObject(wrappedValue: CreateOutgoingInvoiceViewModel(companyId: companyId, session: SessionManager()))
    }

    var body: some View {
            Form {
                Section(header: Text("Základní informace")) {
                    Text("Číslo faktury: \(viewModel.actuarialNumber)")
                    DatePicker("Datum vystavení", selection: $viewModel.issueDate, displayedComponents: .date)
                    DatePicker("Datum splatnosti", selection: $viewModel.dueDate, displayedComponents: .date)
                    


                    Picker("Odběratel", selection: $viewModel.partnerId) {
                        ForEach(viewModel.availablePartners) { partner in
                            Text(partner.name ?? "Neznámý").tag(partner.id)
                        }
                    }
                    
                    Picker("Bankovní účet", selection: $viewModel.accountId) {
                        ForEach(viewModel.availableAccounts) { account in
                            Text(account.name).tag(account.id)
                        }
                    }
                    
                    Picker("Měna", selection: $viewModel.currencyId) {
                        ForEach(viewModel.availableCurrencies, id: \.id) { currency in
                            Text(currency.isoCode ?? "???").tag(currency.id)
                        }
                    }
                }
                
                Section(header: Text("Položky faktury")) {
                    ForEach($viewModel.items) { $item in
                        VStack(alignment: .leading, spacing: 12) {
                            // Hlavní řádek: název položky + tlačítko odstranit
                            HStack {
                                TextField("Název položky", text: $item.name)
                                    .font(.headline)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                                
                                Spacer()
                                
                                Button {
                                    viewModel.removeItem(item)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.8))
                                        .imageScale(.medium)
                                        .padding(6)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Divider().padding(.vertical, 2)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                
                                // Množství
                                HStack {
                                    Text("Množství")
                                        .font(.subheadline)
                                    Spacer()
                                    TextField("0", value: $item.quantity, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                        .padding(.vertical, 4)
                                }
                                Divider()
                                
                                // Jednotka
                                HStack {
                                    Text("Jednotka")
                                        .font(.subheadline)
                                    Spacer()
                                    TextField("ks", text: $item.unit_name)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 60)
                                        .padding(.vertical, 4)
                                }
                                Divider()
                                
                                // Cena za jednotku
                                HStack {
                                    Text("Cena / j.")
                                        .font(.subheadline)
                                    Spacer()
                                    TextField("0", value: $item.unit_price, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                        .padding(.vertical, 4)
                                }
                                Divider()
                            }
                            .padding(.horizontal)

                            
                            // Celková cena
                            if let quantity = item.quantity,
                               let unitPrice = item.unit_price,
                               quantity > 0 {
                                HStack {
                                    Spacer()
                                    Text("Celkem: \((quantity * unitPrice).formatted(.number.precision(.fractionLength(2)))) " + viewModel.selectedCurrencyCode)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.accentColor)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }

                    // Přidat položku
                    Button {
                        viewModel.addEmptyItem()
                    } label: {
                        Label("Přidat položku", systemImage: "plus.circle.fill")
                            .font(.body.weight(.medium))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.top, 6)
                }

                
                


                
                Section {
                    HStack {
                        Text("Celková částka")
                            .font(.headline)
                        Spacer()
                        Text(viewModel.totalAmount, format: .currency(code: viewModel.selectedCurrencyCode))
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                }

                
                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Nová vydaná faktura")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Vytvořit") {
                        Task {
                            await viewModel.createInvoice()
                            if viewModel.creationSuccess {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .task {
                await viewModel.loadInitialData()
            }
        
    }
}

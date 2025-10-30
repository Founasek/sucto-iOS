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
    @StateObject var viewModel: OutgoingInvoiceCreateViewModel

    init(companyId: Int) {
        _viewModel = StateObject(wrappedValue: OutgoingInvoiceCreateViewModel(companyId: companyId, session: SessionManager()))
    }

    var body: some View {
        Form {
            // MARK: - Základní informace
            Section(header: Text("Základní informace")) {
                
                HStack {
                    Text("Číslo faktury: ")
                    Spacer()
                    Text(viewModel.actuarialNumber)
                }
                
                
                
                HStack {
                    Text("Variabilní symbol:")
                        //.foregroundColor(.secondary)
                    
                    Spacer()
                    
                    TextField("", text: $viewModel.variableSymbol)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 80, maxWidth: 220)
                }

                
                DatePicker("Datum vystavení", selection: $viewModel.issueDate, displayedComponents: .date)
                DatePicker("Datum splatnosti", selection: $viewModel.dueDate, displayedComponents: .date)
                
                PartnerPickerView(
                    selectedPartner: $viewModel.selectedPartner,
                    partners: viewModel.availablePartners
                )


                AccountPickerView(
                    selectedAccount: $viewModel.selectedAccount,
                    accounts: viewModel.availableAccounts
                )


                CurrencyPickerView(
                    selectedCurrency: $viewModel.selectedCurrency,
                    currencies: viewModel.availableCurrencies
                )
                 
            }
            
            Section(header: Text("Dalši informace")) {
                HStack {
                    Text("Číslo objednávky:")
                    
                    Spacer()
                    
                    TextField("", text: $viewModel.orderNumber)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 80, maxWidth: 220)
                }
                
                VStack (alignment: .leading){
                    Text("Poznámka:")
                    TextField(viewModel.printNotice, text: $viewModel.printNotice, axis: .vertical)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2...5)
                        //.frame(minWidth: 80, maxWidth: 220)
                }
            }
            

            

            
            // MARK: - Položky faktury
            Section(header: Text("Položky faktury")) {
                ForEach($viewModel.items) { $item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Název položky", text: $item.name)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                            
                            Spacer()
                            
                            Button {
                                viewModel.items.removeAll { $0.id == item.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical)
                        
                        HStack {
                            Text("Množství")
                                .font(.subheadline)
                            Spacer()
                            TextField("0", value: $item.quantity, format: .number)
                                //.keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("Jednotka")
                                .font(.subheadline)
                            Spacer()
                            TextField("ks / h / MD", text: Binding(
                                get: { item.unitName ?? "" },
                                set: { item.unitName = $0 }
                            ))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)


                        }
                        
                        HStack {
                            Text("Cena / j.")
                                .font(.subheadline)
                            Spacer()
                            TextField("0", value: $item.unitPrice, format: .number)
                                .keyboardType(.numberPad)
                                .submitLabel(.done)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("Celkem")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            let total = item.quantity * item.unitPrice
                            Text(total, format: .currency(code: viewModel.selectedCurrency?.isoCode ?? "CZK"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                        }
                        
                        Divider()
                    }
                    .padding(.vertical, 4)
                }
                
                Button(action: {
                    viewModel.items.append(CreateInvoiceLine(
                        vatId: 108,
                        lineableType: "Actuarial",
                        name: "",
                        quantity: 0,
                        unitPrice: 0,
                        basePrice: 0,
                        tax: 0,
                        totalPrice: 0,
                        unitName: nil
                    ))
                }) {
                    VStack(alignment: .leading, spacing: 6) {


                        HStack {
                            Label("Klikněte pro přidání nové položky", systemImage: "plus.circle.fill")
                                .foregroundStyle(.accent)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    //.background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .contentShape(Rectangle()) // zvětší tap oblast
                }
                .buttonStyle(PlainButtonStyle())

            }
 
            
            // MARK: - Celková částka
            Section {
                HStack {
                    Text("Celková částka")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.items.reduce(0) { $0 + ($1.quantity * $1.unitPrice) }, specifier: "%.2f") \(viewModel.selectedCurrency?.isoCode ?? "")")

                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
            
            // MARK: - Chyby
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
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
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

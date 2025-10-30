//
//  CurrencyPickerView.swift
//  SuctoApp
//
//  Created by Jan Founě on 28.10.2025.
//


import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: Currency?
    let currencies: [Currency]
    
    @State private var isPresented = false
    
    var body: some View {
        Button {
            isPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Měna")
                    .foregroundColor(.primary)
                
                HStack {
                    if let selected = selectedCurrency {
                        Text(selected.isoCode ?? "???")
                            .font(.body)
                            .foregroundStyle(.accent)
                    } else {
                        Text("Vyberte měnu")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                List(currencies) { currency in
                    Button {
                        selectedCurrency = currency
                        isPresented = false
                    } label: {
                        Text(currency.isoCode ?? "???")
                            .font(.body)
                    }
                }
                .navigationTitle("Vyberte měnu")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Zavřít") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

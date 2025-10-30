//
//  PaymentTypePickerView.swift
//  SuctoApp
//
//  Created by Jan Founě on 30.10.2025.
//


import SwiftUI

struct PaymentTypePickerView: View {
    @Binding var selectedPaymentType: PaymentType?
    let paymentTypes: [PaymentType]
    
    @State private var searchText = ""
    @State private var isPresented = false
    
    private var filteredPaymentTypes: [PaymentType] {
        if searchText.isEmpty {
            return paymentTypes
        } else {
            return paymentTypes.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        Button {
            isPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daňová kategorie")
                    .foregroundColor(.primary)
                
                HStack {
                    if let selected = selectedPaymentType {
                        Text(selected.name)
                            .font(.body)
                            .foregroundStyle(.accent)
                    } else {
                        Text("Vyberte kategorii")
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
                List(filteredPaymentTypes) { type in
                    Button {
                        selectedPaymentType = type
                        isPresented = false
                    } label: {
                        Text(type.name)
                            .font(.body)
                    }
                }
                .searchable(text: $searchText, prompt: "Hledat podle názvu")
                .navigationTitle("Vyberte typ platby")
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

//
//  VatRegimePickerView.swift
//  SuctoApp
//
//  Created by Jan Founě on 30.10.2025.
//

import SwiftUI

struct VatRegimePickerView: View {
    @Binding var selectedVatRegime: VatRegime?
    let vatRegimes: [VatRegime]

    @State private var searchText = ""
    @State private var isPresented = false

    private var filteredVatRegimes: [VatRegime] {
        if searchText.isEmpty {
            vatRegimes
        } else {
            vatRegimes.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Režim DPH")
                    .foregroundColor(.primary)

                HStack {
                    if let selected = selectedVatRegime {
                        Text(selected.name)
                            .font(.body)
                            .foregroundStyle(.accent)
                    } else {
                        Text("Vyberte režim DPH")
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
                List(filteredVatRegimes) { regime in
                    Button {
                        selectedVatRegime = regime
                        isPresented = false
                    } label: {
                        Text(regime.name)
                            .font(.body)
                    }
                }
                .searchable(text: $searchText, prompt: "Hledat podle názvu")
                .navigationTitle("Vyberte režim DPH")
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

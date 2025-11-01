//
//  AccountPickerView.swift
//  SuctoApp
//
//  Created by Jan Founě on 28.10.2025.
//

import SwiftUI

struct AccountPickerView: View {
    @Binding var selectedAccount: Account?
    let accounts: [Account]

    @State private var searchText = ""
    @State private var isPresented = false

    private var filteredAccounts: [Account] {
        if searchText.isEmpty {
            accounts
        } else {
            accounts.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Forma úhrady")
                    .foregroundColor(.primary)

                HStack {
                    if let selected = selectedAccount {
                        Text(selected.name)
                            .font(.body)
                            .foregroundStyle(.accent)
                    } else {
                        Text("Vyberte účet")
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
                List(filteredAccounts) { account in
                    Button {
                        selectedAccount = account // ← tady přiřazujeme celý objekt
                        isPresented = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .font(.body)
                            if let bank = account.bankAccount {
                                Text("IBAN: \(bank.iban, default: "N/A")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("SWIFT: \(bank.swift, default: "N/A")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Hledat podle názvu účtu")
                .navigationTitle("Vyberte bankovní účet")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Zavřít") { isPresented = false }
                    }
                }
            }
        }
    }
}

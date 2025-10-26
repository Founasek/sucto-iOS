//
//  AccountDetailView.swift
//  SuctoApp
//
//  Created by Jan Founě on 07.10.2025.
//


import SwiftUI

struct AccountDetailView: View {
    let account: Account

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(account.name)
                    .font(.title2)
                    .bold()
                
                if let bank = account.bankAccount {
                    Group {
                        if let iban = bank.iban {
                            InfoRow(label: "IBAN", value: iban)
                        }
                        if let swift = bank.swift {
                            InfoRow(label: "SWIFT", value: swift)
                        }
                        if let accNumber = bank.account {
                            InfoRow(label: "Číslo účtu", value: "\(accNumber)/\(bank.bankCode ?? "")")
                        }
                        if let bankName = bank.bankName {
                            InfoRow(label: "Banka", value: bankName)
                        }
                    }
                }
                
                Divider().padding(.vertical)
                
                InfoRow(
                    label: "Počáteční zůstatek",
                    value: FormatterHelper.formatPrice(account.openingBalance, currency: "Kč")
                )
                
                InfoRow(
                    label: "Prefix",
                    value: account.prefix
                )
                
                InfoRow(
                    label: "Typ účtu",
                    value: account.accountType == 1 ? "Hotovostní" : "Bankovní"
                )
                
                if account.isDeactivated {
                    Text("Účet je deaktivován")
                        .foregroundColor(.red)
                        .bold()
                        .padding(.top, 10)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

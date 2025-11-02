//
//  BankAccountDetailView.swift
//  SuctoApp
//
//  Created by Jan Founě on 07.10.2025.
//

import SwiftUI

struct BankAccountDetailView: View {
    let account: Account

    var body: some View {
        List {
            // 🏷 Název účtu
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.title2)
                    .bold()
            }
            VStack(alignment: .leading, spacing: 24) {
                // 💳 Bankovní údaje (pouze pro bankovní účty)
                if !account.isCashAccount,
                   let bankAccount = account.bankAccount
                {
                    SectionView(title: "Bankovní údaje") {
                        InfoRow(label: "Číslo účtu", value: "\(bankAccount.account, default: " - ")/\(bankAccount.bankCode, default: " - ")")

                        InfoRow(label: "SWIFT", value: "\(bankAccount.swift, default: " - ")")
                        InfoRow(label: "IBAN", value: "\(bankAccount.iban, default: " - ")")
                        InfoRow(label: "Banka", value: "\(bankAccount.bankName, default: " - ")")
                    }
                }

                // 💰 Finanční informace
                SectionView(title: "Zůstatek a parametry") {
                    InfoRow(label: "Prefix", value: account.prefix)

                    InfoRow(
                        label: "Počáteční zůstatek",
                        value: FormatterHelper.formatPrice(account.openingBalance, currency: "Kč")
                    )
                }

                // ⚠️ Stav účtu
                if account.isDeactivated {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Účet je deaktivován")
                            .foregroundColor(.red)
                            .bold()
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
        }
        .navigationTitle(account.isCashAccount ? "Hotovostní účet" : "Bankovní účet")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Podkomponenty

private struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                content
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var copyable: Bool = false
    @State private var copied = false

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .multilineTextAlignment(.trailing)
        }
    }
}

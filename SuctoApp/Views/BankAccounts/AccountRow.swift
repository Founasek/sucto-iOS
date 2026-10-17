//
//  AccountRow.swift
//  SuctoApp
//

import SwiftUI

/// Řádek účtu v profilu firmy.
struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            Image(systemName: account.isCashAccount ? "banknote" : "building.columns")
                .font(.title3)
                .foregroundStyle(Theme.tint)
                .frame(width: 48, height: 48)
                .background(Theme.brand.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(account.name)
                    .font(.headline)
                if !account.isCashAccount, let bank = account.bankAccount, let number = bank.account {
                    Text("\(number)\(bank.bankCode.map { "/\($0)" } ?? "")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else if account.isCashAccount {
                    Text("Hotovost")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if account.isDeactivated {
                Text("Neaktivní")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.12), in: Capsule())
                    .foregroundStyle(.red)
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .card()
        .opacity(account.isDeactivated ? 0.7 : 1)
        .accessibilityElement(children: .combine)
    }
}

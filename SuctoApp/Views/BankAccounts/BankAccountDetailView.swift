//
//  BankAccountDetailView.swift
//  SuctoApp
//
//  Created by Jan Founě on 07.10.2025.
//

import SwiftUI

struct BankAccountDetailView: View {
    let account: Account
    var currencySymbol: String?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                hero

                if !account.isCashAccount, let bank = account.bankAccount {
                    DetailCard(title: "Bankovní údaje", systemImage: "building.columns") {
                        CopyableRow(
                            label: "Číslo účtu",
                            value: bank.account.map { "\($0)/\(bank.bankCode ?? "")" },
                        )
                        CopyableRow(label: "IBAN", value: bank.iban)
                        CopyableRow(label: "SWIFT", value: bank.swift)
                        DetailRow(label: "Banka", value: bank.bankName, hideWhenEmpty: true)
                    }
                }

                DetailCard(title: "Parametry", systemImage: "slider.horizontal.3") {
                    DetailRow(label: "Prefix", value: account.prefix, hideWhenEmpty: true)
                    DetailRow(
                        label: "Počáteční zůstatek",
                        value: FormatterHelper.formatPrice(account.openingBalance, currency: currencySymbol),
                    )
                }

                if account.isDeactivated {
                    Label("Účet je deaktivován", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(Theme.Spacing.m)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                }
            }
            .padding(Theme.Spacing.l)
            .fitsScreenWidth()
        }
        .background(Theme.background)
        .navigationTitle(account.isCashAccount ? "Hotovostní účet" : "Bankovní účet")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Image(systemName: account.isCashAccount ? "banknote" : "building.columns")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.85))
            Text(account.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(FormatterHelper.formatPrice(account.openingBalance, currency: currencySymbol))
                .font(.title.weight(.bold))
                .fontDesign(.rounded)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .monospacedDigit()
                .foregroundStyle(.white)
            Text("Počáteční zůstatek")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.brand.opacity(0.3), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
    }
}

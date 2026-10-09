//
//  BankAccountsView.swift
//  SuctoApp
//
//  Created by Jan Founě on 07.10.2025.
//

import SwiftUI

struct BankAccountsView: View {
    @Namespace private var transitionNamespace
    @EnvironmentObject var viewModel: AccountsViewModel

    var body: some View {
        ScrollView {
            if viewModel.accounts.isEmpty {
                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.fetchAccounts() }
                    }
                } else {
                    EmptyStateView(
                        systemImage: "creditcard",
                        message: "Žádné účty nejsou k dispozici.",
                    )
                }
            } else {
                LazyVStack(spacing: Theme.Spacing.m) {
                    ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { index, account in
                        NavigationLink(value: account) {
                            AccountRow(account: account)
                        }
                        .buttonStyle(PressableCardStyle())
                        .matchedTransitionSource(id: account, in: transitionNamespace)
                        .staggeredAppear(index: index)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .fitsScreenWidth()
                .padding(.vertical, Theme.Spacing.s)
            }
        }
        .background(Theme.background)
        .refreshable { await viewModel.fetchAccounts() }
        .navigationDestination(for: Account.self) { account in
            BankAccountDetailView(account: account, currencySymbol: viewModel.currencySymbol(for: account))
                .navigationTransition(.zoom(sourceID: account, in: transitionNamespace))
        }
    }
}

private struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            Image(systemName: account.isCashAccount ? "banknote" : "building.columns")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
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

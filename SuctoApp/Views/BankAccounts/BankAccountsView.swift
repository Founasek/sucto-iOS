//
//  AccountsView.swift
//  SuctoApp
//
//  Created by Jan Founě on 07.10.2025.
//

import SwiftUI

struct BankAccountsView: View {
    @EnvironmentObject var viewModel: AccountsViewModel
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        if viewModel.accounts.isEmpty {
            ScrollView {
                
                EmptyStateView(
                    systemImage: "creditcard.trianglebadge.exclamationmark",
                    message: "Žádné účty nejsou k dispozici."
                )

            }
            .refreshable {
                Task {
                    await viewModel.fetchAccounts()
                }
            }
            .navigationTitle("Účty")

        } else {
            List(viewModel.accounts) { account in
                VStack(alignment: .leading, spacing: 6) {
                    Text(account.name)
                        .font(.headline)

                    if !account.isCashAccount, let bank = account.bankAccount {
                        Text("Účet: \(bank.account ?? "")\(bank.bankCode != nil ? " / \(bank.bankCode!)" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .onTapGesture {
                    navManager.path.append(AppRoute.accountDetail(account: account))
                }
            }
            .navigationTitle("Účty")
            .refreshable {
                Task {
                    await viewModel.fetchAccounts()
                }
            }
            .overlay {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
    }
}

//
//  AccountsView.swift
//  SuctoApp
//
//  Created by Jan Founě on 07.10.2025.
//

import SwiftUI

struct AccountsView: View {
    @EnvironmentObject var viewModel: AccountsViewModel
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        if viewModel.accounts.isEmpty {
            ScrollView {
                VStack(spacing: 10) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Žádné účty nejsou k dispozici.")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: UIScreen.main.bounds.height * 0.6)
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

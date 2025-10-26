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
        Group {
            if viewModel.accounts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Žádné účty nejsou k dispozici.")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.accounts) { account in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(account.name)
                                .font(.headline)
                            Spacer()
                            Text("\(FormatterHelper.formatPrice(account.openingBalance, currency: nil)) Kč")
                                .font(.subheadline)
                        }
                        if let account = account.bankAccount {
                            Text("Účet: \(account.account ?? "")\(account.bankCode != nil ? " / \(account.bankCode!)" : "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                    }
                    .padding(.vertical, 4)
                    .onTapGesture {
                        navManager.path.append(AppRoute.accountDetail(account: account))
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Účty")
        .task {
            await viewModel.fetchAccounts()
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


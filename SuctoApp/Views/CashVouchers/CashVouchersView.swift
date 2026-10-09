//
//  CashVouchersView.swift
//  SuctoApp
//

import SwiftUI

/// Pokladní doklady (jen čtení a odeslání – API nic dalšího neumožňuje).
struct CashVouchersView: View {
    let companyId: Int
    @StateObject private var viewModel: CashVouchersViewModel

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        _viewModel = StateObject(wrappedValue: CashVouchersViewModel(companyId: companyId, session: session))
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Směr", selection: $viewModel.direction) {
                ForEach(CashDirection.allCases) { direction in
                    Text(direction.title).tag(direction)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)

            ScrollView {
                if viewModel.vouchers.isEmpty {
                    emptyOrLoading
                } else {
                    LazyVStack(spacing: Theme.Spacing.m) {
                        ForEach(Array(viewModel.vouchers.enumerated()), id: \.element.id) { index, voucher in
                            NavigationLink(value: AppRoute.cashVoucherDetail(
                                companyId: companyId, directionRaw: viewModel.direction.rawValue, voucherId: voucher.id,
                            )) {
                                CashVoucherRow(voucher: voucher)
                            }
                            .buttonStyle(PressableCardStyle())
                            .staggeredAppear(index: index)
                            .onAppear {
                                if voucher.id == viewModel.vouchers.last?.id {
                                    Task { await viewModel.fetchNextPage() }
                                }
                            }
                        }
                        if viewModel.isLoading {
                            ProgressView().padding(.vertical, Theme.Spacing.l)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .fitsScreenWidth()
                    .padding(.top, Theme.Spacing.xs)
                }
            }
            .contentMargins(.bottom, 24, for: .scrollContent)
        }
        .background(Theme.background)
        .navigationTitle("Pokladna")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Číslo dokladu nebo příjemce")
        .onChange(of: viewModel.searchText) { viewModel.searchTextChanged() }
        .refreshable { await viewModel.refresh() }
        .task { if viewModel.vouchers.isEmpty { await viewModel.refresh() } }
    }

    @ViewBuilder
    private var emptyOrLoading: some View {
        if viewModel.isLoading {
            LoadingStateView(message: "Načítám doklady…")
                .padding(.top, Theme.Spacing.xxl)
        } else if let error = viewModel.errorMessage {
            ErrorStateView(message: error) { Task { await viewModel.refresh() } }
        } else if viewModel.isSearching {
            EmptyStateView(systemImage: "magnifyingglass", message: "Žádný doklad neodpovídá hledání.")
        } else {
            EmptyStateView(systemImage: "banknote", message: "Zatím tu nejsou žádné \(viewModel.direction.title.lowercased()) doklady.")
        }
    }
}

private struct CashVoucherRow: View {
    let voucher: CashVoucher

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(voucher.number)
                    .font(.headline)
                if let name = voucher.recipient?.name, !name.isEmpty {
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if let date = voucher.transactionDate {
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                Text(FormatterHelper.formatPrice(voucher.totalPrice, currency: nil))
                    .moneyStyle(.headline)
                if voucher.isStorno {
                    Text("Storno").font(.caption2.weight(.semibold)).foregroundStyle(.red)
                }
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

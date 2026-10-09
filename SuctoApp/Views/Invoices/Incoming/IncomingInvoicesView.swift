//
//  IncomingInvoicesView.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import SwiftUI

struct IncomingInvoicesView: View {
    /// Jmenný prostor zoom přechodu do detailu; patří dashboardu, který detail otevírá.
    let namespace: Namespace.ID
    @EnvironmentObject var viewModel: IncomingInvoicesViewModel

    var body: some View {
        InvoiceListView(
            invoices: viewModel.invoices,
            isLoading: viewModel.isLoadingPage,
            errorMessage: viewModel.errorMessage,
            emptyMessage: "Zatím tu nejsou žádné přijaté faktury.",
            filter: $viewModel.filter,
            advanced: $viewModel.advanced,
            isFiltering: viewModel.isFiltering,
            clearFilters: { viewModel.clearFilters() },
            counterparty: { $0.supplier?.name },
            refresh: { await viewModel.refresh() },
            loadMore: { await viewModel.fetchNextPage() },
            namespace: namespace,
        )
        .searchable(text: $viewModel.searchText, prompt: "Číslo faktury nebo dodavatel")
        .onChange(of: viewModel.searchText) { viewModel.searchTextChanged() }
    }
}

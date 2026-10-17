//
//  OutgoingInvoicesView.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import SwiftUI

struct OutgoingInvoicesView: View {
    /// Jmenný prostor zoom přechodu do detailu; patří dashboardu, který detail otevírá.
    let namespace: Namespace.ID
    @EnvironmentObject var viewModel: OutgoingInvoicesViewModel

    var body: some View {
        InvoiceListView(
            invoices: viewModel.invoices,
            isLoading: viewModel.isLoadingPage,
            errorMessage: viewModel.errorMessage,
            emptyMessage: "Zatím tu nejsou žádné vydané faktury.\nVytvoříte je tlačítkem Nová faktura.",
            searchText: $viewModel.searchText,
            searchPrompt: "Číslo faktury nebo odběratel",
            filter: $viewModel.filter,
            advanced: $viewModel.advanced,
            isFiltering: viewModel.isFiltering,
            clearFilters: { viewModel.clearFilters() },
            counterparty: { $0.customer?.name },
            refresh: { await viewModel.refresh() },
            loadMore: { await viewModel.fetchNextPage() },
            namespace: namespace,
        )
        .onChange(of: viewModel.searchText) { viewModel.searchTextChanged() }
    }
}

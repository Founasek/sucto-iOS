//
//  OutgoingInvoicesView.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import SwiftUI

struct OutgoingInvoicesView: View {
    @Namespace private var transitionNamespace
    @EnvironmentObject var viewModel: OutgoingInvoicesViewModel

    var body: some View {
        InvoiceListView(
            invoices: viewModel.invoices,
            isLoading: viewModel.isLoadingPage,
            errorMessage: viewModel.errorMessage,
            emptyMessage: "Zatím tu nejsou žádné vydané faktury.\nVytvoříte je tlačítkem Nová faktura.",
            filter: $viewModel.filter,
            isFiltering: viewModel.isFiltering,
            clearFilters: { viewModel.clearFilters() },
            counterparty: { $0.customer?.name },
            refresh: { await viewModel.refresh() },
            loadMore: { await viewModel.fetchNextPage() },
            namespace: transitionNamespace,
        )
        .searchable(text: $viewModel.searchText, prompt: "Číslo faktury nebo odběratel")
        .onChange(of: viewModel.searchText) { viewModel.searchTextChanged() }
        .navigationDestination(for: Invoice.self) { invoice in
            OutgoingInvoiceDetailView(invoiceId: invoice.id)
                .environmentObject(viewModel)
                .navigationTransition(.zoom(sourceID: invoice.id, in: transitionNamespace))
        }
    }
}

//
//  IncomingInvoicesView.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import SwiftUI

struct IncomingInvoicesView: View {
    @Namespace private var transitionNamespace
    @EnvironmentObject var viewModel: IncomingInvoicesViewModel

    var body: some View {
        InvoiceListView(
            invoices: viewModel.invoices,
            isLoading: viewModel.isLoadingPage,
            errorMessage: viewModel.errorMessage,
            emptyMessage: "Zatím tu nejsou žádné přijaté faktury.",
            filter: $viewModel.filter,
            isFiltering: viewModel.isFiltering,
            clearFilters: { viewModel.clearFilters() },
            counterparty: { $0.supplier?.name },
            refresh: { await viewModel.refresh() },
            loadMore: { await viewModel.fetchNextPage() },
            namespace: transitionNamespace,
        )
        .searchable(text: $viewModel.searchText, prompt: "Číslo faktury nebo dodavatel")
        .onChange(of: viewModel.searchText) { viewModel.searchTextChanged() }
        .navigationDestination(for: Invoice.self) { invoice in
            IncomingInvoiceDetailView(invoiceId: invoice.id)
                .environmentObject(viewModel)
                .navigationTransition(.zoom(sourceID: invoice.id, in: transitionNamespace))
        }
    }
}

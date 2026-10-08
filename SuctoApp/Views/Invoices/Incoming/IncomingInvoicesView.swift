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
            counterparty: { $0.supplier?.name },
            refresh: { await viewModel.refresh() },
            loadMore: { await viewModel.fetchNextPage() },
            namespace: transitionNamespace,
        )
        .navigationDestination(for: Invoice.self) { invoice in
            IncomingInvoiceDetailView(invoiceId: invoice.id)
                .environmentObject(viewModel)
                .navigationTransition(.zoom(sourceID: invoice.id, in: transitionNamespace))
        }
    }
}

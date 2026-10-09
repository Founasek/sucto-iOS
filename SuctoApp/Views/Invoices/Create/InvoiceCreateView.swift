//
//  InvoiceCreateView.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import SwiftUI

struct InvoiceCreateView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: InvoiceCreateViewModel
    @FocusState var keyboardFocused: Bool

    init(
        companyId: Int,
        direction: InvoiceDirection,
        scanId: String? = nil,
        copyFromInvoiceId: Int? = nil,
        session: SessionManager,
    ) {
        _viewModel = StateObject(wrappedValue: InvoiceCreateViewModel(
            companyId: companyId, direction: direction, scanId: scanId, copyFromInvoiceId: copyFromInvoiceId, session: session,
        ))
    }

    var currencyCode: String {
        viewModel.selectedCurrency?.isoCode ?? "CZK"
    }

    var body: some View {
        Form {
            if viewModel.isCopy { CopyBanner() }
            if let supplier = viewModel.scanSupplier {
                ScanBanner(supplier: supplier, notMatched: viewModel.scanSupplierNotMatched)
            }
            basicSection
            datesSection
            paymentSection
            itemsSection
            totalsSection
            notesSection

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .overlay {
            if viewModel.loadFailed {
                ErrorStateView(message: viewModel.errorMessage ?? "Údaje se nepodařilo načíst.") {
                    Task { await viewModel.loadInitialData() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(viewModel.direction.createTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await viewModel.createInvoice()
                        if viewModel.creationSuccess { dismiss() }
                    }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Text("Vytvořit").fontWeight(.semibold)
                    }
                }
                .disabled(viewModel.isSubmitting)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Hotovo") { keyboardFocused = false }
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.creationSuccess)
        .sensoryFeedback(.error, trigger: viewModel.errorMessage) { _, new in new != nil }
        .task {
            await viewModel.loadInitialData()
        }
    }
}

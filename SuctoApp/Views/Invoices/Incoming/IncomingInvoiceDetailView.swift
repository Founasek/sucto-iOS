//
//  IncomingInvoiceDetailView.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import SwiftUI

struct IncomingInvoiceDetailView: View {
    let invoiceId: Int
    @EnvironmentObject var viewModel: IncomingInvoicesViewModel
    @State private var showExportSheet = false
    @EnvironmentObject private var permissions: PermissionsStore
    @State private var lineSheet: LineSheet?

    /// Co se právě edituje: nová položka, nebo existující.
    private struct LineSheet: Identifiable {
        let item: InvoiceItem?
        var id: Int { item?.id ?? -1 }
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoadingDetail {
                LoadingStateView(message: "Načítám fakturu…")
            } else if let error = viewModel.detailErrorMessage {
                ErrorStateView(message: error) {
                    Task { await viewModel.fetchInvoiceDetail(invoiceId: invoiceId) }
                }
            } else if let invoice = viewModel.selectedInvoice {
                content(for: invoice)
            } else {
                EmptyStateView(
                    systemImage: "doc.text.magnifyingglass",
                    message: "Faktura není k dispozici.",
                )
            }
        }
        .navigationTitle("Detail faktury")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.background)
        .toolbar {
            if viewModel.selectedInvoice != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showExportSheet = true
                        } label: {
                            Label("Exportovat do Pohody", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Akce faktury")
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            PohodaExportSheet(
                companyId: viewModel.companyId,
                session: viewModel.session,
                direction: .incoming,
                mode: .invoice(id: invoiceId, number: viewModel.selectedInvoice?.actuarialNumber ?? ""),
            )
        }
        .sheet(item: $lineSheet) { sheet in
            InvoiceLineEditSheet(
                item: sheet.item,
                currency: viewModel.selectedInvoice?.currency?.symbol,
                session: viewModel.session,
                onSave: { request in
                    let error = await viewModel.saveLine(invoiceId: invoiceId, lineId: sheet.item?.id, request: request)
                    if error == nil { await reloadAfterLineChange() }
                    return error
                },
                onDelete: sheet.item.map { item in
                    {
                        let error = await viewModel.deleteLine(invoiceId: invoiceId, lineId: item.id)
                        if error == nil { await reloadAfterLineChange() }
                        return error
                    }
                },
            )
        }
        .task {
            await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
        }
        .refreshable {
            await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
        }
    }

    private func content(for invoice: Invoice) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            InvoiceHeroCard(
                invoice: invoice,
                counterparty: invoice.supplier?.name,
                showBasePrice: invoice.supplier?.isTaxable == true,
            )

            DetailCard(title: "Základní informace", systemImage: "info.circle") {
                DetailRow(label: "Externí číslo", value: invoice.externalNumber, hideWhenEmpty: true)
                DetailRow(label: "Číslo objednávky", value: invoice.orderNumber, hideWhenEmpty: true)
                DetailRow(label: "Variabilní symbol", value: invoice.variableSymbol, hideWhenEmpty: true)
            }

            DetailCard(title: "Dodavatel", systemImage: "building.2") {
                DetailRow(label: "Název", value: invoice.supplier?.name)
                DetailRow(label: "IČO", value: invoice.supplier?.ic, hideWhenEmpty: true)
                DetailRow(label: "DIČ", value: invoice.supplier?.dic, hideWhenEmpty: true)
                DetailRow(label: "Plátce DPH", value: invoice.supplier?.isTaxable == true ? "Ano" : "Ne")
            }

            InvoiceDatesCard(invoice: invoice)
            InvoiceItemsCard(invoice: invoice, editing: itemEditing(for: invoice))
        }
        .padding(Theme.Spacing.l)
    }

    /// Úprava položek je jen pro uživatele s právem `update` a u faktur, které nejsou stornované.
    private func itemEditing(for invoice: Invoice) -> InvoiceItemEditing? {
        guard permissions.can(.update, InvoiceDirection.incoming.permissionResource, companyId: viewModel.companyId),
              invoice.invoiceStatus != .storno
        else { return nil }
        return InvoiceItemEditing(
            onAdd: { lineSheet = LineSheet(item: nil) },
            onEdit: { item in lineSheet = LineSheet(item: item) },
        )
    }

    private func reloadAfterLineChange() async {
        await viewModel.fetchInvoiceDetail(invoiceId: invoiceId)
        await viewModel.refresh()
    }
}

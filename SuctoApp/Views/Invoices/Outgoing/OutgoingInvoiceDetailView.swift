//
//  OutgoingInvoiceDetailView.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import SwiftUI

struct OutgoingInvoiceDetailView: View {
    let invoiceId: Int
    @EnvironmentObject var viewModel: OutgoingInvoicesViewModel
    @State var showSendSheet = false
    @State var showReminderSheet = false
    @AppStorage(ReminderSettings.enabledKey) var remindersEnabled = false
    @State var showExportSheet = false
    @EnvironmentObject var permissions: PermissionsStore
    @EnvironmentObject var navManager: NavigationManager
    @State var lineSheet: LineSheet?
    @State var qrInput: PaymentQR.Input?

    /// Co se právě edituje: nová položka, nebo existující.
    struct LineSheet: Identifiable {
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
        .safeAreaInset(edge: .bottom) { payBar }
        .overlay {
            if let confirmation = viewModel.confirmation {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    PaymentSuccessOverlay(title: confirmation.title, message: confirmation.message)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.confirmation) { _, new in new != nil }
        .toolbar {
            if let invoice = viewModel.selectedInvoice {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showSendSheet = true
                        } label: {
                            Label("Odeslat e-mailem", systemImage: "paperplane")
                        }
                        .disabled(invoice.invoiceStatus == .storno)

                        if let input = invoice.paymentQRInput(recipientName: viewModel.session.selectedCompany?.name) {
                            Button {
                                qrInput = input
                            } label: {
                                Label("QR kód k úhradě", systemImage: "qrcode")
                            }
                        }

                        if permissions.can(.create, InvoiceDirection.outgoing.permissionResource, companyId: viewModel.companyId) {
                            Button {
                                navManager.duplicateInvoice(companyId: viewModel.companyId, direction: .outgoing, invoiceId: invoiceId)
                            } label: {
                                Label("Duplikovat fakturu", systemImage: "doc.on.doc")
                            }
                        }

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
                mode: .invoice(id: invoiceId, number: viewModel.selectedInvoice?.actuarialNumber ?? ""),
            )
        }
        .sheet(isPresented: $showReminderSheet) {
            if let invoice = viewModel.selectedInvoice {
                reminderSheet(for: invoice)
            }
        }
        .sheet(isPresented: $showSendSheet) {
            SendEmailSheet(invoiceNumber: viewModel.selectedInvoice?.actuarialNumber ?? "") { email, comment in
                await viewModel.sendByEmail(invoiceId: invoiceId, email: email, comment: comment)
            }
        }
        .sheet(isPresented: Binding(get: { qrInput != nil }, set: { if !$0 { qrInput = nil } })) {
            if let invoice = viewModel.selectedInvoice, let input = qrInput {
                InvoiceQRSheet(invoice: invoice, input: input)
            }
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
        .alert(
            "Úhradu se nepodařilo provést",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } },
            ),
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    private func content(for invoice: Invoice) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            InvoiceHeroCard(
                invoice: invoice,
                counterparty: invoice.customer?.name,
                showBasePrice: invoice.taxable == true,
            )

            DetailCard(title: "Základní informace", systemImage: "info.circle") {
                DetailRow(label: "Variabilní symbol", value: invoice.variableSymbol, hideWhenEmpty: true)
                DetailRow(label: "Externí číslo", value: invoice.externalNumber, hideWhenEmpty: true)
                DetailRow(label: "Číslo objednávky", value: invoice.orderNumber, hideWhenEmpty: true)
            }

            if remindersEnabled, invoice.isOverdue {
                OverdueReminderCard(invoice: invoice) { showReminderSheet = true }
            }

            InvoicePaymentCard(invoice: invoice)

            DetailCard(title: "Zákazník", systemImage: "person.crop.circle") {
                DetailRow(label: "Název", value: invoice.customer?.name)
                DetailRow(label: "IČO", value: invoice.customer?.ic, hideWhenEmpty: true)
                DetailRow(label: "DIČ", value: invoice.customer?.dic, hideWhenEmpty: true)
                DetailRow(label: "Adresa", value: invoice.customer?.addressLine, hideWhenEmpty: true)
                DetailRow(label: "E-mail", value: invoice.customer?.email, hideWhenEmpty: true)
            }

            InvoiceBankCard(invoice: invoice)
            InvoiceDatesCard(invoice: invoice)
            InvoiceItemsCard(invoice: invoice, editing: itemEditing(for: invoice))
        }
        .padding(Theme.Spacing.l)
        .fitsScreenWidth()
    }
}

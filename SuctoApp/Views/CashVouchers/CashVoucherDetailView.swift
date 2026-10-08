//
//  CashVoucherDetailView.swift
//  SuctoApp
//

import SwiftUI

struct CashVoucherDetailView: View {
    @StateObject private var viewModel: CashVoucherDetailViewModel
    @State private var showEmailSheet = false
    @State private var confirmSendToPartner = false

    init(companyId: Int, direction: CashDirection, voucherId: Int, session: SessionManager) {
        _viewModel = StateObject(wrappedValue: CashVoucherDetailViewModel(
            companyId: companyId, direction: direction, voucherId: voucherId, session: session,
        ))
    }

    var body: some View {
        Group {
            if let voucher = viewModel.voucher {
                content(voucher)
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) { Task { await viewModel.load() } }
            } else {
                LoadingStateView(message: "Načítám doklad…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle("Pokladní doklad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let voucher = viewModel.voucher, !voucher.isStorno {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showEmailSheet = true } label: { Label("Odeslat e-mailem", systemImage: "paperplane") }
                        Button { confirmSendToPartner = true } label: { Label("Odeslat partnerovi", systemImage: "person.crop.circle.badge.checkmark") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Akce dokladu")
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $showEmailSheet) {
            SendEmailSheet(invoiceNumber: viewModel.voucher?.number ?? "") { email, comment in
                await viewModel.sendToEmail(email, comment: comment)
            }
        }
        .confirmationDialog("Odeslat doklad partnerovi?", isPresented: $confirmSendToPartner, titleVisibility: .visible) {
            Button("Odeslat") { Task { await viewModel.sendToPartner() } }
            Button("Zrušit", role: .cancel) {}
        } message: {
            Text("Doklad se pošle na e-mail partnera uložený v sÚčtu.")
        }
        .alert("Odeslání se nezdařilo", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } },
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .alert("Odesláno", isPresented: Binding(
            get: { viewModel.confirmation != nil },
            set: { if !$0 { viewModel.confirmation = nil } },
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.confirmation ?? "")
        }
        .sensoryFeedback(.success, trigger: viewModel.confirmation) { _, new in new != nil }
    }

    private func content(_ voucher: CashVoucher) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                hero(voucher)

                DetailCard(title: "Základní informace", systemImage: "info.circle") {
                    DetailRow(label: "Datum", value: voucher.transactionDate, hideWhenEmpty: true)
                    DetailRow(label: "Popis", value: voucher.description, hideWhenEmpty: true)
                    DetailRow(label: "Účet", value: voucher.account, hideWhenEmpty: true)
                    DetailRow(label: "Externí číslo", value: voucher.externalNumber, hideWhenEmpty: true)
                    DetailRow(label: "Stav", value: voucher.statusTitle, valueColor: voucher.isStorno ? .red : .primary, hideWhenEmpty: true)
                }

                if let recipient = voucher.recipient, recipient.name != nil {
                    DetailCard(title: "Příjemce", systemImage: "person.crop.circle") {
                        DetailRow(label: "Název", value: recipient.name)
                        DetailRow(label: "IČ", value: recipient.ic, hideWhenEmpty: true)
                        DetailRow(label: "DIČ", value: recipient.dic, hideWhenEmpty: true)
                        DetailRow(label: "Adresa", value: recipient.addressLine, hideWhenEmpty: true)
                    }
                }

                if !voucher.items.isEmpty {
                    DetailCard(title: "Položky", systemImage: "list.bullet") {
                        ForEach(voucher.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name).font(.subheadline).fontWeight(.medium)
                                    if let quantity = item.quantity, let unit = item.unitName {
                                        Text("\(quantity) \(unit)").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if let price = item.totalPrice {
                                    Text(FormatterHelper.formatPrice(price, currency: nil)).font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.l)
        }
        .refreshable { await viewModel.load() }
    }

    private func hero(_ voucher: CashVoucher) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(voucher.number)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))
            Text(FormatterHelper.formatPrice(voucher.totalPrice, currency: nil))
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(.white)
            if let base = voucher.basePrice, base != voucher.totalPrice {
                Text("bez DPH \(FormatterHelper.formatPrice(base, currency: nil))")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.brand.opacity(0.3), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
    }
}

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
    @FocusState private var keyboardFocused: Bool

    init(companyId: Int, direction: InvoiceDirection, scanId: String? = nil, session: SessionManager) {
        _viewModel = StateObject(wrappedValue: InvoiceCreateViewModel(companyId: companyId, direction: direction, scanId: scanId, session: session))
    }

    private var currencyCode: String {
        viewModel.selectedCurrency?.isoCode ?? "CZK"
    }

    var body: some View {
        Form {
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

    // MARK: - Sekce

    private var basicSection: some View {
        Section {
            LabeledContent("Číslo faktury") {
                if viewModel.direction.numberIsEditable {
                    TextField("Číslo od dodavatele", text: $viewModel.actuarialNumber)
                        .multilineTextAlignment(.trailing)
                        .focused($keyboardFocused)
                } else {
                    Text(viewModel.actuarialNumber.isEmpty ? "—" : viewModel.actuarialNumber)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }

            LabeledContent("Variabilní symbol") {
                TextField("", text: $viewModel.variableSymbol)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($keyboardFocused)
            }

            PartnerPickerView(
                selectedPartner: $viewModel.selectedPartner,
                partners: viewModel.availablePartners,
                label: viewModel.direction.partnerLabel,
                placeholder: viewModel.direction.partnerPlaceholder,
                onSearch: { await viewModel.searchPartners($0) },
            )
            .onChange(of: viewModel.selectedPartner?.id) {
                viewModel.applyPartnerDefaults()
            }
        } header: {
            Text("Základní informace")
        }
    }

    private var datesSection: some View {
        Section("Časové údaje") {
            DatePicker("Datum vystavení", selection: $viewModel.issueDate, displayedComponents: .date)
            DatePicker("Datum splatnosti", selection: $viewModel.dueDate, displayedComponents: .date)
            DatePicker("Datum UZP", selection: $viewModel.uzpDate, displayedComponents: .date)
        }
    }

    private var paymentSection: some View {
        Section("Platební a daňové údaje") {
            AccountPickerView(
                selectedAccount: $viewModel.selectedAccount,
                accounts: viewModel.availableAccounts,
            )

            CurrencyPickerView(
                selectedCurrency: $viewModel.selectedCurrency,
                currencies: viewModel.availableCurrencies,
            )

            PaymentTypePickerView(
                selectedPaymentType: $viewModel.selectedPaymentType,
                paymentTypes: viewModel.availablePaymentTypes,
            )

            if viewModel.isCompanyTaxable {
                VatRegimePickerView(
                    selectedVatRegime: $viewModel.selectedVatRegime,
                    vatRegimes: viewModel.availableVatRegimes,
                )
            }

            LabeledContent("Číslo objednávky") {
                TextField("", text: $viewModel.orderNumber)
                    .multilineTextAlignment(.trailing)
                    .focused($keyboardFocused)
            }
        }
    }

    private var itemsSection: some View {
        Group {
            if viewModel.direction == .outgoing {
                Section {
                    TextField("Úvodní text", text: $viewModel.printNotice, axis: .vertical)
                        .lineLimit(1 ... 3)
                        .focused($keyboardFocused)
                } header: {
                    Text("Úvodní text faktury")
                }
            }

            ForEach($viewModel.items) { $item in
                Section {
                    itemFields($item)
                } header: {
                    HStack {
                        Text("Položka")
                        Spacer()
                        Button(role: .destructive) {
                            withAnimation(.snappy) {
                                viewModel.items.removeAll { $0.id == item.id }
                            }
                        } label: {
                            Label("Smazat", systemImage: "trash")
                                .font(.footnote)
                                .labelStyle(.iconOnly)
                        }
                        .accessibilityLabel("Smazat položku")
                    }
                }
            }

            Section {
                Button {
                    withAnimation(.snappy) {
                        viewModel.items.append(viewModel.makeEmptyLine())
                    }
                } label: {
                    Label("Přidat položku", systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func itemFields(_ item: Binding<InvoiceCreateLine>) -> some View {
        TextField("Název položky", text: item.name)
            .textInputAutocapitalization(.sentences)
            .focused($keyboardFocused)

        LabeledContent("Množství") {
            TextField("0", value: item.quantity, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($keyboardFocused)
        }

        LabeledContent("Jednotka") {
            TextField("ks / h / MD", text: Binding(
                get: { item.wrappedValue.unitName ?? "" },
                set: { item.wrappedValue.unitName = $0 },
            ))
            .multilineTextAlignment(.trailing)
            .focused($keyboardFocused)
        }

        LabeledContent("Cena za jednotku") {
            TextField("0", value: item.unitPrice, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($keyboardFocused)
        }

        Picker("Sazba DPH", selection: item.vatId) {
            ForEach(viewModel.availableVats) { vat in
                Text("\(vat.value) %").tag(vat.id)
            }
        }

        LabeledContent("Celkem bez DPH") {
            Text(item.wrappedValue.quantity * item.wrappedValue.unitPrice, format: .currency(code: currencyCode))
                .moneyStyle(.subheadline)
                .foregroundStyle(Color.accentColor)
                .contentTransition(.numericText())
        }
    }

    private var totalsSection: some View {
        let totals = viewModel.totals
        return Section {
            if viewModel.isCompanyTaxable {
                LabeledContent("Základ") {
                    Text(totals.base, format: .currency(code: currencyCode)).monospacedDigit()
                }
                LabeledContent("DPH") {
                    Text(totals.tax, format: .currency(code: currencyCode)).monospacedDigit()
                }
            }
            LabeledContent {
                Text(viewModel.isCompanyTaxable ? totals.total : totals.base, format: .currency(code: currencyCode))
                    .moneyStyle(.title3)
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.numericText())
            } label: {
                Text("Celkem").font(.headline)
            }
        } header: {
            Text("Souhrn")
        }
        .animation(.snappy, value: totals.total)
    }

    private var notesSection: some View {
        Section("Patička") {
            TextField("Text v patičce faktury", text: $viewModel.footNotice, axis: .vertical)
                .lineLimit(1 ... 3)
                .focused($keyboardFocused)
        }
    }
}

/// Upozornění nad formulářem vytvářeným ze skenu: co se z dokladu přečetlo.
private struct ScanBanner: View {
    let supplier: InitSupplier
    let notMatched: Bool

    var body: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Předvyplněno z naskenovaného dokladu")
                        .font(.subheadline.weight(.semibold))
                    Text([supplier.name, supplier.ic.map { "IČ \($0)" }].compactMap(\.self).joined(separator: " · "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(notMatched
                        ? "Dodavatele jsme v adresáři partnerů nenašli – vyberte ho ručně. Údaje zkontrolujte."
                        : "Údaje před vytvořením zkontrolujte.")
                        .font(.footnote)
                        .foregroundStyle(notMatched ? Color.orange : Color.secondary)
                }
            } icon: {
                Image(systemName: "doc.viewfinder").foregroundStyle(Color.accentColor)
            }
        }
    }
}

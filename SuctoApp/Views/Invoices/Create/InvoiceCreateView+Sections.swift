//
//  InvoiceCreateView+Sections.swift
//  SuctoApp
//

import SwiftUI

/// Sekce formuláře nové faktury: základní údaje, data a platba.
extension InvoiceCreateView {
    var basicSection: some View {
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

    var datesSection: some View {
        Section("Časové údaje") {
            DatePicker("Datum vystavení", selection: $viewModel.issueDate, displayedComponents: .date)
            DatePicker("Datum splatnosti", selection: $viewModel.dueDate, displayedComponents: .date)
            DatePicker("Datum UZP", selection: $viewModel.uzpDate, displayedComponents: .date)
        }
    }

    var paymentSection: some View {
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

    var notesSection: some View {
        Section("Patička") {
            TextField("Text v patičce faktury", text: $viewModel.footNotice, axis: .vertical)
                .lineLimit(1 ... 3)
                .focused($keyboardFocused)
        }
    }
}

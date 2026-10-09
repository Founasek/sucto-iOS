//
//  InvoiceCreateView+Items.swift
//  SuctoApp
//

import SwiftUI

/// Položky faktury a souhrn částek.
extension InvoiceCreateView {
    var itemsSection: some View {
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
    func itemFields(_ item: Binding<InvoiceCreateLine>) -> some View {
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

    var totalsSection: some View {
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
}

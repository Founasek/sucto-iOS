//
//  InvoiceDetailCards.swift
//  SuctoApp
//

import SwiftUI

/// Částky a platba: typ dokladu, způsob platby, základ, DPH, celkem, uhrazeno a zbývá uhradit.
struct InvoicePaymentCard: View {
    let invoice: Invoice

    private var currency: String? { invoice.currency?.symbol }

    /// DPH se dopočítá jako rozdíl celkem − základ (API má na faktuře jen text `vat` neznámého významu).
    private var vatAmount: String? {
        guard let base = invoice.basePrice.flatMap(Double.init), let end = invoice.endPrice.flatMap(Double.init),
              abs(end - base) >= 0.005 else { return nil }
        return FormatterHelper.formatPrice(String(end - base), currency: currency)
    }

    private var remainingValue: Double { invoice.remaining.flatMap(Double.init) ?? 0 }

    var body: some View {
        DetailCard(title: "Částky a platba", systemImage: "banknote") {
            DetailRow(label: "Typ dokladu", value: invoice.actuarialType, hideWhenEmpty: true)
            DetailRow(label: "Způsob platby", value: invoice.paymentType?.value, hideWhenEmpty: true)
            DetailRow(label: "Základ", value: FormatterHelper.formatPrice(invoice.basePrice, currency: currency), hideWhenEmpty: true)
            DetailRow(label: "DPH", value: vatAmount, hideWhenEmpty: true)
            DetailRow(label: "Celkem", value: FormatterHelper.formatPrice(invoice.endPrice, currency: currency), bold: true, hideWhenEmpty: true)
            DetailRow(label: "Uhrazeno", value: invoice.pay, hideWhenEmpty: true)
            DetailRow(
                label: "Zbývá uhradit",
                value: FormatterHelper.formatPrice(invoice.remaining, currency: currency),
                valueColor: remainingValue > 0 && invoice.isOverdue ? .red : .primary,
                bold: remainingValue > 0,
                hideWhenEmpty: true,
            )
        }
    }
}

/// Platební údaje na faktuře: účet, banka, IBAN, SWIFT, PayPal. Hodnoty lze klepnutím zkopírovat.
struct InvoiceBankCard: View {
    let invoice: Invoice

    private var bank: BankAccount? { invoice.account?.bankAccount }

    private var accountNumber: String? {
        let number = bank?.account ?? invoice.bankNumber?.value
        guard let number, !number.isEmpty else { return nil }
        guard let code = bank?.bankCode, !code.isEmpty else { return number }
        return "\(number)/\(code)"
    }

    private var iban: String? { first(invoice.iban?.value, bank?.iban) }
    private var swift: String? { first(invoice.swift?.value, bank?.swift) }

    /// První neprázdná hodnota.
    private func first(_ values: String?...) -> String? {
        values.compactMap(\.self).first { !$0.isEmpty }
    }

    var hasContent: Bool {
        [accountNumber, iban, swift, bank?.bankName, invoice.paypalIdentifier?.value, invoice.account?.name]
            .contains { !($0 ?? "").isEmpty }
    }

    var body: some View {
        if hasContent {
            DetailCard(title: "Platební údaje", systemImage: "creditcard") {
                DetailRow(label: "Účet", value: invoice.account?.name, hideWhenEmpty: true)
                CopyableRow(label: "Číslo účtu", value: accountNumber)
                CopyableRow(label: "IBAN", value: iban)
                CopyableRow(label: "SWIFT", value: swift)
                DetailRow(label: "Banka", value: bank?.bankName, hideWhenEmpty: true)
                CopyableRow(label: "PayPal", value: invoice.paypalIdentifier?.value)
            }
        }
    }
}

extension Invoice {
    /// Patička a úvodní text jako jedna poznámka (jen vyplněné části).
    var notes: [String] {
        [printNotice, footNotice].compactMap(\.self).filter { !$0.isEmpty }
    }
}

/// Jedna položka faktury: název, množství × jednotková cena, DPH, sleva a celkem.
struct InvoiceItemRow: View {
    let item: InvoiceItem
    let currency: String?
    var showsChevron = false

    /// „21.0“ → „21“.
    private func clean(_ value: String?) -> String? {
        guard let value, let number = Double(value) else { return value }
        return number == number.rounded() ? String(Int(number)) : String(number).replacingOccurrences(of: ".", with: ",")
    }

    private var quantityLine: String? {
        guard let quantity = clean(item.quantity) else { return nil }
        let unit = (item.unitName ?? "").isEmpty ? "" : " \(item.unitName ?? "")"
        let price = item.unitPrice.map { " × " + FormatterHelper.formatPrice($0, currency: currency) } ?? ""
        return quantity + unit + price
    }

    private var detailLine: String? {
        var parts: [String] = []
        if let vat = clean(item.vat), vat != "0" || item.tax != nil { parts.append("DPH \(vat) %") }
        if let base = item.basePrice { parts.append("základ " + FormatterHelper.formatPrice(base, currency: currency)) }
        if let discount = clean(item.discountPercentage), discount != "0" { parts.append("sleva \(discount) %") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let quantityLine {
                    Text(quantityLine).font(.caption).foregroundStyle(.secondary)
                }
                if let detailLine {
                    Text(detailLine).font(.caption).foregroundStyle(.secondary)
                }
            }
            if let price = item.totalPrice {
                Text(FormatterHelper.formatPrice(price, currency: currency))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 3)
            }
        }
        .padding(.top, 8)
        .contentShape(Rectangle())
    }
}

struct InvoiceDatesCard: View {
    let invoice: Invoice

    var body: some View {
        DetailCard(title: "Časové údaje", systemImage: "calendar") {
            DetailRow(label: "Datum vystavení:", value: invoice.issueDateAt)
            DetailRow(label: "Datum splatnosti:", value: invoice.dueDateAt)
            DetailRow(label: "Datum UZP:", value: invoice.uzpDateAt)
        }
    }
}

/// Akce nad položkami faktury (jen když na ně má uživatel právo).
struct InvoiceItemEditing {
    let onAdd: () -> Void
    let onEdit: (InvoiceItem) -> Void
}

struct InvoiceItemsCard: View {
    let invoice: Invoice
    var editing: InvoiceItemEditing?

    var body: some View {
        let items = invoice.items ?? []
        if !invoice.notes.isEmpty || !items.isEmpty || editing != nil {
            DetailCard(title: "Poznámka a položky", systemImage: "bubble.right") {
                ForEach(invoice.notes, id: \.self) { note in
                    Text(note)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(items) { item in
                    if let editing {
                        Button { editing.onEdit(item) } label: {
                            InvoiceItemRow(item: item, currency: invoice.currency?.symbol, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Upraví položku")
                    } else {
                        InvoiceItemRow(item: item, currency: invoice.currency?.symbol)
                    }
                }
                if let editing {
                    Button { editing.onAdd() } label: {
                        Label("Přidat položku", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}

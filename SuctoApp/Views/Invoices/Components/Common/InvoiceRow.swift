//
//  InvoiceRow.swift
//  SuctoApp
//

import SwiftUI

/// Karta faktury v seznamu (společná pro vydané i přijaté).
struct InvoiceRow: View {
    let invoice: Invoice
    /// Odběratel (vydané) nebo dodavatel (přijaté).
    let counterparty: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(invoice.actuarialNumber)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.s)
                StatusBadge(invoice: invoice)
            }

            Text(counterparty ?? "—")
                .font(.headline)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .lastTextBaseline) {
                Text(FormatterHelper.formatPrice(invoice.endPrice, currency: invoice.currency?.symbol))
                    .moneyStyle(.title3)
                Spacer()
                dueLabel
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var dueLabel: some View {
        if let due = invoice.dueDateAt {
            Label(due, systemImage: "calendar")
                .font(.footnote)
                .foregroundStyle(invoice.isOverdue ? Color.red : Color.secondary)
                .labelStyle(.titleAndIcon)
                .accessibilityLabel("Splatnost \(due)")
        }
    }
}

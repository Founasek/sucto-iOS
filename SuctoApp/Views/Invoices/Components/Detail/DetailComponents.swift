//
//  DetailComponents.swift
//  SuctoApp
//

import SwiftUI

/// Karta s nadpisem sekce používaná na detailu faktury.
struct DetailCard<Content: View>: View {
    let title: String?
    var systemImage: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if let title {
                HStack(spacing: Theme.Spacing.s) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(title.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                    Spacer()
                }
                .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .card()
    }
}

/// Řádek „popisek – hodnota“. Prázdné hodnoty se nezobrazí, pokud `hideWhenEmpty`.
struct DetailRow: View {
    let label: String
    let value: String?
    var valueColor: Color = .primary
    var bold = false
    var hideWhenEmpty = false

    var body: some View {
        if !(hideWhenEmpty && (value ?? "").isEmpty) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value ?? "-")
                    .font(.subheadline)
                    .fontWeight(bold ? .bold : .regular)
                    .foregroundStyle(valueColor)
                    .multilineTextAlignment(.trailing)
            }
        }
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

struct InvoiceItemsCard: View {
    let invoice: Invoice

    var body: some View {
        let notice = invoice.printNotice ?? ""
        let items = invoice.items ?? []
        if !notice.isEmpty || !items.isEmpty {
            DetailCard(title: "Poznámka a položky", systemImage: "bubble.right") {
                if !notice.isEmpty {
                    Text(notice)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let quantity = item.quantity, let unit = item.unitName {
                                Text("\(quantity) \(unit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let price = item.totalPrice {
                            Text(FormatterHelper.formatPrice(price, currency: invoice.currency?.symbol))
                                .font(.subheadline)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}

/// Úvodní karta detailu: stav, protistrana a hlavní částka.
struct InvoiceHeroCard: View {
    let invoice: Invoice
    let counterparty: String?
    /// Zda ukázat základ bez DPH (jen u plátce).
    let showBasePrice: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text(invoice.actuarialNumber)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                StatusBadge(invoice: invoice)
                    .padding(2)
                    .background(.white, in: Capsule())
                    .id(invoice.statusId)
                    .transition(.scale.combined(with: .opacity))
            }

            Text(counterparty ?? "—")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Částka k úhradě")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                AnimatedAmount(value: invoice.endPrice, currency: invoice.currency?.symbol)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if showBasePrice {
                    Text("bez DPH \(FormatterHelper.formatPrice(invoice.basePrice, currency: invoice.currency?.symbol))")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.top, Theme.Spacing.xs)

            if let due = invoice.dueDateAt {
                Label("Splatnost \(due)", systemImage: "calendar")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(invoice.isOverdue ? Color(hex: "#FFB4AB") : .white.opacity(0.85))
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Theme.brandGradient
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 220)
                    .offset(x: 130, y: -90)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous)),
        )
        .shadow(color: Theme.brand.opacity(0.3), radius: 18, y: 10)
        .animation(Motion.bouncy, value: invoice.statusId)
        .accessibilityElement(children: .combine)
    }
}

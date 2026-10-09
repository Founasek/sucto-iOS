//
//  OverviewExtraCards.swift
//  SuctoApp
//

import SwiftUI

/// Stáří prošlých faktur: pro každou měnu tabulka košů (1–30, 31–60, 61–90, přes 90 dní) zvlášť pro vydané a přijaté.
struct OverviewAgingCard: View {
    let aging: AgingSummary

    var body: some View {
        DetailCard(title: "Po splatnosti podle stáří", systemImage: "hourglass") {
            ForEach(aging.rows) { row in
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    if aging.rows.count > 1 {
                        Text(row.currency).font(.subheadline.weight(.bold))
                    }
                    header
                    ForEach(Array(AgingSummary.Bucket.all.enumerated()), id: \.element.id) { index, bucket in
                        line(title: bucket.title, issued: row.issued[index], received: row.received[index], currency: row.currency)
                    }
                    Divider()
                    line(title: "Celkem", issued: row.issuedTotal, received: row.receivedTotal, currency: row.currency, bold: true)
                }
                .accessibilityElement(children: .contain)
            }
            Text("Součet zbývajících částek nezaplacených faktur po splatnosti. Měny se nepřepočítávají.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appear(delay: 0.28)
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("Vydané").font(.caption.weight(.semibold)).foregroundStyle(OverviewStyle.revenueColor)
                .frame(minWidth: 56, idealWidth: 110, maxWidth: 110, alignment: .trailing)
            Text("Přijaté").font(.caption.weight(.semibold)).foregroundStyle(OverviewStyle.costColor)
                .frame(minWidth: 56, idealWidth: 110, maxWidth: 110, alignment: .trailing)
        }
        .accessibilityHidden(true)
    }

    private func line(title: String, issued: AgingSummary.Amounts, received: AgingSummary.Amounts, currency: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(bold ? .bold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: Theme.Spacing.s)
            amount(issued, currency: currency, bold: bold)
            amount(received, currency: currency, bold: bold)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): vydané \(summary(issued, currency)), přijaté \(summary(received, currency))")
    }

    private func amount(_ value: AgingSummary.Amounts, currency: String, bold: Bool) -> some View {
        Text(value.hasInvoices ? FormatterHelper.formatWhole(value.amount, currency: currency) : "–")
            .font(.subheadline.weight(bold ? .bold : .regular))
            .monospacedDigit()
            .foregroundStyle(value.hasInvoices ? .primary : .tertiary)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
            .frame(minWidth: 56, idealWidth: 110, maxWidth: 110, alignment: .trailing)
    }

    private func summary(_ value: AgingSummary.Amounts, _ currency: String) -> String {
        value.hasInvoices ? "\(DueFormat.invoices(value.invoiceCount)), \(FormatterHelper.formatWhole(value.amount, currency: currency))" : "nic"
    }
}

/// Největší odběratelé (z vydaných faktur) a dodavatelé (z přijatých) roku jako dvě stránky slideru; uvnitř po měnách.
struct OverviewTopPartiesCard: View {
    let sections: [CurrencySection]
    let labels: OverviewLabels

    private enum Side: String, CaseIterable, Identifiable {
        case customers = "Odběratelé"
        case suppliers = "Dodavatelé"

        var id: String { rawValue }
        var color: Color { self == .customers ? OverviewStyle.revenueColor : OverviewStyle.costColor }
        var systemImage: String { self == .customers ? "arrow.down.left.circle" : "arrow.up.right.circle" }
    }

    @State private var scrolledID: String?

    private func parties(_ side: Side, in section: CurrencySection) -> [RankedParty] {
        side == .customers ? section.topCustomers : section.topSuppliers
    }

    /// Strany, které mají aspoň jednoho partnera v nějaké měně.
    private var visibleSides: [Side] {
        Side.allCases.filter { side in sections.contains { !parties(side, in: $0).isEmpty } }
    }

    private var currentSide: String { scrolledID ?? visibleSides.first?.id ?? "" }

    var body: some View {
        if !visibleSides.isEmpty {
            DetailCard(title: "Největší partneři", systemImage: "person.2") {
                if visibleSides.count == 1, let side = visibleSides.first {
                    page(for: side)
                } else {
                    sideChips
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: Theme.Spacing.l) {
                            ForEach(visibleSides) { side in
                                page(for: side)
                                    .containerRelativeFrame(.horizontal)
                                    .id(side.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $scrolledID)
                    .sensoryFeedback(.selection, trigger: scrolledID)
                }
                Text("Podle základu faktur bez DPH za zvolený rok.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .appear(delay: 0.3)
        }
    }

    private var sideChips: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(visibleSides) { side in
                let isSelected = currentSide == side.id
                Button {
                    withAnimation(Motion.standard) { scrolledID = side.id }
                } label: {
                    Label(side.rawValue, systemImage: side.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .background(
                            isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.surface),
                            in: Capsule(),
                        )
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(isSelected ? 0 : 0.08), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }

    /// Jedna strana: pro každou měnu žebříček pěti největších.
    private func page(for side: Side) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            ForEach(sections) { section in
                let list = parties(side, in: section)
                if !list.isEmpty {
                    if sections.count > 1 {
                        Text(section.currency).font(.subheadline.weight(.bold))
                    }
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, party in
                        HStack {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 22, alignment: .leading)
                            Text(party.name).font(.subheadline).lineLimit(1)
                            Spacer()
                            Text(FormatterHelper.formatWhole(party.amount, currency: section.currency))
                                .moneyStyle(.subheadline)
                                .foregroundStyle(side.color)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
    }
}

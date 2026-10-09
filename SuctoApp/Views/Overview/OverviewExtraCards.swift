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

/// Největší odběratelé (z vydaných) a dodavatelé (z přijatých faktur) roku, po měnách.
struct OverviewTopPartiesCard: View {
    let sections: [CurrencySection]
    let labels: OverviewLabels

    private var visible: [CurrencySection] {
        sections.filter { !$0.topCustomers.isEmpty || !$0.topSuppliers.isEmpty }
    }

    var body: some View {
        if !visible.isEmpty {
            DetailCard(title: "Největší odběratelé a dodavatelé", systemImage: "person.2") {
                ForEach(visible) { section in
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        if sections.count > 1 {
                            Text(section.currency).font(.subheadline.weight(.bold))
                        }
                        group("Odběratelé", parties: section.topCustomers, currency: section.currency, color: OverviewStyle.revenueColor)
                        group("Dodavatelé", parties: section.topSuppliers, currency: section.currency, color: OverviewStyle.costColor)
                    }
                }
                Text("Podle základu faktur bez DPH za zvolený rok.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .appear(delay: 0.3)
        }
    }

    @ViewBuilder
    private func group(_ title: String, parties: [RankedParty], currency: String, color: Color) -> some View {
        if !parties.isEmpty {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .tracking(0.6)
            ForEach(Array(parties.enumerated()), id: \.element.id) { index, party in
                HStack {
                    Text("\(index + 1).").font(.subheadline).foregroundStyle(.secondary).frame(width: 22, alignment: .leading)
                    Text(party.name).font(.subheadline).lineLimit(1)
                    Spacer()
                    Text(FormatterHelper.formatWhole(party.amount, currency: currency))
                        .moneyStyle(.subheadline)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

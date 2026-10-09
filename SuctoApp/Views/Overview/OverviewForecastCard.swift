//
//  OverviewForecastCard.swift
//  SuctoApp
//

import Charts
import SwiftUI

/// Prognóza splatností na 30 dní: sloupce po týdnech (příjmy × platby), součty a nejbližší splatnosti.
struct OverviewForecastCard: View {
    let forecast: ForecastSummary
    @State private var scrolledID: String?

    private static let incomingTitle = "Příjmy"
    private static let outgoingTitle = "Platby"

    var body: some View {
        DetailCard(title: "Splatnosti na 30 dní", systemImage: "calendar.badge.clock") {
            // Nejdřív konkrétní nejbližší splatnosti, pak přehled po týdnech (graf a součty po měnách).
            if !forecast.upcoming.isEmpty {
                Text("NEJBLIŽŠÍ SPLATNOSTI")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                ForEach(forecast.upcoming, id: \.self) { item in
                    upcomingRow(item)
                }
                Divider()
            }

            currencyPages

            Text("Příjmy jsou vydané faktury, platby přijaté. Částky jsou zbývající k úhradě, měny se nepřepočítávají.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appear(delay: 0.26)
    }

    // MARK: - Měny jako slider

    /// Při více měnách jsou stránky (graf + součty) v posuvném slideru a nahoře chipy s měnou; u jedné měny bez slideru.
    @ViewBuilder
    private var currencyPages: some View {
        if forecast.rows.count == 1, let row = forecast.rows.first {
            page(for: row)
        } else {
            VStack(spacing: Theme.Spacing.s) {
                currencyChips
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: Theme.Spacing.l) {
                        ForEach(forecast.rows) { row in
                            page(for: row)
                                .containerRelativeFrame(.horizontal)
                                .id(row.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledID)
                .sensoryFeedback(.selection, trigger: scrolledID)
            }
        }
    }

    private func page(for row: ForecastSummary.Row) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            chart(for: row)
            totals(for: row)
        }
        // Vzduch nahoře: slider ořezává obsah a horní popisek osy Y by jinak byl uříznutý.
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
    }

    private var currentCurrency: String { scrolledID ?? forecast.rows.first?.id ?? "" }

    private var currencyChips: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(forecast.rows) { row in
                let isSelected = currentCurrency == row.id
                Button {
                    withAnimation(Motion.standard) { scrolledID = row.id }
                } label: {
                    Text(row.currency)
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
                .accessibilityLabel("Splatnosti v \(row.currency)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Graf

    /// Popisek týdne = jeho první den („9. 10.“), ať se na ose nepřekrývají dlouhé rozsahy.
    private func label(for week: ForecastSummary.Week) -> String {
        let calendar = Calendar.current
        return "\(calendar.component(.day, from: week.start)). \(calendar.component(.month, from: week.start))."
    }

    private func chart(for row: ForecastSummary.Row) -> some View {
        Chart {
            ForEach(row.weeks) { week in
                let name = label(for: week)
                BarMark(x: .value("Týden", name), y: .value("Částka", week.incoming))
                    .foregroundStyle(by: .value("Typ", Self.incomingTitle))
                    .position(by: .value("Typ", Self.incomingTitle))
                    .cornerRadius(3)
                BarMark(x: .value("Týden", name), y: .value("Částka", week.outgoing))
                    .foregroundStyle(by: .value("Typ", Self.outgoingTitle))
                    .position(by: .value("Typ", Self.outgoingTitle))
                    .cornerRadius(3)
            }
        }
        .chartForegroundStyleScale([Self.incomingTitle: OverviewStyle.revenueColor, Self.outgoingTitle: OverviewStyle.costColor])
        .chartLegend(position: .bottom, alignment: .leading)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text(OverviewStyle.compact(number)).font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel().font(.caption2)
            }
        }
        .frame(height: 170)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Graf splatností na 30 dní po týdnech, popisky jsou první dny týdnů")
        .accessibilityValue("Příjmy \(FormatterHelper.formatWhole(row.incomingTotal, currency: row.currency)), platby \(FormatterHelper.formatWhole(row.outgoingTotal, currency: row.currency))")
    }

    private func totals(for row: ForecastSummary.Row) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            totalLine("Očekávané příjmy", value: row.incomingTotal, currency: row.currency, color: OverviewStyle.revenueColor)
            totalLine("Platby dodavatelům", value: row.outgoingTotal, currency: row.currency, color: OverviewStyle.costColor)
            Divider()
            totalLine("Saldo", value: row.net, currency: row.currency, color: row.net >= 0 ? .accentColor : .red, bold: true)
        }
    }

    private func totalLine(_ title: String, value: Double, currency: String, color: Color, bold: Bool = false) -> some View {
        HStack {
            Text(title).font(.subheadline.weight(bold ? .bold : .regular))
            Spacer()
            Text(FormatterHelper.formatWhole(value, currency: currency))
                .moneyStyle(.subheadline)
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Nejbližší splatnosti

    /// Řádek je tlačítko: otevře detail faktury.
    private func upcomingRow(_ item: DueItem) -> some View {
        NavigationLink(value: InvoiceRoute(id: item.id, isIncoming: item.isIncoming)) {
            upcomingContent(item)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Otevře detail faktury")
    }

    private func upcomingContent(_ item: DueItem) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: item.isIncoming ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                .foregroundStyle(item.isIncoming ? OverviewStyle.costColor : OverviewStyle.revenueColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.counterparty ?? item.number)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(item.dueDate.formatted(.dateTime.weekday(.abbreviated).day().month().locale(Locale(identifier: "cs_CZ"))))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: Theme.Spacing.s)
            Text(FormatterHelper.formatWhole(item.amount, currency: item.currency))
                .moneyStyle(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(item.isIncoming ? "Platba" : "Příjem") \(item.counterparty ?? item.number), "
                + "\(item.dueDate.formatted(.dateTime.day().month().locale(Locale(identifier: "cs_CZ")))), "
                + FormatterHelper.formatWhole(item.amount, currency: item.currency),
        )
    }
}

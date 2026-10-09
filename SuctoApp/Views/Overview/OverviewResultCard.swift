//
//  OverviewResultCard.swift
//  SuctoApp
//

import SwiftUI

/// Hlavní karta: výsledek roku. Při více měnách je v ní řádek pro každou měnu (vše na první obrazovce).
struct OverviewResultCard: View {
    let sections: [CurrencySection]
    let year: Int
    let labels: OverviewLabels
    /// Vysvětlení zdroje dat v bublině; ikona „i“ se v rohu karty ukáže jen když je zadané.
    var info: AnyView?

    @State private var showInfo = false

    private var isSingle: Bool { sections.count == 1 }
    private var singlePositive: Bool { (sections.first?.result ?? 0) >= 0 }
    private var showsRed: Bool { isSingle && !singlePositive }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(labels.result) \(String(year))")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                if let hint = labels.resultHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            ForEach(sections) { section in
                row(section)
                if section.id != sections.last?.id {
                    Divider().overlay(.white.opacity(0.25))
                }
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                showsRed
                    ? LinearGradient(colors: [Color(hex: "#C0392B"), Color(hex: "#8E2A20")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : Theme.brandGradient
                Circle().fill(.white.opacity(0.08)).frame(width: 200).offset(x: 130, y: -80)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous)),
        )
        .overlay(alignment: .topTrailing) { infoButton }
        .shadow(color: (showsRed ? Color.red : Theme.brand).opacity(0.3), radius: 18, y: 10)
        .appear()
    }

    @ViewBuilder
    private var infoButton: some View {
        if let info {
            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Informace o zdroji přehledu")
            .popover(isPresented: $showInfo, arrowEdge: .top) { info }
        }
    }

    /// „Oproti 2025: Vydané +12 %, Přijaté −5 %“ (část, kterou nejde spočítat, se vynechá).
    private func comparison(section: CurrencySection, previous: YearTotals) -> String {
        func part(_ title: String, _ previous: Double, _ current: Double) -> String? {
            percentChange(from: previous, to: current).map { "\(title) \(OverviewComparison.format($0))" }
        }
        let parts = [part(labels.revenue, previous.revenue, section.revenue), part(labels.cost, previous.cost, section.cost)].compactMap(\.self)
        return parts.isEmpty ? "Oproti \(year - 1): minulý rok bez srovnatelných dat" : "Oproti \(year - 1): " + parts.joined(separator: ", ")
    }

    private func row(_ section: CurrencySection) -> some View {
        let positive = section.result >= 0
        return VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(FormatterHelper.formatWhole(section.result, currency: section.currency))
                .font(isSingle ? .largeTitle.weight(.bold) : .title.weight(.bold))
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(positive || isSingle ? .white : Color(hex: "#FFB4AB"))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText(value: section.result))
                .animation(Motion.gentle, value: section.result)
            Label(positive ? labels.positive : labels.negative, systemImage: positive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            if let previous = section.previous {
                Text(comparison(section: section, previous: previous))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
                    .minimumScaleFactor(0.8)
            }
            if !isSingle {
                Text("\(labels.revenue) \(FormatterHelper.formatWhole(section.revenue, currency: section.currency)) · \(labels.cost) \(FormatterHelper.formatWhole(section.cost, currency: section.currency))")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.75))
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

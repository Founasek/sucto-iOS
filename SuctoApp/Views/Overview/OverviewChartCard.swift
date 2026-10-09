//
//  OverviewChartCard.swift
//  SuctoApp
//

import Charts
import SwiftUI

/// Graf výnosů a nákladů po měsících pro jednu měnu.
struct OverviewChartCard: View {
    let section: CurrencySection
    let labels: OverviewLabels
    /// U více měn je kód měny v názvu karty.
    let showsCurrency: Bool

    @State private var selectedMonth: String?
    @State private var barsVisible = false

    private var selectedFigures: MonthlyFigures? {
        guard let selectedMonth, let index = OverviewStyle.shortMonths.firstIndex(of: selectedMonth) else { return nil }
        return section.months.first { $0.month == index + 1 }
    }

    var body: some View {
        let title = "\(labels.revenue) a \(labels.cost.lowercased()) po měsících"
        DetailCard(title: showsCurrency ? "\(title) (\(section.currency))" : title, systemImage: "chart.bar.xaxis") {
            Chart {
                ForEach(section.months) { figures in
                    let label = OverviewStyle.shortMonths[figures.month - 1]
                    BarMark(x: .value("Měsíc", label), y: .value("Částka", barsVisible ? figures.revenue : 0))
                        .foregroundStyle(by: .value("Typ", labels.revenue))
                        .position(by: .value("Typ", labels.revenue))
                        .cornerRadius(4)
                    BarMark(x: .value("Měsíc", label), y: .value("Částka", barsVisible ? figures.cost : 0))
                        .foregroundStyle(by: .value("Typ", labels.cost))
                        .position(by: .value("Typ", labels.cost))
                        .cornerRadius(4)
                }

                if let selected = selectedFigures {
                    RuleMark(x: .value("Měsíc", OverviewStyle.shortMonths[selected.month - 1]))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                            tooltip(for: selected)
                        }
                }
            }
            .chartForegroundStyleScale([labels.revenue: OverviewStyle.revenueColor, labels.cost: OverviewStyle.costColor])
            // Výběr měsíce klepnutím (ne tažením), aby graf nebránil posunu slideru mezi měnami.
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture { location in
                            guard let plot = proxy.plotFrame else { return }
                            let x = location.x - geometry[plot].origin.x
                            let tapped: String? = proxy.value(atX: x)
                            selectedMonth = tapped == selectedMonth ? nil : tapped
                        }
                }
            }
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
            .frame(height: 220)
            .animation(Motion.gentle, value: barsVisible)
            .sensoryFeedback(.selection, trigger: selectedMonth)
            .accessibilityLabel("Graf \(labels.revenue.lowercased()) a \(labels.cost.lowercased()) po měsících v \(section.currency)")
            .accessibilityValue(monthsSummary)
            .onAppear { reveal() }
            .onChange(of: section.months) { reveal() }
        }
        .appear(delay: 0.16)
    }

    /// Hodnoty po měsících jako text pro čtečku obrazovky (graf sám čísla nepředá).
    private var monthsSummary: String {
        section.months
            .filter { $0.revenue != 0 || $0.cost != 0 }
            .map { figures in
                let revenue = FormatterHelper.formatWhole(figures.revenue, currency: section.currency)
                let cost = FormatterHelper.formatWhole(figures.cost, currency: section.currency)
                let result = FormatterHelper.formatWhole(figures.result, currency: section.currency)
                return "\(OverviewStyle.longMonths[figures.month - 1]): \(labels.revenue) \(revenue), \(labels.cost) \(cost), výsledek \(result)"
            }
            .joined(separator: ". ")
    }

    /// Sloupce „vyrostou“ z nuly; voláno i při návratu na záložku, kdy se data nemění.
    private func reveal() {
        barsVisible = false
        withAnimation(Motion.gentle.delay(0.1)) { barsVisible = true }
    }

    private func tooltip(for figures: MonthlyFigures) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(OverviewStyle.longMonths[figures.month - 1]).font(.caption.weight(.bold))
            Text("\(labels.revenue) \(FormatterHelper.formatWhole(figures.revenue, currency: section.currency))")
                .foregroundStyle(OverviewStyle.revenueColor)
            Text("\(labels.cost) \(FormatterHelper.formatWhole(figures.cost, currency: section.currency))")
                .foregroundStyle(OverviewStyle.costColor)
            Text("Výsledek \(FormatterHelper.formatWhole(figures.result, currency: section.currency))")
                .foregroundStyle(figures.result >= 0 ? Color.accentColor : Color.red)
        }
        .font(.caption2.weight(.semibold))
        .monospacedDigit()
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }
}

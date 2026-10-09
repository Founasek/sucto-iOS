//
//  OverviewComponents.swift
//  SuctoApp
//

import Charts
import SwiftUI

/// Společné popisky a barvy přehledu.
enum OverviewStyle {
    static let shortMonths = ["led", "úno", "bře", "dub", "kvě", "čvn", "čvc", "srp", "zář", "říj", "lis", "pro"]
    static let longMonths = ["Leden", "Únor", "Březen", "Duben", "Květen", "Červen", "Červenec", "Srpen", "Září", "Říjen", "Listopad", "Prosinec"]
    static let revenueColor = Color(hex: "#2FAE5D")
    static let costColor = Color(hex: "#F28C28")

    static func compact(_ value: Double) -> String {
        let magnitude = abs(value)
        let sign = value < 0 ? "-" : ""
        switch magnitude {
        case 1_000_000...: return "\(sign)\(String(format: "%.1f", magnitude / 1_000_000).replacingOccurrences(of: ".", with: ",")) mil."
        case 10000...: return "\(sign)\(Int(magnitude / 1000)) tis."
        case 1000...: return "\(sign)\(String(format: "%.1f", magnitude / 1000).replacingOccurrences(of: ".", with: ",")) tis."
        default: return "\(Int(value))"
        }
    }
}

/// Popisky podle zdroje dat (účetní deník × přehled z faktur).
struct OverviewLabels {
    let isAccounting: Bool

    var revenue: String { isAccounting ? "Výnosy" : "Vydané" }
    var cost: String { isAccounting ? "Náklady" : "Přijaté" }
    var result: String { isAccounting ? "Hospodářský výsledek" : "Saldo faktur" }
    /// Vysvětlení výpočtu pod nadpisem karty (jen u přehledu z faktur).
    var resultHint: String? { isAccounting ? nil : "vydané − přijaté faktury, bez DPH" }
    var positive: String { isAccounting ? "Zisk" : "Převaha vydaných" }
    var negative: String { isAccounting ? "Ztráta" : "Převaha přijatých" }
}

enum OverviewComparison {
    /// „+12 %“ / „−5 %“ (typografické mínus), bez desetinných míst nad 10 %.
    static func format(_ value: Double) -> String {
        let magnitude = abs(value)
        let text = magnitude >= 10 ? String(format: "%.0f", magnitude) : String(format: "%.1f", magnitude).replacingOccurrences(of: ".", with: ",")
        return (value < 0 ? "\u{2212}" : "+") + text + " %"
    }
}

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

/// Grafy jednotlivých měn jako posuvný „slider“; chipy s měnou nahoře zároveň ukazují, která je vidět, a po klepnutí na ni přeskočí.
/// U jediné měny je to obyčejná karta bez chipů.
struct OverviewChartCarousel: View {
    let sections: [CurrencySection]
    let labels: OverviewLabels

    @State private var scrolledID: String?

    var body: some View {
        if sections.count == 1, let section = sections.first {
            OverviewChartCard(section: section, labels: labels, showsCurrency: false)
        } else {
            VStack(spacing: Theme.Spacing.s) {
                chips
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: Theme.Spacing.m) {
                        ForEach(sections) { section in
                            OverviewChartCard(section: section, labels: labels, showsCurrency: true)
                                .containerRelativeFrame(.horizontal)
                                .id(section.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledID)
                .scrollClipDisabled()
            }
            .sensoryFeedback(.selection, trigger: scrolledID)
        }
    }

    private var current: String { scrolledID ?? sections.first?.id ?? "" }

    private var chips: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(sections) { section in
                let isSelected = current == section.id
                Button {
                    withAnimation(Motion.standard) { scrolledID = section.id }
                } label: {
                    Text(section.currency)
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
                .accessibilityLabel("Graf \(section.currency)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }
}

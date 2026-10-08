//
//  OverviewView.swift
//  SuctoApp
//

import Charts
import SwiftUI

/// Přehled hospodaření: výnosy, náklady a výsledek za rok, graf po měsících.
struct OverviewView: View {
    @EnvironmentObject var viewModel: OverviewViewModel
    @State private var selectedMonth: String?
    @State private var barsVisible = false

    private static let shortMonths = ["led", "úno", "bře", "dub", "kvě", "čvn", "čvc", "srp", "zář", "říj", "lis", "pro"]
    private static let longMonths = ["Leden", "Únor", "Březen", "Duben", "Květen", "Červen", "Červenec", "Srpen", "Září", "Říjen", "Listopad", "Prosinec"]

    private let revenueColor = Color(hex: "#2FAE5D")
    private let costColor = Color(hex: "#F28C28")

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                if let notice = viewModel.notice {
                    noticeCard(notice)
                }

                yearPicker

                if viewModel.source == .invoices, !viewModel.isLoading || !viewModel.months.isEmpty {
                    fallbackNote
                }

                if let error = viewModel.errorMessage, viewModel.months.isEmpty {
                    ErrorStateView(message: error) {
                        Task { await viewModel.load() }
                    }
                } else if viewModel.isLoading, viewModel.months.isEmpty {
                    skeleton
                } else if viewModel.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar.xaxis",
                        message: viewModel.source == .accounting
                            ? "Za rok \(viewModel.year) nejsou v účetním deníku žádné údaje."
                            : "Za rok \(viewModel.year) nejsou vystavené ani přijaté faktury.",
                    )
                } else {
                    resultCard
                    HStack(spacing: Theme.Spacing.m) {
                        figureCard(title: revenueName, value: viewModel.yearRevenue, icon: "arrow.down.left", color: revenueColor)
                        figureCard(title: costName, value: viewModel.yearCost, icon: "arrow.up.right", color: costColor)
                    }
                    chartCard
                    monthsCard
                }
            }
            .padding(Theme.Spacing.l)
        }
        .background(Theme.background)
        .refreshable { await viewModel.load(retryAccounting: true) }
        .task {
            if viewModel.months.isEmpty { await viewModel.load() }
        }
        .task { await viewModel.loadNotice() }
        .onChange(of: viewModel.months) { revealBars() }
    }

    /// Sloupce graf „vyroste“ z nuly. Voláno i při návratu na záložku – data se tehdy nemění,
    /// takže by `onChange` nezafungoval a sloupce by zůstaly nulové (graf by vypadal prázdný).
    private func revealBars() {
        barsVisible = false
        withAnimation(Motion.gentle.delay(0.1)) { barsVisible = true }
    }

    // MARK: - Části

    // MARK: - Popisky podle zdroje dat

    private var isAccounting: Bool { viewModel.source == .accounting }
    private var revenueName: String { isAccounting ? "Výnosy" : "Vydané" }
    private var costName: String { isAccounting ? "Náklady" : "Přijaté" }
    private var resultName: String { isAccounting ? "Hospodářský výsledek" : "Vydané minus přijaté faktury" }
    private var positiveLabel: String { isAccounting ? "Zisk" : "Převaha vydaných" }
    private var negativeLabel: String { isAccounting ? "Ztráta" : "Převaha přijatých" }

    /// Upozornění, že přehled nevychází z účetního deníku.
    private var fallbackNote: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: "info.circle.fill").foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text("Přehled z faktur")
                    .font(.subheadline.weight(.semibold))
                Text("Server pro váš účet nepouští účetní deník (403), proto jsou součty z vystavených a přijatých faktur bez DPH – nejde o účetní výnosy a náklady.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if viewModel.skippedForeignCount > 0 {
                    Text("Faktury v jiné měně než \(viewModel.currency) (\(viewModel.skippedForeignCount)) nejsou započtené.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.m)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    private var yearPicker: some View {
        HStack {
            Text(isAccounting ? "Hospodaření" : "Fakturace")
                .font(.title2.weight(.bold))
            Spacer()
            Menu {
                Picker("Rok", selection: $viewModel.year) {
                    ForEach(viewModel.availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            } label: {
                Label(String(viewModel.year), systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.surface, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
            }
            .accessibilityLabel("Rok \(viewModel.year)")
        }
    }

    private var resultCard: some View {
        let positive = viewModel.yearResult >= 0
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("\(resultName) \(String(viewModel.year))")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))
            Text(FormatterHelper.formatWhole(viewModel.yearResult, currency: viewModel.currency))
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText(value: viewModel.yearResult))
                .animation(Motion.gentle, value: viewModel.yearResult)
            Label(positive ? positiveLabel : negativeLabel, systemImage: positive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                positive ? Theme.brandGradient : LinearGradient(colors: [Color(hex: "#C0392B"), Color(hex: "#8E2A20")], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(.white.opacity(0.08)).frame(width: 200).offset(x: 130, y: -80)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous)),
        )
        .shadow(color: (positive ? Theme.brand : .red).opacity(0.3), radius: 18, y: 10)
        .appear()
        .accessibilityElement(children: .combine)
    }

    private func figureCard(title: String, value: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Image(systemName: icon)
                .font(.footnote.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.15), in: Circle())
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(FormatterHelper.formatWhole(value, currency: viewModel.currency))
                .moneyStyle(.headline)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText(value: value))
                .animation(Motion.gentle, value: value)
        }
        .card()
        .appear(delay: 0.08)
        .accessibilityElement(children: .combine)
    }

    private var chartCard: some View {
        DetailCard(title: "\(revenueName) a \(costName.lowercased()) po měsících", systemImage: "chart.bar.xaxis") {
            Chart {
                ForEach(viewModel.months) { figures in
                    let label = Self.shortMonths[figures.month - 1]
                    BarMark(x: .value("Měsíc", label), y: .value("Částka", barsVisible ? figures.revenue : 0))
                        .foregroundStyle(by: .value("Typ", revenueName))
                        .position(by: .value("Typ", revenueName))
                        .cornerRadius(4)
                    BarMark(x: .value("Měsíc", label), y: .value("Částka", barsVisible ? figures.cost : 0))
                        .foregroundStyle(by: .value("Typ", costName))
                        .position(by: .value("Typ", costName))
                        .cornerRadius(4)
                }

                if let selected = selectedFigures {
                    RuleMark(x: .value("Měsíc", Self.shortMonths[selected.month - 1]))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                            tooltip(for: selected)
                        }
                }
            }
            .chartForegroundStyleScale([revenueName: revenueColor, costName: costColor])
            .chartXSelection(value: $selectedMonth)
            .chartLegend(position: .bottom, alignment: .leading)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(Self.compact(number)).font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 240)
            .animation(Motion.gentle, value: barsVisible)
            .sensoryFeedback(.selection, trigger: selectedMonth)
            .accessibilityLabel("Graf výnosů a nákladů po měsících")
            .accessibilityHint("Hodnoty jednotlivých měsíců jsou uvedeny pod grafem.")
            .onAppear { revealBars() }
        }
        .appear(delay: 0.16)
    }

    private var selectedFigures: MonthlyFigures? {
        guard let selectedMonth, let index = Self.shortMonths.firstIndex(of: selectedMonth) else { return nil }
        return viewModel.months.first { $0.month == index + 1 }
    }

    private func tooltip(for figures: MonthlyFigures) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Self.longMonths[figures.month - 1]).font(.caption.weight(.bold))
            Text("\(revenueName) \(FormatterHelper.formatWhole(figures.revenue, currency: viewModel.currency))")
                .foregroundStyle(revenueColor)
            Text("\(costName) \(FormatterHelper.formatWhole(figures.cost, currency: viewModel.currency))")
                .foregroundStyle(costColor)
        }
        .font(.caption2.weight(.semibold))
        .monospacedDigit()
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }
}

private extension OverviewView {
    private var monthsCard: some View {
        let active = viewModel.months.filter { $0.revenue != 0 || $0.cost != 0 }
        return DetailCard(title: "Po měsících", systemImage: "list.bullet") {
            ForEach(active.reversed()) { figures in
                HStack {
                    Text(Self.longMonths[figures.month - 1])
                        .font(.subheadline)
                    Spacer()
                    Text(FormatterHelper.formatWhole(figures.result, currency: viewModel.currency))
                        .moneyStyle(.subheadline)
                        .foregroundStyle(figures.result >= 0 ? Color.accentColor : Color.red)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(Self.longMonths[figures.month - 1]): \(revenueName) \(FormatterHelper.formatWhole(figures.revenue, currency: viewModel.currency)), "
                        + "\(costName) \(FormatterHelper.formatWhole(figures.cost, currency: viewModel.currency)), "
                        + "výsledek \(FormatterHelper.formatWhole(figures.result, currency: viewModel.currency))",
                )
            }
        }
        .appear(delay: 0.24)
    }

    private var skeleton: some View {
        VStack(spacing: Theme.Spacing.l) {
            RoundedRectangle(cornerRadius: 28).frame(height: 130)
            HStack(spacing: Theme.Spacing.m) {
                RoundedRectangle(cornerRadius: 20).frame(height: 100)
                RoundedRectangle(cornerRadius: 20).frame(height: 100)
            }
            RoundedRectangle(cornerRadius: 20).frame(height: 280)
        }
        .foregroundStyle(Color.primary.opacity(0.08))
        .shimmer()
        .accessibilityLabel("Načítám přehled")
    }

    private static func compact(_ value: Double) -> String {
        let magnitude = abs(value)
        let sign = value < 0 ? "-" : ""
        switch magnitude {
        case 1_000_000...: return "\(sign)\(String(format: "%.1f", magnitude / 1_000_000).replacingOccurrences(of: ".", with: ",")) mil."
        case 1000...: return "\(sign)\(Int(magnitude / 1000)) tis."
        default: return "\(Int(value))"
        }
    }
}

private extension OverviewView {
    /// Zpráva ze sÚčta s možností ji zavřít.
    func noticeCard(_ notice: SystemNotice) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: "megaphone.fill").foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(notice.title).font(.subheadline.weight(.semibold))
                if let description = notice.description, !description.isEmpty {
                    Text(description).font(.footnote).foregroundStyle(.secondary)
                }
                if let date = notice.createdAt {
                    Text(date).font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 0)
            Button {
                viewModel.dismissNotice()
            } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Zavřít zprávu")
        }
        .padding(Theme.Spacing.m)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

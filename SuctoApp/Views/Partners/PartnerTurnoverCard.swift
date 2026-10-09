//
//  PartnerTurnoverCard.swift
//  SuctoApp
//

import Charts
import SwiftUI

/// Obrat s partnerem po měsících, výběr roku. Faktury se v grafu porovnávají vedle sebe (vydané × přijaté);
/// pokladní doklady jsou hotovostní platby, proto se do sloupců nesčítají a jsou jen v součtech pod grafem.
struct PartnerTurnoverCard: View {
    @ObservedObject var viewModel: PartnerDetailViewModel

    private static let months = ["led", "úno", "bře", "dub", "kvě", "čvn", "čvc", "srp", "zář", "říj", "lis", "pro"]
    private let issuedColor = Color(hex: "#2FAE5D")
    private let receivedColor = Color(hex: "#F28C28")

    private var visibleSeries: [PartnerSeries] { viewModel.series.filter { $0.total != 0 } }

    private func isInvoice(_ series: PartnerSeries) -> Bool {
        series.name.range(of: "faktur", options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    /// Do grafu jen faktury; když žádné nejsou, aspoň to, co v roce je.
    private var chartSeries: [PartnerSeries] {
        let invoices = visibleSeries.filter(isInvoice)
        return invoices.isEmpty ? visibleSeries : invoices
    }

    /// Vydané / příjmové = zelená, přijaté / výdajové = oranžová.
    private func color(for name: String) -> Color {
        let folded = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return folded.contains("vydane") || folded.contains("prijmove") ? issuedColor : receivedColor
    }

    var body: some View {
        DetailCard(title: "Obrat po měsících", systemImage: "chart.bar.xaxis") {
            yearPicker

            if visibleSeries.isEmpty {
                Text("V roce \(String(viewModel.year ?? 0)) zatím nejsou žádné faktury ani doklady.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(chartSeries) { series in
                        ForEach(Array(series.data.prefix(12).enumerated()), id: \.offset) { index, value in
                            BarMark(x: .value("Měsíc", Self.months[index]), y: .value("Částka", value))
                                .foregroundStyle(by: .value("Typ", series.name))
                                .position(by: .value("Typ", series.name))
                                .cornerRadius(3)
                        }
                    }
                }
                .chartForegroundStyleScale(domain: chartSeries.map(\.name), range: chartSeries.map { color(for: $0.name) })
                .chartLegend(position: .bottom, alignment: .leading)
                .frame(height: 200)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Graf obratu po měsících")
                .accessibilityValue(summary)

                ForEach(visibleSeries) { series in
                    HStack {
                        Circle().fill(color(for: series.name)).frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text(series.name).font(.subheadline)
                        Spacer()
                        Text(FormatterHelper.formatWhole(series.total, currency: nil))
                            .moneyStyle(.subheadline)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private var yearPicker: some View {
        let selection = Binding(
            get: { viewModel.year ?? viewModel.years.last ?? 0 },
            set: { year in Task { await viewModel.select(year: year) } },
        )
        if viewModel.years.count > 4 {
            Picker("Rok", selection: selection) { yearOptions }
                .pickerStyle(.menu)
        } else if viewModel.years.count > 1 {
            Picker("Rok", selection: selection) { yearOptions }
                .pickerStyle(.segmented)
        }
    }

    private var yearOptions: some View {
        ForEach(viewModel.years, id: \.self) { year in
            Text(String(year)).tag(year)
        }
    }

    private var summary: String {
        visibleSeries
            .map { "\($0.name): \(FormatterHelper.formatWhole($0.total, currency: nil))" }
            .joined(separator: ", ")
    }
}

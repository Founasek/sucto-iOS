//
//  DueWidgetView.swift
//  SuctoWidget
//

import SwiftUI
import WidgetKit

private let brandGreen = Color(red: 0.17, green: 0.50, blue: 0.27)

struct DueWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DueEntry

    var body: some View {
        if let summary = entry.summary, let snapshot = entry.snapshot {
            switch family {
            case .systemSmall:
                SmallView(summary: summary, company: snapshot.companyName)
                    .widgetURL(summary.overdueLink(companyId: snapshot.companyId))
            case .systemMedium: MediumView(summary: summary, snapshot: snapshot)
            case .accessoryRectangular:
                RectangularView(summary: summary)
                    .widgetURL(summary.overdueLink(companyId: snapshot.companyId))
            case .accessoryInline:
                InlineView(summary: summary)
                    .widgetURL(summary.overdueLink(companyId: snapshot.companyId))
            default: SmallView(summary: summary, company: snapshot.companyName)
            }
        } else {
            NoDataView(family: family)
        }
    }
}

/// Bez dat: widget nic nenačítá sám, čeká na otevření aplikace.
private struct NoDataView: View {
    let family: WidgetFamily

    var body: some View {
        if family == .accessoryInline {
            Text("sÚčto: otevřete aplikaci")
        } else {
            VStack(spacing: 6) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(brandGreen)
                Text("Otevřete sÚčto a vyberte firmu")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Malý

private struct SmallView: View {
    let summary: DueSummary
    let company: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(company)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            SideRow(title: "Vydané", side: summary.issued, currency: summary.currency, tint: brandGreen)
            SideRow(title: "Přijaté", side: summary.received, currency: summary.currency, tint: .orange)

            Spacer(minLength: 0)
            if summary.otherCurrencyCount > 0 {
                Text("+ \(summary.otherCurrencyCount) v jiné měně")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Dva řádky: po splatnosti (červeně) a splatné do týdne.
private struct SideRow: View {
    let title: String
    let side: DueSide
    let currency: String?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
            if side.overdueCount > 0 {
                Text("\(side.overdueCount)× po splatnosti")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
                Text(DueFormat.amount(side.overdueAmount, currency: currency))
                    .font(.caption.monospacedDigit())
                    .privacySensitive()
            } else if side.soonCount > 0 {
                Text("\(side.soonCount)× do týdne")
                    .font(.footnote.weight(.semibold))
                Text(DueFormat.amount(side.soonAmount, currency: currency))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .privacySensitive()
            } else {
                Text("Vše v pořádku")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Střední

private struct MediumView: View {
    let summary: DueSummary
    let snapshot: DueSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(snapshot.companyName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(snapshot.updatedAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .top, spacing: 12) {
                linked(Column(title: "Vydané", side: summary.issued, currency: summary.currency, tint: brandGreen), isIncoming: false)
                Divider()
                linked(Column(title: "Přijaté", side: summary.received, currency: summary.currency, tint: .orange), isIncoming: true)
            }
        }
    }
}

private extension MediumView {
    /// Každý sloupec odkazuje na svůj seznam po splatnosti (bez ID firmy se odkaz nevytvoří).
    @ViewBuilder
    func linked(_ content: some View, isIncoming: Bool) -> some View {
        if let url = DueLink.url(companyId: snapshot.companyId, isIncoming: isIncoming) {
            Link(destination: url) { content }
        } else {
            content
        }
    }
}

private struct Column: View {
    let title: String
    let side: DueSide
    let currency: String?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            SideRow(title: title, side: side, currency: currency, tint: tint)
            ForEach(side.nearest.prefix(2), id: \.id) { item in
                HStack(spacing: 4) {
                    Text(item.dueDate, format: .dateTime.day().month())
                        .foregroundStyle(item.dueDate < Calendar.current.startOfDay(for: Date()) ? .red : .secondary)
                    Text(item.counterparty ?? item.number)
                        .lineLimit(1)
                }
                .font(.caption2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Zamykací obrazovka

private struct RectangularView: View {
    let summary: DueSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Splatnosti", systemImage: "doc.text")
                .font(.caption.weight(.semibold))
                .widgetAccentable()
            Text("Po splatnosti: \(summary.issued.overdueCount) vyd. · \(summary.received.overdueCount) přij.")
                .font(.caption)
            Text("Do týdne: \(summary.issued.soonCount) vyd. · \(summary.received.soonCount) přij.")
                .font(.caption)
        }
    }
}

private struct InlineView: View {
    let summary: DueSummary

    var body: some View {
        Text("sÚčto: po splatnosti \(summary.issued.overdueCount + summary.received.overdueCount)")
    }
}

private extension DueSummary {
    /// Malý widget a zamykací obrazovka: odkaz na stranu s víc prošlými fakturami (při shodě vydané).
    func overdueLink(companyId: Int?) -> URL? {
        DueLink.url(companyId: companyId, isIncoming: received.overdueCount > issued.overdueCount)
    }
}

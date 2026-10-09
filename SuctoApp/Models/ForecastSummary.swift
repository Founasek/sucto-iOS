//
//  ForecastSummary.swift
//  SuctoApp
//

import Foundation

/// Prognóza splatností na dalších 30 dní po týdnech: kolik nám mají zaplatit odběratelé (vydané faktury)
/// a kolik máme zaplatit my (přijaté). Měny se nepřepočítávají, každá má vlastní řádek.
struct ForecastSummary: Equatable {
    static let horizonDays = 30

    struct Week: Identifiable, Equatable {
        let start: Date
        let end: Date
        var incoming = 0.0
        var outgoing = 0.0
        var id: Date { start }
    }

    struct Row: Identifiable, Equatable {
        let currency: String
        var weeks: [Week]
        var id: String { currency }

        /// Očekávané příjmy (vydané faktury).
        var incomingTotal: Double { weeks.reduce(0) { $0 + $1.incoming } }
        /// Platby, které máme uhradit (přijaté faktury).
        var outgoingTotal: Double { weeks.reduce(0) { $0 + $1.outgoing } }
        var net: Double { incomingTotal - outgoingTotal }
    }

    let rows: [Row]
    /// Nejbližší splatné faktury (od dneška), nejdřív ty nejbližší.
    let upcoming: [DueItem]

    var isEmpty: Bool { rows.isEmpty }

    init(items: [DueItem], now: Date = Date(), calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        var byCurrency: [String: Row] = [:]
        var order: [String] = []
        var inRange: [DueItem] = []

        for item in items {
            let due = calendar.startOfDay(for: item.dueDate)
            guard let days = calendar.dateComponents([.day], from: today, to: due).day,
                  days >= 0, days <= Self.horizonDays
            else { continue }
            inRange.append(item)

            let key = item.currency ?? "Kč"
            if byCurrency[key] == nil {
                byCurrency[key] = Row(currency: key, weeks: Self.emptyWeeks(from: today, calendar: calendar))
                order.append(key)
            }
            let index = min(days / 7, (byCurrency[key]?.weeks.count ?? 1) - 1)
            if item.isIncoming {
                byCurrency[key]?.weeks[index].outgoing += item.amount
            } else {
                byCurrency[key]?.weeks[index].incoming += item.amount
            }
        }

        // Česká koruna vždy první, ostatní měny podle objemu.
        rows = order.compactMap { byCurrency[$0] }.sorted { lhs, rhs in
            if isCzechCrown(lhs.currency) != isCzechCrown(rhs.currency) { return isCzechCrown(lhs.currency) }
            return (lhs.incomingTotal + lhs.outgoingTotal) > (rhs.incomingTotal + rhs.outgoingTotal)
        }
        upcoming = Array(inRange.sorted { $0.dueDate < $1.dueDate }.prefix(6))
    }

    /// Pět týdenních košů: dny 0–6, 7–13, 14–20, 21–27 a 28–30.
    private static func emptyWeeks(from today: Date, calendar: Calendar) -> [Week] {
        (0 ..< 5).compactMap { index in
            guard let start = calendar.date(byAdding: .day, value: index * 7, to: today),
                  let end = calendar.date(byAdding: .day, value: min(index * 7 + 6, horizonDays), to: today)
            else { return nil }
            return Week(start: start, end: end)
        }
    }
}

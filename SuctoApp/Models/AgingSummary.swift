//
//  AgingSummary.swift
//  SuctoApp
//

import Foundation

/// Stáří pohledávek a závazků po splatnosti: kolik je prošlých 1–30, 31–60, 61–90 a přes 90 dní.
/// Měny se nepřepočítávají, každá má vlastní řádek.
struct AgingSummary: Equatable {
    struct Bucket: Equatable, Identifiable {
        let title: String
        let range: ClosedRange<Int>
        var id: String { title }

        static let all: [Bucket] = [
            Bucket(title: "1–30 dní", range: 1 ... 30),
            Bucket(title: "31–60 dní", range: 31 ... 60),
            Bucket(title: "61–90 dní", range: 61 ... 90),
            Bucket(title: "přes 90 dní", range: 91 ... Int.max),
        ]
    }

    struct Amounts: Equatable {
        var invoiceCount = 0
        var amount = 0.0

        var hasInvoices: Bool { invoiceCount != 0 }
    }

    /// Řádek za jednu měnu: součty po koších zvlášť pro vydané (nám dlužím) a přijaté (dlužíme my).
    struct Row: Identifiable, Equatable {
        let currency: String
        var issued: [Amounts]
        var received: [Amounts]
        var id: String { currency }

        var issuedTotal: Amounts { Self.sum(issued) }
        var receivedTotal: Amounts { Self.sum(received) }

        private static func sum(_ values: [Amounts]) -> Amounts {
            Amounts(invoiceCount: values.reduce(0) { $0 + $1.invoiceCount }, amount: values.reduce(0) { $0 + $1.amount })
        }
    }

    let rows: [Row]

    var isEmpty: Bool { rows.isEmpty }

    init(items: [DueItem], now: Date = Date(), calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        var byCurrency: [String: Row] = [:]
        var order: [String] = []
        let empty = Array(repeating: Amounts(), count: Bucket.all.count)

        for item in items {
            let due = calendar.startOfDay(for: item.dueDate)
            guard let days = calendar.dateComponents([.day], from: due, to: today).day, days >= 1,
                  let index = Bucket.all.firstIndex(where: { $0.range.contains(days) })
            else { continue }
            let key = item.currency ?? "Kč"
            if byCurrency[key] == nil {
                byCurrency[key] = Row(currency: key, issued: empty, received: empty)
                order.append(key)
            }
            if item.isIncoming {
                byCurrency[key]?.received[index].invoiceCount += 1
                byCurrency[key]?.received[index].amount += item.amount
            } else {
                byCurrency[key]?.issued[index].invoiceCount += 1
                byCurrency[key]?.issued[index].amount += item.amount
            }
        }
        // Měna s nejvyšším počtem prošlých faktur první.
        rows = order.compactMap { byCurrency[$0] }.sorted {
            ($0.issuedTotal.invoiceCount + $0.receivedTotal.invoiceCount) > ($1.issuedTotal.invoiceCount + $1.receivedTotal.invoiceCount)
        }
    }
}

//
//  DueWidget.swift
//  SuctoWidget
//

import SwiftUI
import WidgetKit

struct DueEntry: TimelineEntry {
    let date: Date
    let snapshot: DueSnapshot?

    var summary: DueSummary? {
        snapshot.map { DueSummary(items: $0.items, now: date) }
    }
}

struct DueProvider: TimelineProvider {
    func placeholder(in _: Context) -> DueEntry {
        DueEntry(date: Date(), snapshot: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (DueEntry) -> Void) {
        completion(DueEntry(date: Date(), snapshot: context.isPreview ? Self.sample : DueSnapshotStore.load()))
    }

    /// Souhrn se počítá z uložených položek, takže jednotlivé položky timeline „přepočítají“, co je po splatnosti, i bez dat z aplikace.
    func getTimeline(in _: Context, completion: @escaping (Timeline<DueEntry>) -> Void) {
        let snapshot = DueSnapshotStore.load()
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let afterNext = calendar.date(byAdding: .day, value: 1, to: midnight) ?? midnight
        let entries = [now, midnight, afterNext].map { DueEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(calendar.date(byAdding: .hour, value: 6, to: now) ?? now)))
    }

    private static var sample: DueSnapshot {
        let day: TimeInterval = 86400
        let now = Date()
        return DueSnapshot(
            companyName: "Ukázková firma",
            items: [
                DueItem(id: 1, isIncoming: false, number: "FV 2026001", counterparty: "Klient s.r.o.", dueDate: now - 3 * day, amount: 24500, currency: "Kč"),
                DueItem(id: 2, isIncoming: false, number: "FV 2026002", counterparty: "Další klient", dueDate: now + 2 * day, amount: 12000, currency: "Kč"),
                DueItem(id: 3, isIncoming: true, number: "FP 118", counterparty: "Dodavatel a.s.", dueDate: now + day, amount: 8300, currency: "Kč"),
            ],
            updatedAt: now,
        )
    }
}

struct DueWidget: Widget {
    let kind = "DueWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DueProvider()) { entry in
            DueWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Splatnosti")
        .description("Faktury po splatnosti a splatné v nejbližších dnech.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

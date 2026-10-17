//
//  DueSnapshot.swift
//  Sdílený kód aplikace a widgetu (jen Foundation, žádné UIKit/SwiftUI závislosti).
//

import Foundation

/// Nezaplacená faktura se splatností – podklad pro widget a upozornění.
struct DueItem: Codable, Hashable {
    let id: Int
    /// `true` = přijatá faktura (my platíme), `false` = vydaná (platí nám).
    let isIncoming: Bool
    let number: String
    let counterparty: String?
    let dueDate: Date
    /// Zbývající částka k úhradě.
    let amount: Double
    let currency: String?
}

/// Poslední stav splatností vybrané firmy. Widget ho jen čte; token ani síť nepotřebuje.
struct DueSnapshot: Codable {
    /// Chybí u snapshotů uložených starší verzí; widget pak odkaz do aplikace neumí cílit na firmu.
    let companyId: Int?
    let companyName: String
    let items: [DueItem]
    let updatedAt: Date
}

enum DueSnapshotStore {
    static let appGroup = "group.com.UFOSOFT.SuctoApp"
    /// Klíč, pod kterým dřívější verze ukládaly snapshot do `UserDefaults`; hodnota se při prvním přístupu smaže.
    private static let legacyKey = "dueSnapshot"
    private static let fileName = "dueSnapshot.json"

    /// Sdílené úložiště aplikace a widgetu; bez App Group (např. nepodepsaný build) se použije běžné.
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    /// Soubor v kontejneru skupiny (bez něj v Application Support). Snapshot obsahuje protistrany a částky, proto leží
    /// v souboru mimo zálohy, ne v plistu `UserDefaults`, který se zálohuje. Widget ho musí číst i na zamčeném telefonu,
    /// proto je ochrana „do prvního odemknutí“ (přísnější by widget zablokovala).
    private static var fileURL: URL? {
        let manager = FileManager.default
        let directory = manager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let directory else { return nil }
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }

    static func save(_ snapshot: DueSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot), var url = fileURL else { return }
        guard (try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])) != nil else { return }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
        sharedDefaults.removeObject(forKey: legacyKey)
    }

    static func load() -> DueSnapshot? {
        if let url = fileURL, let data = try? Data(contentsOf: url) {
            return try? JSONDecoder().decode(DueSnapshot.self, from: data)
        }
        // Snapshot z dřívější verze, dokud ho aplikace nepřepíše novým.
        guard let data = sharedDefaults.data(forKey: legacyKey) else { return nil }
        return try? JSONDecoder().decode(DueSnapshot.self, from: data)
    }

    /// Při odhlášení – widget nesmí dál ukazovat data předchozího uživatele.
    static func clear() {
        if let url = fileURL { try? FileManager.default.removeItem(at: url) }
        sharedDefaults.removeObject(forKey: legacyKey)
    }
}

/// Součty za jednu stranu (vydané nebo přijaté).
struct DueSide: Equatable {
    var overdueCount = 0
    var overdueAmount = 0.0
    var soonCount = 0
    var soonAmount = 0.0
    /// Nejbližší splatné (nebo nejstarší prošlé) položky pro výpis.
    var nearest: [DueItem] = []
}

/// Souhrn splatností k danému okamžiku. Počítá se při zobrazení, takže zůstává správně i dny po posledním načtení.
struct DueSummary: Equatable {
    var issued = DueSide()
    var received = DueSide()
    /// Měna, ve které jsou součty (nejčastější v datech); položky v jiných měnách se jen počítají.
    var currency: String?
    var otherCurrencyCount = 0

    static let soonDays = 7

    init(items: [DueItem], now: Date = Date(), calendar: Calendar = .current) {
        let counts = Dictionary(grouping: items, by: \.currency).mapValues(\.count)
        let main = counts.max { $0.value < $1.value }?.key
        currency = main ?? nil
        let today = calendar.startOfDay(for: now)
        let limit = calendar.date(byAdding: .day, value: Self.soonDays, to: today) ?? today

        for item in items {
            guard item.currency == currency else {
                otherCurrencyCount += 1
                continue
            }
            let due = calendar.startOfDay(for: item.dueDate)
            var side = item.isIncoming ? received : issued
            if due < today {
                side.overdueCount += 1
                side.overdueAmount += item.amount
            } else if due <= limit {
                side.soonCount += 1
                side.soonAmount += item.amount
            }
            if item.isIncoming { received = side } else { issued = side }
        }
        issued.nearest = Self.nearest(items.filter { !$0.isIncoming }, today: today)
        received.nearest = Self.nearest(items.filter(\.isIncoming), today: today)
    }

    /// Prošlé nejdřív (nejstarší nahoře), pak budoucí podle data.
    private static func nearest(_ items: [DueItem], today _: Date, limit: Int = 3) -> [DueItem] {
        Array(items.sorted { $0.dueDate < $1.dueDate }.prefix(limit))
    }
}

enum DueFormat {
    private static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = "\u{00A0}"
        formatter.locale = Locale(identifier: "cs_CZ")
        return formatter
    }()

    static func amount(_ value: Double, currency: String?) -> String {
        let text = whole.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        guard let currency, !currency.isEmpty else { return text }
        return "\(text)\u{00A0}\(currency)"
    }

    /// „1 faktura“, „2 faktury“, „5 faktur“.
    static func invoices(_ count: Int) -> String {
        switch count {
        case 1: "1 faktura"
        case 2 ... 4: "\(count) faktury"
        default: "\(count) faktur"
        }
    }
}

/// Odkaz z widgetu do aplikace: `sucto://overdue?company=ID&side=issued|received`.
/// Aplikace otevře firmu na záložce vydaných/přijatých s filtrem „Po splatnosti“.
enum DueLink {
    static let scheme = "sucto"

    static func url(companyId: Int?, isIncoming: Bool) -> URL? {
        guard let companyId else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = "overdue"
        components.queryItems = [
            URLQueryItem(name: "company", value: "\(companyId)"),
            URLQueryItem(name: "side", value: isIncoming ? "received" : "issued"),
        ]
        return components.url
    }

    static func parse(_ url: URL) -> (companyId: Int, isIncoming: Bool)? {
        guard url.scheme == scheme, url.host == "overdue",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let company = items.first(where: { $0.name == "company" })?.value.flatMap(Int.init)
        else { return nil }
        return (company, items.first { $0.name == "side" }?.value == "received")
    }
}

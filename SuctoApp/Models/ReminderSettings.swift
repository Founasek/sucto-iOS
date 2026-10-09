//
//  ReminderSettings.swift
//  SuctoApp
//

import Foundation

/// Nastavení upomínek po splatnosti. Funkce je ve výchozím stavu VYPNUTÁ – uživatel ji musí vědomě zapnout v Nastavení.
/// Žádná upomínka se neodesílá sama, každou potvrzuje uživatel v okně s upravitelným textem.
enum ReminderSettings {
    /// Klíč v UserDefaults; sdílí ho i `@AppStorage` v obrazovkách, aby se překlep nemohl rozejít.
    static let enabledKey = "remindersEnabled"
    private static let templateKey = "reminderTemplate"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Zástupné znaky, které se při odeslání nahradí údaji faktury.
    static let placeholders: [(token: String, meaning: String)] = [
        ("{číslo}", "číslo faktury"),
        ("{částka}", "zbývající částka k úhradě"),
        ("{splatnost}", "datum splatnosti"),
        ("{dní_po_splatnosti}", "počet dní po splatnosti, např. „3 dny“"),
        ("{firma}", "název vaší firmy"),
    ]

    static let defaultTemplate = """
    Dobrý den,

    dovolujeme si Vás upozornit, že faktura {číslo} na částku {částka} byla splatná dne {splatnost} \
    ({dní_po_splatnosti} po splatnosti) a v naší evidenci ji dosud nemáme uhrazenou.

    Pokud jste platbu již odeslali, považujte prosím tuto zprávu za bezpředmětnou. V opačném případě Vás prosíme o její úhradu.

    Děkujeme.
    {firma}
    """

    /// Uložená šablona uživatele, jinak výchozí text.
    static var template: String {
        get {
            let stored = UserDefaults.standard.string(forKey: templateKey)
            return (stored?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ? defaultTemplate : stored ?? defaultTemplate
        }
        set { UserDefaults.standard.set(newValue, forKey: templateKey) }
    }

    static func resetTemplate() {
        UserDefaults.standard.removeObject(forKey: templateKey)
    }

    /// „1 den“, „3 dny“, „7 dnů“.
    static func days(_ count: Int) -> String {
        switch count {
        case 1: "1 den"
        case 2 ... 4: "\(count) dny"
        default: "\(count) dnů"
        }
    }

    /// Dosadí údaje faktury do šablony.
    static func render(_ template: String, invoice: Invoice, companyName: String?, now: Date = Date()) -> String {
        let overdueDays = invoice.dueDate.flatMap {
            Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: $0), to: Calendar.current.startOfDay(for: now)).day
        } ?? 0
        let amountText = invoice.remaining.flatMap(Double.init).flatMap { $0 > 0 ? String($0) : nil } ?? invoice.endPrice
        let values: [String: String] = [
            "{číslo}": invoice.actuarialNumber,
            "{částka}": FormatterHelper.formatPrice(amountText, currency: invoice.currency?.symbol),
            "{splatnost}": invoice.dueDateAt ?? "",
            "{dní_po_splatnosti}": days(max(overdueDays, 0)),
            "{firma}": companyName ?? "",
        ]
        return values.reduce(template) { text, pair in text.replacingOccurrences(of: pair.key, with: pair.value) }
    }
}

/// Kdy byla k faktuře naposledy odeslána upomínka (jen na tomto zařízení) – ať se omylem neposílá dvakrát po sobě.
enum ReminderLog {
    private static let key = "reminderLog"

    private static var entries: [String: Date] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else { return [:] }
            return (try? JSONDecoder().decode([String: Date].self, from: data)) ?? [:]
        }
        set { UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: key) }
    }

    static func lastSent(invoiceId: Int) -> Date? {
        entries["\(invoiceId)"]
    }

    static func record(invoiceId: Int, date: Date = Date()) {
        var all = entries
        all["\(invoiceId)"] = date
        // Záznamy starší než rok se zahodí, ať soubor neroste donekonečna.
        let limit = Calendar.current.date(byAdding: .year, value: -1, to: date) ?? date
        entries = all.filter { $0.value >= limit }
    }
}

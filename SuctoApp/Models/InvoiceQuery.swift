//
//  InvoiceQuery.swift
//  SuctoApp
//

import Foundation

/// Rychlé filtry seznamu faktur. Stavy odpovídají `status_id` z API dokumentace.
enum InvoiceFilter: CaseIterable, Identifiable {
    case all, overdue, paid, concept

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Vše"
        case .overdue: "Po splatnosti"
        case .paid: "Zaplacené"
        case .concept: "Koncepty"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "tray.full"
        case .overdue: "exclamationmark.triangle"
        case .paid: "checkmark.circle"
        case .concept: "pencil.and.list.clipboard"
        }
    }
}

/// Podrobné filtry ze sheetu „Filtry“ (parametry `q[...]` z API dokumentace).
struct InvoiceAdvancedFilter: Equatable {
    var status: Invoice.Status?
    var issueFrom: Date?
    var issueTo: Date?
    var dueFrom: Date?
    var dueTo: Date?
    /// Částka s DPH (`end_price`).
    var minPrice: Double?
    var maxPrice: Double?

    /// Kolik podrobných filtrů je zapnutých (do odznaku na tlačítku).
    var activeCount: Int {
        [status != nil,
         issueFrom != nil || issueTo != nil,
         dueFrom != nil || dueTo != nil,
         minPrice != nil || maxPrice != nil].filter(\.self).count
    }

    var isActive: Bool { activeCount > 0 }
}

/// Dotaz na seznam faktur – převádí hledání a filtr na `q[...]` parametry (ransack) z API dokumentace.
struct InvoiceQuery {
    var search = ""
    var filter: InvoiceFilter = .all
    var advanced = InvoiceAdvancedFilter()

    var isActive: Bool {
        filter != .all || advanced.isActive || !search.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Číslo s tečkou bez zbytečné desetinné části („1500“, „99.5“).
    private static func number(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }

    func queryItems(page: Int, today: Date = Date()) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "page", value: "\(page)")]

        let term = search.trimmingCharacters(in: .whitespaces)
        if !term.isEmpty {
            // API nabízí samostatné parametry: text s číslicí bereme jako číslo faktury, jinak jako jméno partnera.
            let key = term.contains(where: \.isNumber) ? "q[actuarial_number_cont]" : "q[partner_name_cont]"
            items.append(URLQueryItem(name: key, value: term))
        }

        // Stav ze sheetu má přednost před rychlým filtrem (view model je v praxi drží navzájem nezávislé).
        if let status = advanced.status {
            items.append(URLQueryItem(name: "q[status_eq]", value: "\(status.rawValue)"))
        }

        var dueTo = advanced.dueTo
        switch filter {
        case .all:
            break
        case .paid:
            if advanced.status == nil { items.append(URLQueryItem(name: "q[status_eq]", value: "8")) }
        case .concept:
            if advanced.status == nil { items.append(URLQueryItem(name: "q[status_eq]", value: "1")) }
        case .overdue:
            // Server umí jen filtrovat podle data; zaplacené a stornované vyřadíme na klientu (viz `Invoice.isOverdue`).
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) {
                dueTo = min(dueTo ?? yesterday, yesterday)
            }
        }

        let dates: [(String, Date?)] = [
            ("q[issue_date_at_gteq]", advanced.issueFrom), ("q[issue_date_at_lteq]", advanced.issueTo),
            ("q[due_date_at_gteq]", advanced.dueFrom), ("q[due_date_at_lteq]", dueTo),
        ]
        for (key, date) in dates {
            if let date { items.append(URLQueryItem(name: key, value: Self.dateFormatter.string(from: date))) }
        }
        if let minPrice = advanced.minPrice { items.append(URLQueryItem(name: "q[end_price_gteq]", value: Self.number(minPrice))) }
        if let maxPrice = advanced.maxPrice { items.append(URLQueryItem(name: "q[end_price_lteq]", value: Self.number(maxPrice))) }
        return items
    }

    func path(_ base: String, page: Int) -> String {
        var components = URLComponents()
        components.queryItems = queryItems(page: page)
        return "\(base)?\(components.percentEncodedQuery ?? "")"
    }
}

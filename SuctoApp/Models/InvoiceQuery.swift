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

/// Dotaz na seznam faktur – převádí hledání a filtr na `q[...]` parametry (ransack) z API dokumentace.
struct InvoiceQuery {
    var search = ""
    var filter: InvoiceFilter = .all

    var isActive: Bool {
        filter != .all || !search.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func queryItems(page: Int, today: Date = Date()) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "page", value: "\(page)")]

        let term = search.trimmingCharacters(in: .whitespaces)
        if !term.isEmpty {
            // API nabízí samostatné parametry: text s číslicí bereme jako číslo faktury, jinak jako jméno partnera.
            let key = term.contains(where: \.isNumber) ? "q[actuarial_number_cont]" : "q[partner_name_cont]"
            items.append(URLQueryItem(name: key, value: term))
        }

        switch filter {
        case .all:
            break
        case .paid:
            items.append(URLQueryItem(name: "q[status_eq]", value: "8"))
        case .concept:
            items.append(URLQueryItem(name: "q[status_eq]", value: "1"))
        case .overdue:
            // Server umí jen filtrovat podle data; zaplacené a stornované vyřadíme na klientu (viz `Invoice.isOverdue`).
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) {
                items.append(URLQueryItem(name: "q[due_date_at_lteq]", value: Self.dateFormatter.string(from: yesterday)))
            }
        }
        return items
    }

    func path(_ base: String, page: Int) -> String {
        var components = URLComponents()
        components.queryItems = queryItems(page: page)
        return "\(base)?\(components.percentEncodedQuery ?? "")"
    }
}

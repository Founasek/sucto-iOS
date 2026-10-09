//
//  InvoiceCSVExporter.swift
//  SuctoApp
//

import Foundation

/// Export seznamu faktur do CSV pro Excel / účetní: oddělovač `;`, desetinná čárka, UTF-8 s BOM, řádky CRLF.
enum InvoiceCSVExporter {
    static let header = [
        "Číslo", "Typ", "Protistrana", "Datum vystavení", "Datum UZP", "Splatnost", "Stav",
        "Základ", "Celkem", "Zbývá uhradit", "Měna", "Variabilní symbol",
    ]

    static func csv(for invoices: [Invoice], direction: InvoiceDirection) -> Data {
        var lines = [header.map(escape).joined(separator: ";")]
        for invoice in invoices {
            let counterparty = direction == .outgoing ? invoice.customer?.name : invoice.supplier?.name
            let fields: [String] = [
                invoice.actuarialNumber,
                invoice.actuarialType,
                counterparty ?? "",
                invoice.issueDateAt ?? "",
                invoice.uzpDateAt ?? "",
                invoice.dueDateAt ?? "",
                invoice.status,
                number(invoice.basePrice),
                number(invoice.endPrice),
                number(invoice.remaining),
                invoice.currency?.isoCode ?? invoice.currency?.symbol ?? "",
                invoice.variableSymbol ?? "",
            ]
            lines.append(fields.map(escape).joined(separator: ";"))
        }
        // BOM, aby Excel poznal UTF-8 (jinak rozbije češtinu).
        return Data([0xEF, 0xBB, 0xBF]) + Data((lines.joined(separator: "\r\n") + "\r\n").utf8)
    }

    /// „200.0“ → „200,00“ (bez oddělovačů tisíců, aby šlo číst jako číslo).
    static func number(_ value: String?) -> String {
        guard let value, let double = Double(value) else { return value ?? "" }
        return String(format: "%.2f", double).replacingOccurrences(of: ".", with: ",")
    }

    /// Hodnoty s oddělovačem, uvozovkou nebo zalomením se uzavřou do uvozovek; uvozovky se zdvojí.
    /// Texty začínající `=`, `+`, `-`, `@` dostanou apostrof, aby je tabulka nebrala jako vzorec (CSV injection).
    static func escape(_ value: String) -> String {
        var text = value
        if let first = text.first, "=+-@".contains(first) { text = "'" + text }
        if text.contains(";") || text.contains("\"") || text.contains("\n") || text.contains("\r") {
            return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return text
    }

    /// Název souboru, např. `faktury-vydane-2026-10-09.csv`.
    static func fileName(direction: InvoiceDirection, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "faktury-\(direction == .outgoing ? "vydane" : "prijate")-\(formatter.string(from: date)).csv"
    }
}

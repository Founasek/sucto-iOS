//
//  PohodaExporter+XML.swift
//  SuctoApp
//

import Foundation

/// Pomocné funkce pro sestavení XML: čísla, data, elementy a escapování.
extension PohodaExporter {
    // MARK: - Pomocné

    static func decimal(_ string: String) throws -> Decimal {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard let value = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")) else {
            throw ExportError.invalidAmount(string)
        }
        return value
    }

    static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Datum z API („dd. MM. yyyy“) na ISO. Prázdná hodnota → `nil`.
    static func isoDate(_ apiDate: String?) throws -> String? {
        guard let apiDate, !apiDate.isEmpty else { return nil }
        guard let date = apiDate.toDate() else { throw ExportError.invalidDate(apiDate) }
        return isoFormatter.string(from: date)
    }

    static func element(_ name: String, _ value: String?, indent: Int) -> String {
        guard let value, !value.isEmpty else { return "" }
        return String(repeating: " ", count: indent) + "<\(name)>\(escape(value))</\(name)>\n"
    }

    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

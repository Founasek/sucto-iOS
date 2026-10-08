//
//  PohodaExporter+Types.swift
//  SuctoApp
//

import Foundation

extension PohodaExporter {
    enum ExportError: LocalizedError {
        case unsupportedType(String)
        case unsupportedCurrency(String)
        case unsupportedVATRate(String)
        case missingIssuer
        case missingItems
        case invalidAmount(String)
        case invalidDate(String)

        var errorDescription: String? {
            switch self {
            case let .unsupportedType(type):
                "typ dokladu „\(type)“ (export podporuje jen faktury FA)"
            case let .unsupportedCurrency(code):
                "neplatný kód měny „\(code)“"
            case let .unsupportedVATRate(rate):
                "sazba DPH \(rate) % (podporované jsou 21, 12 a 0)"
            case .missingIssuer:
                "chybí IČ firmy (vystavitele)"
            case .missingItems:
                "faktura nemá žádné položky"
            case let .invalidAmount(value):
                "neplatná částka „\(value)“"
            case let .invalidDate(value):
                "neplatné datum „\(value)“"
            }
        }
    }

    /// Faktura, kterou se nepodařilo převést, a důvod.
    struct Failure: Identifiable {
        let id: Int
        let number: String
        let reason: String
    }

    struct Result {
        let data: Data
        let exportedCount: Int
        let failures: [Failure]
    }
}

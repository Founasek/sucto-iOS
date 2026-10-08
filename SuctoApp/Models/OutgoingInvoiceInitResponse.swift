//
//  OutgoingInvoiceInitResponse.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct OutgoingInvoiceInitResponse: Decodable {
    let actuarialNumber: String
    let variableSymbol: String?

    let issueDateAt: String?
    let dueDateAt: String?
    let uzpDateAt: String?

    let currency: Currency?
    let customer: Customer?
    let items: [OutgoingInvoiceCreateLine]

    var issueDate: Date? {
        issueDateAt?.toDate()
    }

    var dueDate: Date? {
        dueDateAt?.toDate()
    }

    enum CodingKeys: String, CodingKey {
        case actuarialNumber = "actuarial_number",
             variableSymbol = "variable_symbol",
             issueDateAt = "issue_date_at",
             dueDateAt = "due_date_at",
             uzpDateAt = "uzp_date_at",
             currency,
             customer,
             items
    }
}

extension String {
    private static let czechDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd. MM. yyyy"
        formatter.locale = Locale(identifier: "cs_CZ")
        return formatter
    }()

    /// Datum z odpovědi API ve tvaru „dd. MM. yyyy“.
    func toDate() -> Date? {
        Self.czechDateFormatter.date(from: self)
    }
}

struct OutgoingInvoiceCreatedResponse: Decodable {
    let id: Int
}

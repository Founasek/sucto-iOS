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
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd. MM. yyyy"
        formatter.locale = Locale(identifier: "cs_CZ")
        return formatter.date(from: self)
    }
}

struct OutgoingInvoiceCreatedResponse: Decodable {
    let id: Int
}

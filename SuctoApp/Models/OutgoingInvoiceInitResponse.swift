//
//  OutgoingInvoiceNewResponse.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct OutgoingInvoiceInitResponse: Decodable {
    let actuarial_number: String
    let variableSymbol: String?
    
    let issue_date_at: String?
    let due_date_at: String?
    let uzpDateAt: String?
    
    let currency: Currency?
    let customer: Customer?
    let items: [CreateInvoiceLine]
    
    var issueDate: Date? {
        issue_date_at?.toDate()
    }
    
    var dueDate: Date? {
        due_date_at?.toDate()
    }
    
    enum CodingKeys: String, CodingKey {
        case actuarial_number = "actuarial_number",
             variableSymbol = "variable_symbol",
             issue_date_at = "issue_date_at",
             due_date_at = "due_date_at",
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

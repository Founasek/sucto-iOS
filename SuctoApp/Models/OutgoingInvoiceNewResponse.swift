//
//  OutgoingInvoiceNewResponse.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct OutgoingInvoiceNewResponse: Decodable {
    let actuarial_number: String
    let issue_date_at: String?
    let due_date_at: String?
    let currency: Currency?
    let customer: Partner?
    let items: [InvoiceItem]
    
    var issueDate: Date? {
        issue_date_at?.toDate()
    }
    
    var dueDate: Date? {
        due_date_at?.toDate()
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

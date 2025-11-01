//
//  Invoice.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import Foundation

struct Invoice: Identifiable, Codable, Hashable {
    let id: Int
    let actuarialType: String
    let actuarialNumber: String
    let issueDateAt: String?
    let uzpDateAt: String?
    let dueDateAt: String?
    let status: String
    let statusId: Int
    let basePrice: String?
    let endPrice: String?
    let remaining: String?
    let variableSymbol: String?
    let currency: Currency?
    let printNotice: String?
    let footNotice: String?
    let externalNumber: String?
    let orderNumber: String?
    let taxable : Bool?
    let vat : String?
    let pay : String?
    
    let account: Account?

    // U vydané faktury
    let customer: Customer?
    // U přijaté faktury
    let supplier: Supplier?

    // Položky faktury
    let items: [InvoiceItem]?

    enum CodingKeys: String, CodingKey {
        case id
        case actuarialType = "actuarial_type"
        case actuarialNumber = "actuarial_number"
        case uzpDateAt = "uzp_date_at"
        case dueDateAt = "due_date_at"
        case status
        case statusId = "status_id"
        case issueDateAt = "issue_date_at"
        case basePrice = "base_price"
        case endPrice = "end_price"
        case remaining
        case variableSymbol = "variable_symbol"
        case currency
        case printNotice = "print_notice"
        case footNotice = "foot_notice"
        case customer
        case supplier
        case items
        case externalNumber = "external_number"
        case orderNumber = "order_number"
        case account
        case taxable
        case vat
        case pay
    }
}

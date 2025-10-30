//
//  Actuarial.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//


import Foundation

struct Invoice: Identifiable, Codable, Hashable {
    let id: Int
    let actuarialType: String
    let actuarialNumber: String
    let uzpDateAt: String?
    let dueDateAt: String?
    let status: String
    let statusId: Int
    let issueDateAt: String?
    let basePrice: String?
    let endPrice: String?
    let remaining: String?
    let variableSymbol: String?
    let currency: Currency?
    let printNotice: String?
    let footNotice: String?

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
    }
}







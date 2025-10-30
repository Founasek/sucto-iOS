//
//  CreateInvoiceRequest.swift
//  SuctoApp
//
//  Created by Jan Founě on 26.10.2025.
//


struct OutgoingInvoiceCreateRequest: Codable {
    var actuarialNumber: String
    var variableSymbol: String
    var actuarialTypeId: Int
    
    var partnerId: Int
    var accountId: Int
    var currencyId: Int
    
    var iban: String
    var swift: String
    var bankNumber: String
    var vatRegimeId: Int
    
    var issueDateAt: String
    var dueDateAt: String
    var uzpDateAt: String
    
    var printNotice: String
    var orderNumber: String
    var lines: [CreateInvoiceLine]
    
    enum CodingKeys: String, CodingKey {
        case actuarialNumber = "actuarial_number"
        case variableSymbol = "variable_symbol"
        case actuarialTypeId = "actuarial_type_id"
        
        case partnerId = "partner_id"
        case accountId = "account_id"
        case currencyId = "currency_id"
        
        case iban = "iban"
        case swift = "swift"
        case bankNumber = "bank_number"
        case vatRegimeId = "vat_regime_id"
        
        case issueDateAt = "issue_date_at"
        case dueDateAt = "due_date_at"
        case uzpDateAt = "uzp_date_at"
        
        case printNotice = "print_notice"
        case orderNumber = "order_number"
        case lines
    }
}

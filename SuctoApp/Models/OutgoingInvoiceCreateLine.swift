//
//  CreateInvoiceLine.swift
//  SuctoApp
//
//  Created by Jan Founě on 26.10.2025.
//

import Foundation

struct OutgoingInvoiceCreateLine: Identifiable , Codable, Hashable {
    let id = UUID()
    var vatId: Int
    var lineableType: String
    var name: String
    var quantity: Double
    var unitPrice: Double
    var basePrice: Double
    var tax: Double
    var totalPrice: Double
    var unitName: String?
    
    enum CodingKeys: String, CodingKey {
        case vatId = "vat_id"
        case lineableType = "lineable_type"
        case name
        case quantity
        case unitPrice = "unit_price"
        case basePrice = "base_price"
        case tax
        case totalPrice = "total_price"
        case unitName = "unit_name"
    }
}

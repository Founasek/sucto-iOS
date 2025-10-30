//
//  InvoiceItem.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct InvoiceItem: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let quantity: String?
    let unitPrice: String?
    let basePrice: String?
    let totalPrice: String?
    let unitName: String?
    let vatId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
        case unitPrice = "unit_price"
        case basePrice = "base_price"
        case totalPrice = "total_price"
        case unitName = "unit_name"
        case vatId = "vat_id"
    }
}

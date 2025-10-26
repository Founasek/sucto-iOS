//
//  InvoiceItem.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct InvoiceItem: Identifiable, Codable {
    var id: UUID?
    var name: String
    var quantity: Double? = nil
    var unit_price: Double?
    var base_price: Double? = nil
    var vat_id: Double? = nil
    var total_price: Double? = nil
    var unit_name: String = ""
}

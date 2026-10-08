//
//  InvoiceCreateLine.swift
//  SuctoApp
//
//  Created by Jan Founě on 26.10.2025.
//

import Foundation

struct InvoiceCreateLine: Identifiable, Codable, Hashable {
    /// Pouze lokální identifikátor pro SwiftUI (neposílá se na server).
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

extension InvoiceCreateLine {
    /// Tolerantní čtení: řádek z naskenovaného dokladu má řadu hodnot prázdných (`null`).
    /// `vat_id == 0` znamená „doplní se první dostupná sazba“.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vatId = (try? container.decodeIfPresent(Int.self, forKey: .vatId)) ?? 0
        lineableType = container.lossyString(.lineableType) ?? "Actuarial"
        name = container.lossyString(.name) ?? ""
        quantity = container.lossyDouble(.quantity) ?? 1
        unitPrice = container.lossyDouble(.unitPrice) ?? 0
        basePrice = container.lossyDouble(.basePrice) ?? 0
        tax = container.lossyDouble(.tax) ?? 0
        totalPrice = container.lossyDouble(.totalPrice) ?? 0
        unitName = container.lossyString(.unitName)
    }
}

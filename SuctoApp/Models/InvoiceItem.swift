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
    /// Sazba DPH v procentech (např. „21.0“).
    let vat: String?
    /// Částka DPH za řádek.
    let tax: String?
    let discountPercentage: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
        case unitPrice = "unit_price"
        case basePrice = "base_price"
        case totalPrice = "total_price"
        case unitName = "unit_name"
        case vatId = "vat_id"
        case vat
        case tax
        case discountPercentage = "discount_percentage"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        quantity = container.lossyString(.quantity)
        unitPrice = container.lossyString(.unitPrice)
        basePrice = container.lossyString(.basePrice)
        totalPrice = container.lossyString(.totalPrice)
        unitName = container.lossyString(.unitName)
        vatId = try? container.decodeIfPresent(Int.self, forKey: .vatId)
        vat = container.lossyString(.vat)
        tax = container.lossyString(.tax)
        discountPercentage = container.lossyString(.discountPercentage)
    }
}

extension KeyedDecodingContainer {
    /// Čte číslo i tehdy, když ho API pošle jako text („1.0“); jinak `nil`.
    func lossyDouble(_ key: Key) -> Double? {
        if let double = try? decodeIfPresent(Double.self, forKey: key) { return double }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Double(string.replacingOccurrences(of: ",", with: "."))
        }
        return nil
    }

    /// Čte hodnotu jako text, i když ji API pošle jako číslo; chybějící či jiný typ vrátí `nil` místo chyby.
    func lossyString(_ key: Key) -> String? {
        if let string = try? decodeIfPresent(String.self, forKey: key) { return string }
        if let double = try? decodeIfPresent(Double.self, forKey: key) { return String(double) }
        return nil
    }
}

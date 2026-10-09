//
//  Supplier.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct Supplier: Codable, Hashable {
    let name: String
    let ic: String?
    let dic: String?
    let dic2: String?
    let street: String?
    let city: String?
    let zip: String?
    let isTaxable: Bool?
    let countryId: Int?

    enum CodingKeys: String, CodingKey {
        case name, ic, dic, dic2, street, city, zip
        case isTaxable = "is_taxable"
        case countryId = "country_id"
    }
}

extension Supplier {
    /// „Ulice, 110 00 Praha“ – prázdné části se vynechají.
    var addressLine: String? {
        let place = [zip, city].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " ")
        let parts = [street, place].compactMap(\.self).filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

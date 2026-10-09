//
//  Customer.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct Customer: Codable, Hashable {
    let id: Int?
    let name: String?
    let ic: String?
    let dic: String?
    let dic2: String?
    let email: String?
    let street: String?
    let city: String?
    let zip: String?
    let countryId: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, ic, dic, dic2, email, street, city, zip
        case countryId = "country_id"
    }
}

extension Customer {
    /// „Ulice, 110 00 Praha“ – prázdné části se vynechají.
    var addressLine: String? {
        let place = [zip, city].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " ")
        let parts = [street, place].compactMap(\.self).filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

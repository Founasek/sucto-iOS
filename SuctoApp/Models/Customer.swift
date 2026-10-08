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

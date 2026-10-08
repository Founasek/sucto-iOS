//
//  Company.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import Foundation

struct Company: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
    let ic: String
    let isTaxable: Bool
    let countryId: Int
    let email: String
    let logo: String?

    enum CodingKeys: String, CodingKey {
        case id, name, ic, email, logo
        case isTaxable = "is_taxable"
        case countryId = "country_id"
    }
}

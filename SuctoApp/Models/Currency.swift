//
//  Currency.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct Currency: Codable, Hashable, Identifiable {
    let id: Int?
    let isoCode: String?
    let name: String?
    let symbol: String?
    let symbolFirst: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case isoCode = "iso_code"
        case name
        case symbol
        case symbolFirst = "symbol_first"
    }
}

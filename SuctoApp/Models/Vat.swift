//
//  Vat.swift
//  SuctoApp
//
//  Created by Jan Founě on 30.10.2025.
//

struct Vat: Identifiable, Codable {
    let id: Int
    let value: String
    let validFrom: String
    let validTo: String?

    enum CodingKeys: String, CodingKey {
        case id, value
        case validFrom = "valid_from"
        case validTo = "valid_to"
    }
}

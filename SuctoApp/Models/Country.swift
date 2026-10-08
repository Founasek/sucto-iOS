//
//  Country.swift
//  SuctoApp
//

import Foundation

struct Country: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
    let defaultLanguage: String?
    let currency: Currency?

    private enum CodingKeys: String, CodingKey {
        case id, name, currency
        case defaultLanguage = "default_language"
    }
}

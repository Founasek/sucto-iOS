//
//  CompanyDetail.swift
//  SuctoApp
//

import Foundation

/// Detail firmy (`GET companies/{id}`): údaje ze seznamu firem a navíc adresa.
struct CompanyDetail: Decodable {
    let id: Int
    let name: String
    let ic: String
    let isTaxable: Bool
    let countryId: Int
    let email: String
    let address: Address?

    enum CodingKeys: String, CodingKey {
        case id, name, ic, email, address
        case isTaxable = "is_taxable"
        case countryId = "country_id"
    }

    /// Adresa na dva řádky: ulice (s částí obce) a PSČ s městem.
    var addressLines: [String] {
        guard let address else { return [] }
        let street = [address.street, address.cityPart].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: ", ")
        let city = [address.zip, address.city].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " ")
        return [street, city].filter { !$0.isEmpty }
    }
}

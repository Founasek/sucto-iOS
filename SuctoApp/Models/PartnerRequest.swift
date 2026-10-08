//
//  PartnerRequest.swift
//  SuctoApp
//

import Foundation

/// Tělo pro vytvoření/úpravu partnera: `{ "partner": { … } }` s `address_attributes` (dle příkladů v API dokumentaci).
/// Prázdné nepovinné hodnoty se posílají jako `null`, aby šly v úpravě vymazat.
struct PartnerAddressBody: Encodable {
    var street: String?
    var city: String
    var zip: String
    var countryId: Int

    enum CodingKeys: String, CodingKey {
        case street, city, zip
        case countryId = "country_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(street, forKey: .street)
        try container.encode(city, forKey: .city)
        try container.encode(zip, forKey: .zip)
        try container.encode(countryId, forKey: .countryId)
    }
}

struct PartnerBody: Encodable {
    var name: String
    var ic: String?
    var dic: String?
    var email: String?
    var phone: String?
    var web: String?
    var invoicingLanguage: String
    var invoiceDue: Int?
    var isTaxable: Bool
    var isSupplier: Bool
    var isCustomer: Bool
    var currencyId: Int
    var address: PartnerAddressBody

    enum CodingKeys: String, CodingKey {
        case name, ic, dic, email, phone, web
        case invoicingLanguage = "invoicing_language"
        case invoiceDue = "invoice_due"
        case isTaxable = "is_taxable"
        case isSupplier = "is_supplier"
        case isCustomer = "is_customer"
        case currencyId = "currency_id"
        case address = "address_attributes"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(ic, forKey: .ic)
        try container.encode(dic, forKey: .dic)
        try container.encode(email, forKey: .email)
        try container.encode(phone, forKey: .phone)
        try container.encode(web, forKey: .web)
        try container.encode(invoicingLanguage, forKey: .invoicingLanguage)
        try container.encode(invoiceDue, forKey: .invoiceDue)
        try container.encode(isTaxable, forKey: .isTaxable)
        try container.encode(isSupplier, forKey: .isSupplier)
        try container.encode(isCustomer, forKey: .isCustomer)
        try container.encode(currencyId, forKey: .currencyId)
        try container.encode(address, forKey: .address)
    }
}

struct PartnerRequest: Encodable {
    let partner: PartnerBody
}

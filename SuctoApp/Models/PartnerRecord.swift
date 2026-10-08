//
//  PartnerRecord.swift
//  SuctoApp
//

import Foundation

/// Adresa partnera. V seznamu partnerů chybí `country_id`, v detailu je i s `country`.
struct PartnerAddress: Decodable, Equatable {
    var street: String?
    var city: String?
    var zip: String?
    var countryId: Int?
    var countryName: String?

    private enum CodingKeys: String, CodingKey {
        case street, city, zip, country
        case countryId = "country_id"
    }

    private struct CountryRef: Decodable { let name: String? }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        street = container.lossyString(.street)
        city = container.lossyString(.city)
        zip = container.lossyString(.zip)
        countryId = try? container.decodeIfPresent(Int.self, forKey: .countryId)
        countryName = (try? container.decodeIfPresent(CountryRef.self, forKey: .country))?.name
    }

    /// „Ulice, 110 00 Praha“ – prázdné části se vynechají.
    var oneLine: String? {
        let place = [zip, city].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " ")
        let parts = [street, place].compactMap(\.self).filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

/// Partner ze seznamu i z detailu (seznam vrací jen podmnožinu polí, ostatní zůstanou prázdná).
struct PartnerRecord: Identifiable, Decodable, Equatable {
    let id: Int
    let name: String
    let ic: String?
    let dic: String?
    let dic2: String?
    let email: String?
    let phone: String?
    let fax: String?
    let web: String?
    let paypal: String?
    let invoicingLanguage: String?
    let invoiceDue: String?
    let isCustomer: Bool
    let isSupplier: Bool
    let isTaxable: Bool
    let address: PartnerAddress?
    let postalAddress: PartnerAddress?
    let currency: Currency?
    let currencyId: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name, ic, dic, dic2, email, phone, fax, web, paypal, address, currency
        case invoicingLanguage = "invoicing_language"
        case invoiceDue = "invoice_due"
        case isCustomer = "is_customer"
        case isSupplier = "is_supplier"
        case isTaxable = "is_taxable"
        case postalAddress = "postal_address"
        case currencyId = "currency_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        ic = container.lossyString(.ic)
        dic = container.lossyString(.dic)
        dic2 = container.lossyString(.dic2)
        email = container.lossyString(.email)
        phone = container.lossyString(.phone)
        fax = container.lossyString(.fax)
        web = container.lossyString(.web)
        paypal = container.lossyString(.paypal)
        invoicingLanguage = container.lossyString(.invoicingLanguage)
        invoiceDue = container.lossyString(.invoiceDue)
        isCustomer = (try? container.decodeIfPresent(Bool.self, forKey: .isCustomer)) ?? false
        isSupplier = (try? container.decodeIfPresent(Bool.self, forKey: .isSupplier)) ?? false
        isTaxable = (try? container.decodeIfPresent(Bool.self, forKey: .isTaxable)) ?? false
        address = try? container.decodeIfPresent(PartnerAddress.self, forKey: .address)
        postalAddress = try? container.decodeIfPresent(PartnerAddress.self, forKey: .postalAddress)
        currency = try? container.decodeIfPresent(Currency.self, forKey: .currency)
        currencyId = (try? container.decodeIfPresent(Int.self, forKey: .currencyId)) ?? currency?.id
    }

    var initial: String { String(name.prefix(1)).uppercased() }

    /// Dny splatnosti jako číslo (server může poslat číslo i text).
    var invoiceDueDays: Int? { invoiceDue.flatMap { Double($0) }.map { Int($0) } }
}

/// Měsíční řada z grafů partnera (např. „Faktury vydané“, 12 hodnot).
struct PartnerSeries: Decodable, Identifiable {
    let name: String
    let data: [Double]
    var id: String { name }
    var total: Double { data.reduce(0, +) }
}

/// Změna partnera, o které se má dozvědět seznam (detail a seznam jsou dvě nezávislé obrazovky).
enum PartnerEvent {
    case saved(PartnerRecord)
    case deleted(id: Int)

    static let notification = Notification.Name("PartnerEvent")
}

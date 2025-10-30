//
//  Partner.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct Partner: Identifiable, Codable {
    let id: Int?
    let name: String
    let ic: String?
    let dic: String?
    let isCustomer: Bool
    let isSupplier: Bool
    let email: String?
    let isTaxable: Bool
    let invoicingLanguage: String?
    let invoiceDue: Int?
    let address: Address?
    let currency: Currency?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ic
        case dic
        case isCustomer = "is_customer"
        case isSupplier = "is_supplier"
        case email
        case isTaxable = "is_taxable"
        case invoicingLanguage = "invoicing_language"
        case invoiceDue = "invoice_due"
        case address
        case currency
    }
}

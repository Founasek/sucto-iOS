//
//  BankAccount.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

struct BankAccount: Codable, Hashable {
    let id: Int?
    let countryId: Int?
    let account: String?
    let bankName: String?
    let iban: String?
    let createdAt: String?
    let updatedAt: String?
    let bankCode: String?
    let bankableId: Int?
    let bankableType: String?
    let isDeleted: Bool
    let swift: String?
    let qrCodes: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case countryId = "country_id"
        case account
        case bankName = "bank_name"
        case iban
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case bankCode = "bank_code"
        case bankableId = "bankable_id"
        case bankableType = "bankable_type"
        case isDeleted = "is_deleted"
        case swift
        case qrCodes = "qr_codes"
    }
}

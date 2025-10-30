//
//  Account.swift
//  SuctoApp
//
//  Created by Jan Founě on 07.10.2025.
//

import Foundation

struct Account: Identifiable, Codable, Hashable {
    let id: Int?
    let name: String
    let identifier: String?
    let accountType: Int
    let currencyId: Int
    let countryId: Int?
    let prefix: String
    let isDeactivated: Bool
    let openingBalance: String
    let bankAccount: BankAccount?

    enum CodingKeys: String, CodingKey {
        case id, name, identifier
        case accountType = "account_type"
        case currencyId = "currency_id"
        case countryId = "country_id"
        case prefix
        case isDeactivated = "is_deactivated"
        case openingBalance = "opening_balance"
        case bankAccount = "bank_account"
    }
}

extension Account {
    var isCashAccount: Bool { accountType == 1 }
}




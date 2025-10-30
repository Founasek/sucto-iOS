//
//  PayInvoiceResponse.swift
//  SuctoApp
//
//  Created by Jan Founě on 11.10.2025.
//

struct PayInvoiceResponse: Codable {
    let cashVoucherId: Int

    enum CodingKeys: String, CodingKey {
        case cashVoucherId = "cash_voucher_id"
    }
}

//
//  APIConstants.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import Foundation

enum APIConstants {
    static let baseURL = "https://www.sucto.cz/api/"
    static let loginEndpoint = "sessions/create"

    static func outgoingInvoiceMarkAsPaid(companyId: Int, invoiceId: Int) -> String {
        "companies/\(companyId)/actuarials_outs/\(invoiceId)/pay"
    }

    static func incomingInvoiceMarkAsPaid(companyId: Int, invoiceId: Int) -> String {
        "companies/\(companyId)/actuarials_ins/\(invoiceId)/pay"
    }

    static func GetOutgoingInvoiceDetail(companyId: Int, invoiceId: Int) -> String {
        "companies/\(companyId)/actuarials_outs/\(invoiceId)"
    }

    static func GetIncomingInvoiceDetail(companyId: Int, invoiceId: Int) -> String {
        "companies/\(companyId)/actuarials_ins/\(invoiceId)"
    }

    static func getNewOutgoingInvoice(companyId: Int) -> String {
        "companies/\(companyId)/actuarials_outs/new"
    }

    static func createOutgoingInvoice(companyId: Int) -> String {
        "companies/\(companyId)/actuarials_outs"
    }

    static func getPartners(companyId: Int) -> String {
        "companies/\(companyId)/partners?page=1&limit=9999"
    }

    static func GetVatRegimes(countryId: Int) -> String {
        "countries/\(countryId)/vat_regimes"
    }

    static func GetVats(countryId: Int) -> String {
        "countries/\(countryId)/vats"
    }

    static func getCurrencies() -> String {
        "currencies"
    }

    static func getCompanies() -> String {
        "companies"
    }

    static func getBankAccounts(companyId: Int) -> String {
        "companies/\(companyId)/accounts"
    }

    static func GetPaymentTypes(companyId: Int) -> String {
        "companies/\(companyId)/payment_types"
    }

    static let defaultTimeout: TimeInterval = 30
}

enum HeaderKeys {
    static let contentType = "Content-Type"
}

enum ContentTypes {
    static let formUrlEncoded = "application/x-www-form-urlencoded"
}

enum ErrorMessages {
    static let noData = "Server neposlal žádná data."
    static let decodingFailed = "Nepodařilo se zpracovat odpověď serveru."
    static let unknown = "Neznámá chyba."
}

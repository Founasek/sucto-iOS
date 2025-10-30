//
//  APIConstants.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//


import Foundation

struct APIConstants {
    static let baseURL = "https://www.sucto.cz/api/"
    static let loginEndpoint = "sessions/create"
    
    static func payInvoiceEndpoint(companyId: Int, invoiceId: Int) -> String {
        return "companies/\(companyId)/actuarials_outs/\(invoiceId)/pay"
    }
    
    static func GetOutgoingInvoiceDetail(companyId: Int, invoiceId: Int) -> String {
        return "companies/\(companyId)/actuarials_outs/\(invoiceId)"
    }
    
    static func getNewOutgoingInvoice(companyId: Int) -> String {
        return "companies/\(companyId)/actuarials_outs/new"
    }
    
    static func createOutgoingInvoice(companyId: Int) -> String {
        return "companies/\(companyId)/actuarials_outs"
    }
    
    static func getPartners(companyId: Int) -> String {
        return "companies/\(companyId)/partners?page=1&limit=9999"
    }

    static func GetVatRegimes(countryId: Int) -> String {
        return "countries/\(countryId)/vat_regimes"
    }

    static func GetVats(countryId: Int) -> String {
        return "countries/\(countryId)/vats"
    }

    static func getCurrencies() -> String {
        return "currencies"
    }
    
    static func getCompanies() -> String {
        return "companies"
    }
    
    static func getBankAccounts(companyId: Int) -> String {
        return "companies/\(companyId)/accounts"
    }

    static func GetPaymentTypes(companyId: Int) -> String {
        return "companies/\(companyId)/payment_types"
    }
    
    static let defaultTimeout: TimeInterval = 30
}

struct HeaderKeys {
    static let contentType = "Content-Type"
}

struct ContentTypes {
    static let formUrlEncoded = "application/x-www-form-urlencoded"
}

struct ErrorMessages {
    static let noData = "Server neposlal žádná data."
    static let decodingFailed = "Nepodařilo se zpracovat odpověď serveru."
    static let unknown = "Neznámá chyba."
}

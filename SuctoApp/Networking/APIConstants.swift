//
//  APIConstants.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import Foundation

enum APIConstants {
    static let baseURL = "https://www.sucto.cz/api/"
    static let defaultTimeout: TimeInterval = 30

    static let loginEndpoint = "sessions/create"

    static func outgoingInvoiceMarkAsPaid(companyId: Int, invoiceId: Int) -> String {
        "companies/\(companyId)/actuarials_outs/\(invoiceId)/pay"
    }

    static func outgoingInvoiceSendToEmail(companyId: Int, invoiceId: Int) -> String {
        "companies/\(companyId)/actuarials_outs/\(invoiceId)/send_to_email"
    }

    static func outgoingInvoiceDetail(companyId: Int, invoiceId: Int) -> String {
        "companies/\(companyId)/actuarials_outs/\(invoiceId)"
    }

    static func incomingInvoiceDetail(companyId: Int, invoiceId: Int) -> String {
        "companies/\(companyId)/actuarials_ins/\(invoiceId)"
    }

    static func newOutgoingInvoice(companyId: Int) -> String {
        "companies/\(companyId)/actuarials_outs/new"
    }

    static func newIncomingInvoice(companyId: Int) -> String {
        "companies/\(companyId)/actuarials_ins/new"
    }

    static func createIncomingInvoice(companyId: Int) -> String {
        "companies/\(companyId)/actuarials_ins"
    }

    static let actuarialTypes = "actuarial_types"

    static func scans(companyId: Int, page: Int = 1, limit: Int = 30) -> String {
        "companies/\(companyId)/scans?page=\(page)&limit=\(limit)"
    }

    static func createScan(companyId: Int) -> String {
        "companies/\(companyId)/scans"
    }

    /// `version`: thumb, hd nebo fullhd.
    static func scanData(companyId: Int, scanId: String, version: String = "thumb") -> String {
        "companies/\(companyId)/scans/\(scanId)/data?version=\(version)"
    }

    static func newIncomingInvoiceFromScan(companyId: Int, scanId: String) -> String {
        "companies/\(companyId)/actuarials_ins/new?scan_id=\(scanId)"
    }

    /// Účetní deník: skupiny Náklady / Výnosy / Hospodářský výsledek za rok (a případně měsíc).
    static func accountingDiaries(companyId: Int, year: Int, month: Int? = nil) -> String {
        var path = "companies/\(companyId)/accounting_diaries?q%5Byear_eq%5D=\(year)"
        if let month { path += "&q%5Bmonth_eq%5D=\(month)" }
        return path
    }

    static func createOutgoingInvoice(companyId: Int) -> String {
        "companies/\(companyId)/actuarials_outs"
    }

    /// Seznam partnerů; `query` hledá podle názvu, IČ, DIČ i adresy (dle API dokumentace).
    static func partners(companyId: Int, query: String = "", page: Int = 1, limit: Int = 50) -> String {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]
        if !query.isEmpty {
            components.queryItems?.append(
                URLQueryItem(name: "q[name_or_ic_or_dic_or_address_street_or_address_city_cont]", value: query),
            )
        }
        return "companies/\(companyId)/partners?\(components.percentEncodedQuery ?? "")"
    }

    static func partner(companyId: Int, partnerId: Int) -> String {
        "companies/\(companyId)/partners/\(partnerId)"
    }

    static func createPartner(companyId: Int) -> String {
        "companies/\(companyId)/partners"
    }

    static func createPartnerByAres(companyId: Int, ic: String) -> String {
        "companies/\(companyId)/partners/create_by_ares/\(ic)"
    }

    static func partnerChartYears(companyId: Int, partnerId: Int) -> String {
        "companies/\(companyId)/partners/\(partnerId)/partner_charts/available_years"
    }

    static func partnerChartSeries(companyId: Int, partnerId: Int, year: Int) -> String {
        "companies/\(companyId)/partners/\(partnerId)/partner_charts/series?year=\(year)"
    }

    static func dashboard(companyId: Int) -> String {
        "companies/\(companyId)/dashboard"
    }

    static let countries = "countries"

    static func vatRegimes(countryId: Int) -> String {
        "countries/\(countryId)/vat_regimes"
    }

    static func vats(countryId: Int) -> String {
        "countries/\(countryId)/vats"
    }

    static let currencies = "currencies"
    static let companies = "companies"

    static func bankAccounts(companyId: Int) -> String {
        "companies/\(companyId)/accounts"
    }

    static func paymentTypes(companyId: Int) -> String {
        "companies/\(companyId)/payment_types"
    }
}

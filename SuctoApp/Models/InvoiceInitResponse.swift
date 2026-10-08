//
//  InvoiceInitResponse.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import Foundation

/// Dodavatel načtený z naskenovaného dokladu.
struct InitSupplier: Decodable, Equatable {
    let name: String?
    let ic: String?
    let dic: String?

    enum CodingKeys: String, CodingKey { case name, ic, dic }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = container.lossyString(.name)
        ic = container.lossyString(.ic)
        dic = container.lossyString(.dic)
    }
}

struct InvoiceInitResponse: Decodable {
    /// U nové přijaté faktury je číslo `null` (zadává ho uživatel).
    let actuarialNumber: String?
    /// Číslo faktury od dodavatele (u dokladu ze skenu).
    let externalNumber: String?
    let variableSymbol: String?

    let issueDateAt: String?
    let dueDateAt: String?
    let uzpDateAt: String?

    let currency: Currency?
    let customer: Customer?
    let supplier: InitSupplier?
    let items: [InvoiceCreateLine]

    var issueDate: Date? {
        issueDateAt?.toDate()
    }

    var dueDate: Date? {
        dueDateAt?.toDate()
    }

    enum CodingKeys: String, CodingKey {
        case actuarialNumber = "actuarial_number",
             externalNumber = "external_number",
             variableSymbol = "variable_symbol",
             issueDateAt = "issue_date_at",
             dueDateAt = "due_date_at",
             uzpDateAt = "uzp_date_at",
             currency,
             customer,
             supplier,
             items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        actuarialNumber = container.lossyString(.actuarialNumber)
        externalNumber = container.lossyString(.externalNumber)
        variableSymbol = container.lossyString(.variableSymbol)
        issueDateAt = container.lossyString(.issueDateAt)
        dueDateAt = container.lossyString(.dueDateAt)
        uzpDateAt = container.lossyString(.uzpDateAt)
        currency = try? container.decodeIfPresent(Currency.self, forKey: .currency)
        customer = try? container.decodeIfPresent(Customer.self, forKey: .customer)
        supplier = try? container.decodeIfPresent(InitSupplier.self, forKey: .supplier)
        items = (try? container.decodeIfPresent([InvoiceCreateLine].self, forKey: .items)) ?? []
    }
}

extension String {
    private static let czechDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd. MM. yyyy"
        formatter.locale = Locale(identifier: "cs_CZ")
        return formatter
    }()

    /// Datum z odpovědi API ve tvaru „dd. MM. yyyy“.
    func toDate() -> Date? {
        Self.czechDateFormatter.date(from: self)
    }
}

struct InvoiceCreatedResponse: Decodable {
    let id: Int
}

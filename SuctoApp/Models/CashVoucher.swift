//
//  CashVoucher.swift
//  SuctoApp
//

import Foundation

/// Směr pokladního dokladu: `cash_vouchers_ins` = příjmové, `cash_vouchers_outs` = výdajové.
enum CashDirection: String, CaseIterable, Identifiable {
    case income = "cash_vouchers_ins"
    case expense = "cash_vouchers_outs"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .income: "Příjmové"
        case .expense: "Výdajové"
        }
    }

    /// Ikona v přepínači (stejný styl jako Vydané/Přijaté u faktur).
    var systemImage: String {
        switch self {
        case .income: "arrow.down.left.circle"
        case .expense: "arrow.up.right.circle"
        }
    }

    func list(companyId: Int, query: String, page: Int) -> String {
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "page", value: "\(page)")]
        let term = query.trimmingCharacters(in: .whitespaces)
        if !term.isEmpty {
            // Stejné pravidlo jako u faktur: text s číslicí = číslo dokladu, jinak jméno příjemce.
            let key = term.contains(where: \.isNumber) ? "q[number_cont]" : "q[partner_name_cont]"
            components.queryItems?.append(URLQueryItem(name: key, value: term))
        }
        return "companies/\(companyId)/\(rawValue)?\(components.percentEncodedQuery ?? "")"
    }

    func detail(companyId: Int, voucherId: Int) -> String {
        "companies/\(companyId)/\(rawValue)/\(voucherId)"
    }

    func sendToEmail(companyId: Int, voucherId: Int) -> String {
        detail(companyId: companyId, voucherId: voucherId) + "/send_to_email"
    }

    func sendToPartner(companyId: Int, voucherId: Int) -> String {
        detail(companyId: companyId, voucherId: voucherId) + "/send_to_partner"
    }
}

struct CashRecipient: Decodable, Equatable {
    let name: String?
    let street: String?
    let city: String?
    let zip: String?
    let country: String?
    let ic: String?
    let dic: String?

    private enum CodingKeys: String, CodingKey { case name, street, city, zip, country, ic, dic }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = container.lossyString(.name)
        street = container.lossyString(.street)
        city = container.lossyString(.city)
        zip = container.lossyString(.zip)
        country = container.lossyString(.country)
        ic = container.lossyString(.ic)
        dic = container.lossyString(.dic)
    }

    var addressLine: String? {
        let place = [zip, city].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " ")
        let parts = [street, place].compactMap(\.self).filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

/// Pokladní doklad (seznam vrací jen část polí, detail i `account` a položky).
/// Pole `status` ze serveru se záměrně nečte. V dokumentaci i v reálných datech (příjmový doklad zaplacené faktury)
/// má vždy hodnotu `{"storno": "Stornováno"}`, i když doklad stornovaný není – nejde tedy o jeho stav, nejspíš o nabídku
/// možné akce. Stav pokladního dokladu API spolehlivě nevrací.
struct CashVoucher: Identifiable, Decodable, Equatable {
    let id: Int
    let number: String
    let description: String?
    let totalPrice: String?
    let basePrice: String?
    let transactionDate: String?
    let recipient: CashRecipient?
    let externalNumber: String?
    let account: String?
    let items: [InvoiceItem]

    private enum CodingKeys: String, CodingKey {
        case id, number, description, recipient, account, items
        case totalPrice = "total_price"
        case basePrice = "base_price"
        case transactionDate = "transaction_date"
        case externalNumber = "external_number"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        number = container.lossyString(.number) ?? "—"
        description = container.lossyString(.description)
        totalPrice = container.lossyString(.totalPrice)
        basePrice = container.lossyString(.basePrice)
        transactionDate = container.lossyString(.transactionDate)
        recipient = try? container.decodeIfPresent(CashRecipient.self, forKey: .recipient)
        externalNumber = container.lossyString(.externalNumber)
        account = container.lossyString(.account)
        items = (try? container.decodeIfPresent([InvoiceItem].self, forKey: .items)) ?? []
    }
}

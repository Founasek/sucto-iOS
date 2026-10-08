//
//  AccountingOverview.swift
//  SuctoApp
//

import Foundation

/// Skupina z účetního deníku (Náklady / Výnosy / Hospodářský výsledek).
struct AccountingDiaryGroup: Decodable {
    let groupId: Int?
    let groupName: String?
    /// Naformátovaná částka z API, např. „12 345,67 Kč“.
    let total: String?

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case groupName = "group_name"
        case total
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groupId = try? container.decodeIfPresent(Int.self, forKey: .groupId)
        groupName = container.lossyString(.groupName)
        total = container.lossyString(.total)
    }
}

/// Odpověď `GET accounting_diaries` – nás zajímají jen součty skupin.
struct AccountingDiaryReport: Decodable {
    let groups: [AccountingDiaryGroup]

    enum Kind { case cost, revenue, result }

    /// Skupiny jsou podle dokumentace: 0 = Náklady, 1 = Výnosy, 2 = Hospodářský výsledek.
    func amount(_ kind: Kind) -> AccountingAmount? {
        let id: Int
        let name: String
        switch kind {
        case .cost: (id, name) = (0, "náklad")
        case .revenue: (id, name) = (1, "výnos")
        case .result: (id, name) = (2, "výsled")
        }
        let group = groups.first { $0.groupId == id }
            ?? groups.first { $0.groupName?.lowercased().contains(name) == true }
        return AccountingAmount.parse(group?.total)
    }
}

/// Částka z API (text s oddělovači a měnou) převedená na číslo.
struct AccountingAmount: Equatable {
    var value: Double
    var currency: String

    /// Např. „-12 345,67 Kč“ → (-12345.67, „Kč“). Neplatný vstup vrací `nil`.
    static func parse(_ text: String?) -> AccountingAmount? {
        guard let text, !text.isEmpty else { return nil }
        let numeric = text
            .replacingOccurrences(of: "\u{2212}", with: "-")
            .filter { "0123456789,.-".contains($0) }
        let normalized = numeric.contains(",")
            ? numeric.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            : numeric
        guard let value = Double(normalized) else { return nil }
        let currency = text.filter { $0.isLetter || $0 == "$" || $0 == "€" || $0 == "£" }
        return AccountingAmount(value: value, currency: currency)
    }
}

/// Jeden měsíc v přehledu.
struct MonthlyFigures: Identifiable, Equatable {
    let month: Int
    var revenue: Double
    var cost: Double
    var result: Double

    var id: Int { month }
}

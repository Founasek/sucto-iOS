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

/// Česká koruna je ve výpisech po měnách vždy první, ostatní měny podle počtu faktur / objemu.
func isCzechCrown(_ currency: String) -> Bool {
    currency == "Kč" || currency.uppercased() == "CZK"
}

/// Součty za celý rok (pro srovnání s minulým rokem).
struct YearTotals: Equatable {
    let revenue: Double
    let cost: Double

    var result: Double { revenue - cost }
}

/// Největší protistrana roku (odběratel u vydaných, dodavatel u přijatých faktur).
struct RankedParty: Identifiable, Equatable {
    let name: String
    let amount: Double
    var id: String { name }
}

/// Procentní změna oproti minulému roku; `nil`, pokud se nedá smysluplně spočítat (minulý rok nulový).
func percentChange(from previous: Double, to current: Double) -> Double? {
    guard previous != 0 else { return nil }
    return (current - previous) / abs(previous) * 100
}

/// Součty roku v jedné měně: měsíce, výnosy/vydané, náklady/přijaté a výsledek.
/// Měny se nepřepočítávají (API nemá kurzy), proto má každá měna vlastní sekci přehledu.
struct CurrencySection: Identifiable, Equatable {
    let currency: String
    let months: [MonthlyFigures]
    let revenue: Double
    let cost: Double
    let result: Double
    /// Počet faktur v této měně (u přehledu z faktur).
    let invoiceCount: Int
    /// Předchozí rok pro srovnání (`nil`, pokud se nepodařilo načíst nebo v něm nic nebylo).
    var previous: YearTotals?
    /// Největší odběratelé a dodavatelé (jen u přehledu z faktur).
    var topCustomers: [RankedParty] = []
    var topSuppliers: [RankedParty] = []

    var id: String { currency }
    var hasData: Bool { revenue != 0 || cost != 0 || months.contains { $0.revenue != 0 || $0.cost != 0 } }

    /// Měsíce doplněné nulami na celých 12, ať má osa grafu vždy všechny měsíce.
    static func padded(_ figures: [MonthlyFigures]) -> [MonthlyFigures] {
        var all = figures
        for month in 1 ... 12 where !all.contains(where: { $0.month == month }) {
            all.append(MonthlyFigures(month: month, revenue: 0, cost: 0, result: 0))
        }
        return all.sorted { $0.month < $1.month }
    }
}

/// Průběh prvního načtení přehledu (pro úvodní načítací stránku).
struct OverviewLoadProgress: Equatable {
    enum StepState: Equatable {
        case pending, active, done
    }

    var connecting = StepState.active
    var issued = StepState.pending
    var received = StepState.pending
    var preparing = StepState.pending
    var issuedCount = 0
    var receivedCount = 0

    /// Podíl dokončených kroků (0…1) pro ukazatel průběhu; rozpracovaný krok se počítá za půl.
    var fraction: Double {
        let states = [connecting, issued, received, preparing]
        let value = states.reduce(0.0) { sum, state in
            sum + (state == .done ? 1 : (state == .active ? 0.5 : 0))
        }
        return value / Double(states.count)
    }

    /// Všechno hotovo (účetní deník se načetl bez dalších kroků).
    mutating func finishAll() {
        connecting = .done
        issued = .done
        received = .done
        preparing = .done
    }
}

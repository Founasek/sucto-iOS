//
//  OverviewViewModel+Invoices.swift
//  SuctoApp
//

import Foundation

extension OverviewViewModel {
    // MARK: - Záložní zdroj: faktury

    func loadInvoices(year: Int, generation myGeneration: Int) async throws {
        async let issued = listInvoices(base: "actuarials_outs", year: year) { [weak self] count in
            self?.progress.issuedCount = count
        }
        async let received = listInvoices(base: "actuarials_ins", year: year) { [weak self] count in
            self?.progress.receivedCount = count
        }
        let issuedList = try await issued
        progress.issued = .done
        let receivedList = try await received
        progress.received = .done
        progress.preparing = .active
        guard myGeneration == generation else { return }

        // Měny se nepřepočítávají (API nemá kurzy) – každá měna dostane vlastní sekci, všechny se ukážou najednou.
        let all = issuedList + receivedList
        func code(_ invoice: Invoice) -> String { invoice.currency?.symbol ?? "Kč" }
        let counts = Dictionary(grouping: all, by: code).mapValues(\.count)

        func monthly(_ invoices: [Invoice], currency: String) -> [Int: Double] {
            var sums: [Int: Double] = [:]
            for invoice in invoices where code(invoice) == currency {
                guard let date = invoice.issueDateAt?.toDate(), let base = invoice.basePrice.flatMap(Double.init) else { continue }
                sums[Calendar.current.component(.month, from: date), default: 0] += base
            }
            return sums
        }

        let ordered: [(key: String, value: Int)] = counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
        }
        sections = ordered.compactMap { currency, count in
            let revenue = monthly(issuedList, currency: currency)
            let cost = monthly(receivedList, currency: currency)
            let months = (1 ... 12).map { month in
                let r = revenue[month] ?? 0
                let c = cost[month] ?? 0
                return MonthlyFigures(month: month, revenue: r, cost: c, result: r - c)
            }
            let revenueTotal = months.reduce(0) { $0 + $1.revenue }
            let costTotal = months.reduce(0) { $0 + $1.cost }
            var section = CurrencySection(
                currency: currency, months: months, revenue: revenueTotal, cost: costTotal,
                result: revenueTotal - costTotal, invoiceCount: count,
            )
            section.topCustomers = Self.ranking(issuedList, currency: currency, code: code) { $0.customer?.name }
            section.topSuppliers = Self.ranking(receivedList, currency: currency, code: code) { $0.supplier?.name }
            return section.hasData ? section : nil
        }
        source = .invoices
        isEmpty = sections.isEmpty
        errorMessage = nil
        progress.preparing = .done

        // Srovnání s minulým rokem se dočítá až po zobrazení přehledu – nezdržuje první obrazovku.
        Task { await loadPreviousYear(year: year, generation: myGeneration) }
    }

    /// Doplní do už zobrazených sekcí součty minulého roku. Při chybě nebo změně roku se prostě neukáže.
    func loadPreviousYear(year: Int, generation myGeneration: Int) async {
        async let issued: [Invoice]? = try? listInvoices(base: "actuarials_outs", year: year - 1)
        async let received: [Invoice]? = try? listInvoices(base: "actuarials_ins", year: year - 1)
        let (previousIssued, previousReceived) = await (issued, received)
        guard myGeneration == generation, source == .invoices,
              let previousIssued, let previousReceived
        else { return }

        func code(_ invoice: Invoice) -> String { invoice.currency?.symbol ?? "Kč" }
        sections = sections.map { section in
            var section = section
            let totals = YearTotals(
                revenue: Self.baseSum(previousIssued, currency: section.currency, code: code),
                cost: Self.baseSum(previousReceived, currency: section.currency, code: code),
            )
            section.previous = totals.revenue != 0 || totals.cost != 0 ? totals : nil
            return section
        }
    }

    static func baseSum(_ invoices: [Invoice], currency: String, code: (Invoice) -> String) -> Double {
        invoices.filter { code($0) == currency }.reduce(0) { $0 + ($1.basePrice.flatMap(Double.init) ?? 0) }
    }

    /// Nejvyšší součty základu podle protistrany (v dané měně), nejvýše pět.
    static func ranking(
        _ invoices: [Invoice],
        currency: String,
        code: (Invoice) -> String,
        name: (Invoice) -> String?,
    ) -> [RankedParty] {
        var sums: [String: Double] = [:]
        for invoice in invoices where code(invoice) == currency {
            let key = name(invoice).flatMap { $0.isEmpty ? nil : $0 } ?? "Neuvedeno"
            sums[key, default: 0] += invoice.basePrice.flatMap(Double.init) ?? 0
        }
        var parties: [RankedParty] = []
        for (name, amount) in sums where amount != 0 {
            parties.append(RankedParty(name: name, amount: amount))
        }
        parties.sort { lhs, rhs in
            lhs.amount == rhs.amount ? lhs.name < rhs.name : lhs.amount > rhs.amount
        }
        return Array(parties.prefix(5))
    }

    /// Všechny faktury vystavené v daném roce (bez konceptů a stornovaných). Stránky se stahují po čtveřicích
    /// současně – počet stránek dopředu neznáme, takže se končí první prázdnou stránkou.
    func listInvoices(
        base: String,
        year: Int,
        onProgress: (@MainActor (Int) -> Void)? = nil,
    ) async throws -> [Invoice] {
        var all: [Invoice] = []
        var seen = Set<Int>()
        var firstPage = 1

        while firstPage <= maximumPages {
            let pages = Array(firstPage ..< min(firstPage + concurrentPages, maximumPages + 1))
            let results = try await fetchPages(pages, base: base, year: year)
            var reachedEnd = false
            for page in pages {
                let fresh = (results[page] ?? []).filter { seen.insert($0.id).inserted }
                if fresh.isEmpty {
                    reachedEnd = true
                    break
                }
                all += fresh
            }
            onProgress?(all.count)
            if reachedEnd { break }
            firstPage += concurrentPages
        }
        return all.filter { $0.invoiceStatus != .concept && $0.invoiceStatus != .storno }
    }

    func fetchPages(_ pages: [Int], base: String, year: Int) async throws -> [Int: [Invoice]] {
        try await withThrowingTaskGroup(of: (Int, [Invoice]).self) { group in
            for page in pages {
                group.addTask { @MainActor in
                    var components = URLComponents()
                    components.queryItems = [
                        URLQueryItem(name: "page", value: "\(page)"),
                        URLQueryItem(name: "q[issue_date_at_gteq]", value: "\(year)-01-01"),
                        URLQueryItem(name: "q[issue_date_at_lteq]", value: "\(year)-12-31"),
                    ]
                    let path = "companies/\(self.companyId)/\(base)?\(components.percentEncodedQuery ?? "")"
                    let result: [Invoice] = try await self.session.send(path)
                    return (page, result)
                }
            }
            var collected: [Int: [Invoice]] = [:]
            for try await (page, invoices) in group {
                collected[page] = invoices
            }
            return collected
        }
    }
}

//
//  OverviewViewModel.swift
//  SuctoApp
//

import SwiftUI

@MainActor
final class OverviewViewModel: ObservableObject {
    /// Odkud přehled vychází.
    enum Source {
        /// Účetní deník (výnosy, náklady, hospodářský výsledek).
        case accounting
        /// Záložní zdroj, když server účetní deník nepustí (403): součty vystavených a přijatých faktur.
        case invoices
    }

    @Published var year: Int {
        didSet { if year != oldValue { Task { await load() } } }
    }

    @Published private(set) var months: [MonthlyFigures] = []
    @Published private(set) var yearRevenue = 0.0
    @Published private(set) var yearCost = 0.0
    @Published private(set) var yearResult = 0.0
    @Published private(set) var currency = "Kč"
    @Published private(set) var source = Source.accounting
    /// Počet faktur v jiné měně, které se do součtů nezapočítaly (jen u zdroje `invoices`).
    @Published private(set) var skippedForeignCount = 0
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// `true`, pokud server za zvolený rok nevrátil žádné nenulové údaje.
    @Published private(set) var isEmpty = false
    /// Zpráva ze sÚčta (dashboard API), dokud ji uživatel nezavře.
    @Published private(set) var notice: SystemNotice?

    let companyId: Int
    private let session: SessionManager
    private let concurrentRequests = 4
    private let maximumPages = 100
    private var generation = 0
    /// Server už jednou účetní deník odmítl – příště se rovnou použijí faktury (pull-to-refresh to zkusí znovu).
    private var accountingKnownForbidden = false

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
        year = Calendar.current.component(.year, from: Date())
    }

    /// Roky nabízené ve výběru (aktuální a pět předchozích).
    var availableYears: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 5 ... current).reversed())
    }

    /// Zprávy ze sÚčta jsou jen doplněk – jejich selhání se tiše ignoruje.
    func loadNotice() async {
        guard let response: DashboardResponse = try? await session.send(APIConstants.dashboard(companyId: companyId)) else { return }
        notice = response.notices.first { !SystemNoticeStore.isDismissed($0.id) }
    }

    func dismissNotice() {
        guard let notice else { return }
        SystemNoticeStore.dismiss(notice.id)
        withAnimation(.snappy) { self.notice = nil }
    }

    func load(retryAccounting: Bool = false) async {
        generation += 1
        let myGeneration = generation
        isLoading = true
        defer { if myGeneration == generation { isLoading = false } }

        let selectedYear = year
        do {
            if accountingKnownForbidden, !retryAccounting { throw APIError.forbidden(message: nil) }
            try await loadAccounting(year: selectedYear, generation: myGeneration)
            accountingKnownForbidden = false
        } catch is CancellationError {
            return
        } catch APIError.forbidden {
            // Účetní deník server pro tento token nepustil – zkusíme přehled z faktur.
            if !accountingKnownForbidden {
                Log.debug("🚫 Účetní deník vrací 403, přepínám na přehled z faktur")
                await probePermissions()
            }
            accountingKnownForbidden = true
            do {
                try await loadInvoices(year: selectedYear, generation: myGeneration)
            } catch is CancellationError {
                return
            } catch {
                guard myGeneration == generation else { return }
                errorMessage = error.localizedDescription
            }
        } catch {
            guard myGeneration == generation else { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Účetní deník

    private func loadAccounting(year: Int, generation myGeneration: Int) async throws {
        let lastMonth = lastMonthToLoad(for: year)
        async let annual: AccountingDiaryReport = session.send(
            APIConstants.accountingDiaries(companyId: companyId, year: year),
        )
        let monthly = try await loadMonths(1 ... lastMonth, year: year)
        let annualReport = try await annual
        guard myGeneration == generation else { return }

        apply(months: monthly)
        yearRevenue = annualReport.amount(.revenue)?.value ?? 0
        yearCost = annualReport.amount(.cost)?.value ?? 0
        yearResult = annualReport.amount(.result)?.value ?? (yearRevenue - yearCost)
        currency = annualReport.amount(.revenue)?.currency ?? annualReport.amount(.cost)?.currency ?? currency
        source = .accounting
        skippedForeignCount = 0
        isEmpty = yearRevenue == 0 && yearCost == 0 && months.allSatisfy { $0.revenue == 0 && $0.cost == 0 }
        errorMessage = nil
    }

    private func lastMonthToLoad(for year: Int) -> Int {
        let now = Date()
        return year == Calendar.current.component(.year, from: now) ? Calendar.current.component(.month, from: now) : 12
    }

    private func loadMonths(_ range: ClosedRange<Int>, year: Int) async throws -> [MonthlyFigures] {
        var results: [MonthlyFigures] = []
        var iterator = range.makeIterator()

        try await withThrowingTaskGroup(of: MonthlyFigures.self) { group in
            func addNext() {
                guard let month = iterator.next() else { return }
                group.addTask { @MainActor in
                    let report: AccountingDiaryReport = try await self.session.send(
                        APIConstants.accountingDiaries(companyId: self.companyId, year: year, month: month),
                    )
                    let revenue = report.amount(.revenue)?.value ?? 0
                    let cost = report.amount(.cost)?.value ?? 0
                    let result = report.amount(.result)?.value ?? (revenue - cost)
                    return MonthlyFigures(month: month, revenue: revenue, cost: cost, result: result)
                }
            }

            for _ in 0 ..< concurrentRequests {
                addNext()
            }
            while let figures = try await group.next() {
                results.append(figures)
                addNext()
            }
        }
        return results
    }

    // MARK: - Záložní zdroj: faktury

    private func loadInvoices(year: Int, generation myGeneration: Int) async throws {
        async let issued = listInvoices(base: "actuarials_outs", year: year)
        async let received = listInvoices(base: "actuarials_ins", year: year)
        let (issuedList, receivedList) = try await (issued, received)
        guard myGeneration == generation else { return }

        // Do součtů jdou jen faktury ve hlavní měně (nejčastější); ostatní se spočítají a ohlásí.
        let all = issuedList + receivedList
        let counts = Dictionary(grouping: all, by: { $0.currency?.symbol ?? "Kč" }).mapValues(\.count)
        let main = counts.max { $0.value < $1.value }?.key ?? "Kč"

        func monthly(_ invoices: [Invoice]) -> [Int: Double] {
            var sums: [Int: Double] = [:]
            for invoice in invoices where (invoice.currency?.symbol ?? "Kč") == main {
                guard let date = invoice.issueDateAt?.toDate(), let base = invoice.basePrice.flatMap(Double.init) else { continue }
                sums[Calendar.current.component(.month, from: date), default: 0] += base
            }
            return sums
        }
        let revenue = monthly(issuedList)
        let cost = monthly(receivedList)

        apply(months: (1 ... 12).map { month in
            let r = revenue[month] ?? 0
            let c = cost[month] ?? 0
            return MonthlyFigures(month: month, revenue: r, cost: c, result: r - c)
        })
        yearRevenue = months.reduce(0) { $0 + $1.revenue }
        yearCost = months.reduce(0) { $0 + $1.cost }
        yearResult = yearRevenue - yearCost
        currency = main
        source = .invoices
        skippedForeignCount = all.count(where: { ($0.currency?.symbol ?? "Kč") != main })
        isEmpty = yearRevenue == 0 && yearCost == 0
        errorMessage = nil
    }

    /// Všechny faktury vystavené v daném roce (bez konceptů a stornovaných).
    private func listInvoices(base: String, year: Int) async throws -> [Invoice] {
        var all: [Invoice] = []
        var seen = Set<Int>()
        for page in 1 ... maximumPages {
            var components = URLComponents()
            components.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "q[issue_date_at_gteq]", value: "\(year)-01-01"),
                URLQueryItem(name: "q[issue_date_at_lteq]", value: "\(year)-12-31"),
            ]
            let path = "companies/\(companyId)/\(base)?\(components.percentEncodedQuery ?? "")"
            let result: [Invoice] = try await session.send(path)
            let fresh = result.filter { seen.insert($0.id).inserted }
            if fresh.isEmpty { break }
            all += fresh
        }
        return all.filter { $0.invoiceStatus != .concept && $0.invoiceStatus != .storno }
    }

    // MARK: - Společné

    /// Doplní chybějící měsíce nulami, ať má osa x vždy 12 měsíců.
    private func apply(months figures: [MonthlyFigures]) {
        var all = figures
        for month in 1 ... 12 where !all.contains(where: { $0.month == month }) {
            all.append(MonthlyFigures(month: month, revenue: 0, cost: 0, result: 0))
        }
        months = all.sorted { $0.month < $1.month }
    }

    /// Jen pro ladění: zjistí, co server pro tento účet povoluje (výsledek jde do konzole).
    private func probePermissions() async {
        #if DEBUG
            struct Ability: Decodable { let read: Bool? }
            let navigation: [String]? = try? await session.send("companies/\(companyId)/api_permissions/navigation")
            Log.debug("🔐 Zdroje s právem čtení: \(navigation?.joined(separator: ", ") ?? "nelze zjistit")")
            let ability: Ability? = try? await session.send("companies/\(companyId)/api_permissions?resource=AccountingDiary")
            Log.debug("🔐 AccountingDiary read: \(ability?.read.map(String.init) ?? "nelze zjistit")")
        #endif
    }
}

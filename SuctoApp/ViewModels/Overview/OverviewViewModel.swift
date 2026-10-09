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

    /// Sekce po měnách (u účetního deníku jedna, u přehledu z faktur jedna na každou měnu, nejpoužívanější první).
    @Published var sections: [CurrencySection] = []
    @Published var source = Source.accounting
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    /// `true`, pokud server za zvolený rok nevrátil žádné nenulové údaje.
    @Published var isEmpty = false
    /// Poslední zpráva ze sÚčta (dashboard API); zobrazuje se na vyžádání.
    @Published private(set) var notice: SystemNotice?
    @Published private(set) var isNoticeUnread = false
    /// Průběh načítání pro úvodní obrazovku (kroky a počty načtených faktur).
    @Published var progress = OverviewLoadProgress()
    /// Stáří prošlých pohledávek a závazků (nezávisí na zvoleném roce).
    @Published private(set) var aging = AgingSummary(items: [])
    /// Prognóza splatností na 30 dní (ze stejných dat jako stáří po splatnosti).
    @Published private(set) var forecast = ForecastSummary(items: [])

    let companyId: Int
    let session: SessionManager
    let concurrentRequests = 4
    let maximumPages = 100
    /// Kolik stránek seznamu faktur se stahuje současně.
    let concurrentPages = 4
    var generation = 0
    /// Server už jednou účetní deník odmítl – příště se rovnou použijí faktury (pull-to-refresh to zkusí znovu).
    /// Pamatuje se i mezi spuštěními, ať se při každém otevření firmy nečeká na zbytečný dotaz, který skončí 403.
    private var accountingKnownForbidden: Bool {
        get { UserDefaults.standard.bool(forKey: "overview.accountingForbidden.\(companyId)") }
        set { UserDefaults.standard.set(newValue, forKey: "overview.accountingForbidden.\(companyId)") }
    }

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
        notice = response.notices.first
        isNoticeUnread = notice.map { !SystemNoticeStore.isDismissed($0.id) } ?? false
    }

    /// Načte nezaplacené faktury a spočítá z nich stáří po splatnosti a prognózu na 30 dní.
    /// Jen doplněk – při chybě nebo výpadku zůstane předchozí stav.
    func loadDueItems() async {
        guard let items = try? await DueSnapshotService(session: session).fetchItems(companyId: companyId),
              session.cachedDataDate == nil
        else { return }
        aging = AgingSummary(items: items)
        forecast = ForecastSummary(items: items)
    }

    /// Zpráva se ukazuje jen na vyžádání; po otevření se označí jako přečtená (zmizí tečka u tlačítka).
    func markNoticeRead() {
        guard let notice else { return }
        SystemNoticeStore.dismiss(notice.id)
        isNoticeUnread = false
    }

    func load(retryAccounting: Bool = false) async {
        generation += 1
        let myGeneration = generation
        isLoading = true
        defer { if myGeneration == generation { isLoading = false } }
        progress = OverviewLoadProgress()

        let selectedYear = year
        do {
            if accountingKnownForbidden, !retryAccounting { throw APIError.forbidden(message: nil) }
            try await loadAccounting(year: selectedYear, generation: myGeneration)
            accountingKnownForbidden = false
            progress.finishAll()
        } catch is CancellationError {
            return
        } catch APIError.forbidden {
            // Účetní deník server pro tento token nepustil – zkusíme přehled z faktur.
            if !accountingKnownForbidden {
                Log.debug("🚫 Účetní deník vrací 403, přepínám na přehled z faktur")
                await probePermissions()
            }
            accountingKnownForbidden = true
            progress.connecting = .done
            progress.issued = .active
            progress.received = .active
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

        let revenue = annualReport.amount(.revenue)
        let cost = annualReport.amount(.cost)
        let revenueTotal = revenue?.value ?? 0
        let costTotal = cost?.value ?? 0
        let result = annualReport.amount(.result)?.value ?? (revenueTotal - costTotal)
        // Minulý rok je jen doplněk srovnání – při chybě se prostě neukáže.
        let previousReport: AccountingDiaryReport? = try? await session.send(
            APIConstants.accountingDiaries(companyId: companyId, year: year - 1),
        )
        let previousTotals = previousReport.map {
            YearTotals(revenue: $0.amount(.revenue)?.value ?? 0, cost: $0.amount(.cost)?.value ?? 0)
        }
        let section = CurrencySection(
            currency: revenue?.currency ?? cost?.currency ?? "Kč",
            months: CurrencySection.padded(monthly),
            revenue: revenueTotal,
            cost: costTotal,
            result: result,
            invoiceCount: 0,
            previous: previousTotals.flatMap { $0.revenue != 0 || $0.cost != 0 ? $0 : nil },
        )
        sections = section.hasData ? [section] : []
        source = .accounting
        isEmpty = sections.isEmpty
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

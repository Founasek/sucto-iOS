//
//  PartnerDetailViewModel.swift
//  SuctoApp
//

import SwiftUI

@MainActor
final class PartnerDetailViewModel: ObservableObject {
    @Published private(set) var partner: PartnerRecord?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    @Published private(set) var years: [Int] = []
    @Published private(set) var year: Int?
    @Published private(set) var series: [PartnerSeries] = []
    @Published var alertMessage: String?
    @Published private(set) var isDeleting = false

    let companyId: Int
    let partnerId: Int
    private let session: SessionManager

    init(companyId: Int, partnerId: Int, session: SessionManager) {
        self.companyId = companyId
        self.partnerId = partnerId
        self.session = session
    }

    func load() async {
        isLoading = partner == nil
        defer { isLoading = false }
        do {
            partner = try await session.send(APIConstants.partner(companyId: companyId, partnerId: partnerId))
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        await loadCharts()
    }

    /// Grafy jsou jen doplněk – jejich selhání nesmí zakrýt detail partnera.
    /// Roky z API obsahují jen roky s doklady; aktuální rok se přidá, aby šel vybrat i když je zatím prázdný.
    private func loadCharts() async {
        do {
            let available: [Int] = try await session.send(
                APIConstants.partnerChartYears(companyId: companyId, partnerId: partnerId),
            )
            let current = Calendar.current.component(.year, from: Date())
            years = Array(Set(available + [current])).sorted()
        } catch is CancellationError {
            return
        } catch {
            years = []
            series = []
            return
        }

        if let year, years.contains(year) {
            await select(year: year)
            return
        }
        // Výchozí rok: nejnovější, ve kterém jsou nějaká data (letošek bývá na začátku roku prázdný).
        for candidate in years.reversed().prefix(4) {
            await select(year: candidate)
            if hasData { return }
        }
        if let latest = years.last { await select(year: latest) }
    }

    /// Alespoň jedna řada má nenulovou hodnotu.
    var hasData: Bool { series.contains { $0.total != 0 } }

    func select(year: Int) async {
        self.year = year
        do {
            let loaded: [PartnerSeries] = try await session.send(
                APIConstants.partnerChartSeries(companyId: companyId, partnerId: partnerId, year: year),
            )
            guard self.year == year else { return }
            series = loaded
        } catch is CancellationError {
            return
        } catch {
            guard self.year == year else { return }
            series = []
        }
    }

    /// Po úpravě ve formuláři.
    func didSave(_ updated: PartnerRecord) {
        partner = updated
        NotificationCenter.default.post(name: PartnerEvent.notification, object: PartnerEvent.saved(updated))
    }

    /// Smaže partnera. Vrací `true` při úspěchu; chyba (např. partner má doklady) je v `alertMessage`.
    func delete() async -> Bool {
        isDeleting = true
        defer { isDeleting = false }
        do {
            let _: EmptyResponse = try await session.send(
                APIConstants.partner(companyId: companyId, partnerId: partnerId),
                method: .DELETE,
            )
            NotificationCenter.default.post(name: PartnerEvent.notification, object: PartnerEvent.deleted(id: partnerId))
            return true
        } catch is CancellationError {
            return false
        } catch {
            alertMessage = error.localizedDescription
            return false
        }
    }
}

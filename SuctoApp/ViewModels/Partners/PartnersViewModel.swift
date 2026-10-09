//
//  PartnersViewModel.swift
//  SuctoApp
//

import SwiftUI

@MainActor
final class PartnersViewModel: ObservableObject {
    @Published private(set) var partners: [PartnerRecord] = []
    @Published var searchText = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// Chyba akce (např. vytvoření z ARES) zobrazená v alertu.
    @Published var alertMessage: String?
    @Published private(set) var isCreatingFromAres = false

    let companyId: Int
    private let session: SessionManager
    private let pageSize = 100
    private let maximumPages = 30
    /// Zvyšuje se při každém novém načtení; odpovědi starší generace se zahodí.
    private var generation = 0
    private var searchTask: Task<Void, Never>?

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    func searchTextChanged() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    /// Načte všechny partnery (server nemá zdokumentované řazení) a seřadí je podle názvu A–Z.
    /// Stránkování by při řazení na klientovi řadilo jen to, co je zrovna načtené, a později načtení by skákali do středu seznamu.
    func refresh() async {
        generation += 1
        let myGeneration = generation
        isLoading = true
        defer { if myGeneration == generation { isLoading = false } }

        let term = searchText.trimmingCharacters(in: .whitespaces)
        var collected: [PartnerRecord] = []
        var seen = Set<Int>()
        do {
            for page in 1 ... maximumPages {
                let result: [PartnerRecord] = try await session.send(
                    APIConstants.partners(companyId: companyId, query: term, page: page, limit: pageSize),
                )
                guard myGeneration == generation else { return }
                let fresh = result.filter { seen.insert($0.id).inserted }
                if fresh.isEmpty { break }
                collected += fresh
            }
            partners = Self.sorted(collected)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard myGeneration == generation else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Abecedně podle názvu, bez ohledu na velikost písmen a s českým řazením (např. „Č“ za „C“).
    static func sorted(_ partners: [PartnerRecord]) -> [PartnerRecord] {
        let locale = Locale(identifier: "cs_CZ")
        return partners.sorted { lhs, rhs in
            let order = lhs.name.compare(rhs.name, options: [.caseInsensitive, .diacriticInsensitive], range: nil, locale: locale)
            if order == .orderedSame { return lhs.id < rhs.id }
            return order == .orderedAscending
        }
    }

    /// Přidá nového nebo nahradí upraveného partnera v už načteném seznamu.
    func apply(_ event: PartnerEvent) {
        switch event {
        case let .saved(partner):
            if let index = partners.firstIndex(where: { $0.id == partner.id }) {
                partners[index] = partner
                partners = Self.sorted(partners)
            } else if !isSearching {
                partners = Self.sorted(partners + [partner])
            }
        case let .deleted(id):
            partners.removeAll { $0.id == id }
        }
    }

    /// Vytvoří partnera podle IČO z ARES. Vrací vytvořeného partnera, nebo `nil` (chyba je v `alertMessage`).
    func createFromAres(ic: String) async -> PartnerRecord? {
        let digits = ic.filter(\.isNumber)
        guard digits.count == 8 else {
            alertMessage = "IČO má mít 8 číslic."
            return nil
        }
        isCreatingFromAres = true
        defer { isCreatingFromAres = false }
        do {
            let partner: PartnerRecord = try await session.send(
                APIConstants.createPartnerByAres(companyId: companyId, ic: digits),
                method: .POST,
                body: Data("{}".utf8),
            )
            apply(.saved(partner))
            return partner
        } catch is CancellationError {
            return nil
        } catch APIError.badRequest {
            // Server vrací jen název neplatného pole (`["ic"]`) – zpráva by uživateli nic neřekla.
            alertMessage = "Partnera se z ARES nepodařilo vytvořit. Zkontrolujte IČO, případně partner už může existovat."
            return nil
        } catch {
            alertMessage = error.localizedDescription
            return nil
        }
    }
}

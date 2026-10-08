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
    @Published private(set) var hasMorePages = true
    @Published private(set) var errorMessage: String?
    /// Chyba akce (např. vytvoření z ARES) zobrazená v alertu.
    @Published var alertMessage: String?
    @Published private(set) var isCreatingFromAres = false

    let companyId: Int
    private let session: SessionManager
    private let pageSize = 30
    private var currentPage = 1
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

    func refresh() async {
        generation += 1
        currentPage = 1
        hasMorePages = true
        isLoading = false
        await fetchNextPage()
    }

    func fetchNextPage() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        let myGeneration = generation
        defer { if myGeneration == generation { isLoading = false } }

        let page = currentPage
        let term = searchText.trimmingCharacters(in: .whitespaces)
        do {
            let result: [PartnerRecord] = try await session.send(
                APIConstants.partners(companyId: companyId, query: term, page: page, limit: pageSize),
            )
            guard myGeneration == generation else { return }
            currentPage = page + 1
            hasMorePages = !result.isEmpty
            if page == 1 {
                partners = result
            } else {
                let known = Set(partners.map(\.id))
                partners += result.filter { !known.contains($0.id) }
            }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard myGeneration == generation else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Přidá nového nebo nahradí upraveného partnera v už načteném seznamu.
    func apply(_ event: PartnerEvent) {
        switch event {
        case let .saved(partner):
            if let index = partners.firstIndex(where: { $0.id == partner.id }) {
                partners[index] = partner
            } else if !isSearching {
                partners.insert(partner, at: 0)
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

//
//  PagedInvoicesViewModel.swift
//  SuctoApp
//

import SwiftUI

/// Společný základ seznamů faktur: stránkování, hledání a filtry. Potomek dodá endpoint.
@MainActor
class PagedInvoicesViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var selectedInvoice: Invoice?

    /// Chyba načtení seznamu.
    @Published var errorMessage: String?
    /// Chyba načtení detailu (oddělená od seznamu, aby se nepřenášela mezi obrazovkami).
    @Published var detailErrorMessage: String?

    @Published var isLoadingPage = false
    @Published var isLoadingDetail = false
    @Published var hasMorePages = true

    @Published var searchText = ""
    @Published var filter: InvoiceFilter = .all {
        didSet {
            guard filter != oldValue else { return }
            // Rychlé filtry „Zaplacené“ a „Koncepty“ nastavují stav – nesmí se bít se stavem ze sheetu.
            if filter == .paid || filter == .concept, advanced.status != nil { advanced.status = nil }
            Task { await refresh() }
        }
    }

    @Published var advanced = InvoiceAdvancedFilter() {
        didSet {
            guard advanced != oldValue else { return }
            if advanced.status != nil, filter == .paid || filter == .concept { filter = .all }
            Task { await refresh() }
        }
    }

    let companyId: Int
    let session: SessionManager
    /// Vydané × přijaté: určuje, na který zdroj (`actuarials_outs` / `actuarials_ins`) se seznam, detail i řádky ptají.
    let direction: InvoiceDirection

    private var currentPage = 1
    /// Zvyšuje se při každém novém načtení; odpovědi starší generace se zahodí.
    private var generation = 0
    private var searchTask: Task<Void, Never>?

    /// Kolik shod chceme mít po jednom načtení (u filtru „Po splatnosti“ se dotahuje víc stránek).
    private let minimumMatches = 10
    private let maximumPagesPerLoad = 5

    init(companyId: Int, session: SessionManager, direction: InvoiceDirection) {
        self.companyId = companyId
        self.session = session
        self.direction = direction
    }

    var resourcePath: String {
        "companies/\(companyId)/" + (direction == .outgoing ? "actuarials_outs" : "actuarials_ins")
    }

    /// Endpoint seznamu pro danou stránku a dotaz.
    func listEndpoint(page: Int, query: InvoiceQuery) -> String {
        query.path(resourcePath, page: page)
    }

    var query: InvoiceQuery {
        InvoiceQuery(search: searchText, filter: filter, advanced: advanced)
    }

    var isFiltering: Bool { query.isActive }

    func clearFilters() {
        searchText = ""
        filter = .all
        advanced = InvoiceAdvancedFilter()
    }

    /// Voláno při psaní do hledání – dotaz se pošle až po krátké pauze.
    func searchTextChanged() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    /// Načte první stránku znovu (pull-to-refresh, změna filtru, návrat na obrazovku).
    func refresh() async {
        generation += 1
        currentPage = 1
        hasMorePages = true
        isLoadingPage = false
        await fetchNextPage()
    }

    func fetchNextPage() async {
        guard !isLoadingPage, hasMorePages else { return }
        isLoadingPage = true
        let myGeneration = generation
        defer { if myGeneration == generation { isLoadingPage = false } }

        let query = query
        let startPage = currentPage
        var collected: [Invoice] = []
        var pagesLoaded = 0

        do {
            while pagesLoaded < maximumPagesPerLoad {
                let page = currentPage
                let result: [Invoice] = try await session.send(listEndpoint(page: page, query: query))
                guard myGeneration == generation else { return }

                pagesLoaded += 1
                currentPage = page + 1
                hasMorePages = !result.isEmpty
                collected += query.filter == .overdue ? result.filter(\.isOverdue) : result

                if !hasMorePages || collected.count >= minimumMatches { break }
            }

            if startPage == 1 {
                invoices = collected
            } else {
                invoices.append(contentsOf: collected)
            }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard myGeneration == generation else { return }
            errorMessage = error.localizedDescription
        }
    }
}

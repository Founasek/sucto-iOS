//
//  PagedInvoicesViewModel+Export.swift
//  SuctoApp
//

import Foundation

/// Načtení všech faktur odpovídajících filtrům (pro export).
extension PagedInvoicesViewModel {
    /// Všechny faktury odpovídající aktuálnímu hledání a filtrům (pro export) – stránky se čtou, dokud nejsou prázdné.
    func fetchAllMatching() async throws -> [Invoice] {
        let query = query
        var all: [Invoice] = []
        var seen = Set<Int>()
        for page in 1 ... 200 {
            let result: [Invoice] = try await session.send(listEndpoint(page: page, query: query))
            let fresh = result.filter { seen.insert($0.id).inserted }
            if fresh.isEmpty { break }
            all += query.filter == .overdue ? fresh.filter(\.isOverdue) : fresh
        }
        return all
    }
}

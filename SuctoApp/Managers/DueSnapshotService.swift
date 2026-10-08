//
//  DueSnapshotService.swift
//  SuctoApp
//

import Foundation
import WidgetKit

/// Načte nezaplacené faktury se splatností a uloží je pro widget a upozornění.
/// API nemá souhrn ani filtr „nezaplaceno“, proto se pro každý nezaplacený stav ptáme zvlášť (server umí jen `status_eq`).
@MainActor
final class DueSnapshotService {
    /// Stavy, ve kterých je faktura ještě k úhradě (viz `Invoice.Status`): připraveno … částečně uhrazeno.
    private static let unpaidStatuses = [2, 3, 4, 5, 6, 7]
    private static let horizonDays = 30
    private static let maximumPages = 5

    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    /// Obnoví snapshot firmy; vrací `true`, pokud se podařilo uložit čerstvá data.
    @discardableResult
    func refresh(company: Company) async -> Bool {
        guard let horizon = Calendar.current.date(byAdding: .day, value: Self.horizonDays, to: Date()) else { return false }
        do {
            let outgoing = try await load(direction: .outgoing, companyId: company.id, until: horizon)
            let incoming = try await load(direction: .incoming, companyId: company.id, until: horizon)
            // Při výpadku připojení by `SessionManager` vrátil starou cache – ta se nesmí vydávat za čerstvá data.
            guard session.cachedDataDate == nil else { return false }

            let snapshot = DueSnapshot(companyName: company.name, items: outgoing + incoming, updatedAt: Date())
            DueSnapshotStore.save(snapshot)
            WidgetCenter.shared.reloadAllTimelines()
            await DueNotifier.shared.reschedule(from: snapshot)
            return true
        } catch {
            Log.debug("⚠️ Snapshot splatností se nepodařilo obnovit: \(error.localizedDescription)")
            return false
        }
    }

    private func load(direction: InvoiceDirection, companyId: Int, until horizon: Date) async throws -> [DueItem] {
        let base = direction == .outgoing ? "companies/\(companyId)/actuarials_outs" : "companies/\(companyId)/actuarials_ins"
        var advanced = InvoiceAdvancedFilter()
        advanced.dueTo = horizon

        var invoices: [Invoice] = []
        try await withThrowingTaskGroup(of: [Invoice].self) { group in
            for status in Self.unpaidStatuses {
                var filter = advanced
                filter.status = Invoice.Status(rawValue: status)
                let query = InvoiceQuery(filter: .all, advanced: filter)
                group.addTask { @MainActor in
                    var collected: [Invoice] = []
                    for page in 1 ... Self.maximumPages {
                        let result: [Invoice] = try await self.session.send(query.path(base, page: page))
                        if result.isEmpty { break }
                        collected += result
                    }
                    return collected
                }
            }
            for try await part in group {
                invoices += part
            }
        }

        // Stejná faktura se nikdy nemá započítat dvakrát (např. kdyby server filtr stavu ignoroval).
        var seen = Set<Int>()
        invoices = invoices.filter { seen.insert($0.id).inserted }

        return invoices.compactMap { invoice in
            guard let due = invoice.dueDate, !invoice.isPaid, invoice.invoiceStatus != .storno else { return nil }
            let remaining = invoice.remaining.flatMap(Double.init) ?? invoice.endPrice.flatMap(Double.init) ?? 0
            let name = direction == .outgoing ? invoice.customer?.name : invoice.supplier?.name
            return DueItem(
                id: invoice.id,
                isIncoming: direction == .incoming,
                number: invoice.actuarialNumber,
                counterparty: name,
                dueDate: due,
                amount: remaining,
                currency: invoice.currency?.symbol,
            )
        }
    }
}

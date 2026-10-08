//
//  PohodaExportViewModel.swift
//  SuctoApp
//

import SwiftUI

@MainActor
final class PohodaExportViewModel: ObservableObject {
    struct Summary {
        /// Soubor k uložení/sdílení; `nil`, pokud se nepodařilo vyexportovat nic.
        let file: URL?
        let exportedCount: Int
        /// Koncepty a stornované faktury, které se do účetnictví nevyvážejí.
        let skippedCount: Int
        let failures: [PohodaExporter.Failure]
    }

    enum Phase {
        case idle
        case loading(message: String, progress: Double?)
        case finished(Summary)
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle

    let companyId: Int
    private let session: SessionManager

    private let maximumPages = 100
    private let concurrentDetails = 4

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    var isRunning: Bool {
        if case .loading = phase { return true }
        return false
    }

    // MARK: - Jedna faktura

    func exportInvoice(id: Int) async {
        phase = .loading(message: "Připravuji export…", progress: nil)
        do {
            let invoice: Invoice = try await session.send(
                APIConstants.outgoingInvoiceDetail(companyId: companyId, invoiceId: id),
            )
            try finish(invoices: [invoice], skipped: 0, fileName: "Pohoda_FA_\(invoice.actuarialNumber)")
        } catch is CancellationError {
            return
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    // MARK: - Období

    func exportPeriod(from: Date, to: Date) async {
        guard from <= to else {
            phase = .failed("Datum „od“ musí být dřív než „do“.")
            return
        }
        do {
            phase = .loading(message: "Načítám seznam faktur…", progress: nil)
            let listed = try await listInvoices(from: from, to: to)
            let exportable = listed.filter { $0.invoiceStatus != .concept && $0.invoiceStatus != .storno }
            let skipped = listed.count - exportable.count

            guard !exportable.isEmpty else {
                phase = .finished(Summary(file: nil, exportedCount: 0, skippedCount: skipped, failures: []))
                return
            }

            var downloadFailures: [PohodaExporter.Failure] = []
            let details = try await loadDetails(of: exportable, failures: &downloadFailures)

            let name = "Pohoda_vydane_faktury_\(Self.fileDate(from))_\(Self.fileDate(to))"
            try finish(invoices: details, skipped: skipped, fileName: name, extraFailures: downloadFailures)
        } catch is CancellationError {
            return
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    // MARK: - Kroky

    private func listInvoices(from: Date, to: Date) async throws -> [Invoice] {
        var all: [Invoice] = []
        var seen = Set<Int>()
        for page in 1 ... maximumPages {
            var components = URLComponents()
            components.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "q[issue_date_at_gteq]", value: Self.apiDate(from)),
                URLQueryItem(name: "q[issue_date_at_lteq]", value: Self.apiDate(to)),
            ]
            let path = "companies/\(companyId)/actuarials_outs?\(components.percentEncodedQuery ?? "")"
            let result: [Invoice] = try await session.send(path)

            let fresh = result.filter { seen.insert($0.id).inserted }
            if fresh.isEmpty { break }
            all += fresh
            phase = .loading(message: "Načítám seznam faktur… (\(all.count))", progress: nil)
        }
        return all
    }

    /// Stáhne detaily (seznam neobsahuje položky) s omezenou souběžností.
    private func loadDetails(
        of invoices: [Invoice],
        failures: inout [PohodaExporter.Failure],
    ) async throws -> [Invoice] {
        var details: [Invoice] = []
        var done = 0
        var iterator = invoices.makeIterator()

        try await withThrowingTaskGroup(of: (Invoice, Invoice?).self) { group in
            func addNext() -> Bool {
                guard let next = iterator.next() else { return false }
                group.addTask { @MainActor in
                    let detail: Invoice? = try? await self.session.send(
                        APIConstants.outgoingInvoiceDetail(companyId: self.companyId, invoiceId: next.id),
                    )
                    return (next, detail)
                }
                return true
            }

            for _ in 0 ..< concurrentDetails {
                _ = addNext()
            }
            while let (listed, detail) = try await group.next() {
                done += 1
                if let detail {
                    details.append(detail)
                } else {
                    failures.append(.init(id: listed.id, number: listed.actuarialNumber, reason: "nepodařilo se stáhnout detail"))
                }
                phase = .loading(message: "Stahuji faktury \(done) z \(invoices.count)…", progress: Double(done) / Double(invoices.count))
                _ = addNext()
            }
        }
        // V Pohodě je zvykem importovat od nejstarší (podle čísla dokladu).
        return details.sorted { $0.actuarialNumber.localizedStandardCompare($1.actuarialNumber) == .orderedAscending }
    }

    private func finish(
        invoices: [Invoice],
        skipped: Int,
        fileName: String,
        extraFailures: [PohodaExporter.Failure] = [],
    ) throws {
        let result = try PohodaExporter.makeXML(for: invoices)
        let failures = extraFailures + result.failures

        var file: URL?
        if result.exportedCount > 0 {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).xml")
            try result.data.write(to: url, options: .atomic)
            file = url
        }
        phase = .finished(Summary(file: file, exportedCount: result.exportedCount, skippedCount: skipped, failures: failures))
    }

    // MARK: - Formátování

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static func apiDate(_ date: Date) -> String { formatter.string(from: date) }
    private static func fileDate(_ date: Date) -> String { formatter.string(from: date) }
}

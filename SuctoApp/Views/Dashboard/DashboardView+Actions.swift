//
//  DashboardView+Actions.swift
//  SuctoApp
//

import SwiftUI

/// Akce dashboardu: export CSV, obnova dat pro widget, odkazy z widgetu/upozornění, nahrání dokladu.
extension DashboardView {
    /// Exportuje aktuální výběr faktur (hledání + filtry) do CSV a otevře sdílecí okno.
    func exportCSV(direction: InvoiceDirection) async {
        isExportingCSV = true
        defer { isExportingCSV = false }
        do {
            let viewModel: PagedInvoicesViewModel = direction == .outgoing ? outgoingInvoicesVM : incomingInvoicesVM
            let invoices = try await viewModel.fetchAllMatching()
            let data = InvoiceCSVExporter.csv(for: invoices, direction: direction)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(InvoiceCSVExporter.fileName(direction: direction))
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            csvFile = ShareableFile(url: url)
        } catch is CancellationError {
            return
        } catch {
            csvError = error.localizedDescription
        }
    }

    /// Odkaz z widgetu: přepne záložku vydaných/přijatých a zapne filtr „Po splatnosti“.
    func consumePendingTarget() {
        guard let target = navManager.pendingTarget else { return }
        navManager.pendingTarget = nil
        mainTab = .invoices
        invoiceSide = target.isIncoming ? .incoming : .outgoing
        if target.isIncoming {
            incomingInvoicesVM.filter = .overdue
        } else {
            outgoingInvoicesVM.filter = .overdue
        }
    }

    /// Obnoví data pro widget a upozornění na splatnost (běží na pozadí, chyby se ignorují).
    func refreshDueSnapshot() async {
        guard let company = session.selectedCompany, company.id == companyId else { return }
        await DueSnapshotService(session: session).refresh(company: company)
    }

    func uploadScan(_ file: MultipartFile) {
        Task {
            if await scanUploader.upload(file) {
                navManager.showScans(companyId: companyId)
            }
        }
    }
}

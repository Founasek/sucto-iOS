//
//  NavigationManager.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

@MainActor
final class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()
    /// Cíl z odkazu (např. widget): po otevření dashboardu se přepne záložka a nastaví filtr „Po splatnosti“.
    @Published var pendingTarget: DashboardTarget?

    struct DashboardTarget: Equatable {
        let isIncoming: Bool
    }

    func goToDashboard(companyId: Int) {
        path.append(AppRoute.dashboard(companyId: companyId))
    }

    /// Nahradí otevřený dashboard dashboardem jiné firmy (bez návratu přes seznam firem).
    func switchCompany(to companyId: Int) {
        var newPath = NavigationPath()
        newPath.append(AppRoute.dashboard(companyId: companyId))
        path = newPath
    }

    func createInvoice(companyId: Int, direction: InvoiceDirection, scanId: String? = nil) {
        path.append(AppRoute.createInvoice(companyId: companyId, direction: direction, scanId: scanId))
    }

    func duplicateInvoice(companyId: Int, direction: InvoiceDirection, invoiceId: Int) {
        path.append(AppRoute.duplicateInvoice(companyId: companyId, direction: direction, invoiceId: invoiceId))
    }

    func showAccounts(companyId: Int) {
        path.append(AppRoute.accounts(companyId: companyId))
    }

    func showSettings() {
        path.append(AppRoute.settings)
    }

    func showScans(companyId: Int) {
        path.append(AppRoute.scans(companyId: companyId))
    }

    func showPartners(companyId: Int) {
        path.append(AppRoute.partners(companyId: companyId))
    }

    func reset() {
        path = NavigationPath()
    }
}

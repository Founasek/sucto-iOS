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

    func goToCompanies() {
        path = NavigationPath()
    }

    func goToDashboard(companyId: Int) {
        path.append(AppRoute.dashboard(companyId: companyId))
    }

    func createInvoice(companyId: Int, direction: InvoiceDirection, scanId: String? = nil) {
        path.append(AppRoute.createInvoice(companyId: companyId, direction: direction, scanId: scanId))
    }

    func duplicateInvoice(companyId: Int, direction: InvoiceDirection, invoiceId: Int) {
        path.append(AppRoute.duplicateInvoice(companyId: companyId, direction: direction, invoiceId: invoiceId))
    }

    func showScans(companyId: Int) {
        path.append(AppRoute.scans(companyId: companyId))
    }

    func showPartners(companyId: Int) {
        path.append(AppRoute.partners(companyId: companyId))
    }

    func showCashVouchers(companyId: Int) {
        path.append(AppRoute.cashVouchers(companyId: companyId))
    }

    func reset() {
        path = NavigationPath()
    }
}

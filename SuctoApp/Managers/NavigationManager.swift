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

    func goToCompanies() {
        path = NavigationPath()
    }

    func goToDashboard(companyId: Int) {
        path.append(AppRoute.dashboard(companyId: companyId))
    }

    func createInvoice(companyId: Int, direction: InvoiceDirection, scanId: String? = nil) {
        path.append(AppRoute.createInvoice(companyId: companyId, direction: direction, scanId: scanId))
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

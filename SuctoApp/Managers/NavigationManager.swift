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

    func createOutgoingInvoice(companyId: Int) {
        path.append(AppRoute.createOutgoingInvoice(companyId: companyId))
    }

    func reset() {
        path = NavigationPath()
    }
}

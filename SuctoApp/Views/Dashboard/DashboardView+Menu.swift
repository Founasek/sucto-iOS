//
//  DashboardView+Menu.swift
//  SuctoApp
//

import SwiftUI

/// Menu „…“ v záhlaví dashboardu.
extension DashboardView {
    /// Položky menu „…“ (podle záložky se liší exporty).
    @ViewBuilder
    var menuItems: some View {
        if mainTab == .invoices {
            Button {
                pohodaExportDirection = invoiceSide.direction
            } label: {
                Label(pohodaExportTitle, systemImage: "square.and.arrow.up")
            }

            Button {
                Task { await exportCSV(direction: invoiceSide.direction) }
            } label: {
                Label("Exportovat seznam do CSV", systemImage: "tablecells")
            }
            .disabled(isExportingCSV)
        }

        if FeatureFlags.scans, mainTab == .invoices, invoiceSide == .incoming {
            Button {
                navManager.showScans(companyId: companyId)
            } label: {
                Label("Skeny faktur", systemImage: "doc.viewfinder")
            }
        }

        Button {
            navManager.showSettings()
        } label: {
            Label("Nastavení", systemImage: "gearshape")
        }

        Button(role: .destructive) {
            session.logout()
            navManager.reset()
        } label: {
            Label("Odhlásit se", systemImage: "rectangle.portrait.and.arrow.right")
        }
    }

    /// Výběr záložky; opakované klepnutí na už otevřenou záložku Firma otevře přepínač firem.
    var tabSelection: Binding<MainTab> {
        Binding(
            get: { mainTab },
            set: { newValue in
                if newValue == .company, mainTab == .company { showCompanySwitcher = true }
                mainTab = newValue
            },
        )
    }

    var pohodaExportTitle: String {
        invoiceSide == .outgoing ? "Export vydaných do Pohody" : "Export přijatých do Pohody"
    }
}

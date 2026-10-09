//
//  DashboardView+Invoices.swift
//  SuctoApp
//

import SwiftUI

/// Záložka Faktury dashboardu: přepínač Vydané/Přijaté, seznam, tlačítko nové faktury a cíle navigace na detail.
extension DashboardView {
    /// Záložka Faktury: přepínač Vydané/Přijaté nahoře, seznam pod ním a plovoucí tlačítko nové faktury.
    var invoicesTab: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                SegmentedTabs(items: InvoiceSide.allCases.map(\.item), selection: Binding(
                    get: { invoiceSide.rawValue },
                    set: { index in
                        guard let newSide = InvoiceSide(rawValue: index) else { return }
                        // Směr přechodu se nastaví dřív než samotná změna strany.
                        slideEdge = newSide.rawValue > invoiceSide.rawValue ? .trailing : .leading
                        invoiceSide = newSide
                    },
                ))
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.s)

                Group {
                    switch invoiceSide {
                    case .outgoing:
                        OutgoingInvoicesView(namespace: invoiceNamespace)
                            .environmentObject(outgoingInvoicesVM)
                    case .incoming:
                        IncomingInvoicesView(namespace: invoiceNamespace)
                            .environmentObject(incomingInvoicesVM)
                    }
                }
                .id(invoiceSide)
                .transition(.asymmetric(
                    insertion: .move(edge: slideEdge).combined(with: .opacity),
                    removal: .move(edge: slideEdge == .trailing ? .leading : .trailing).combined(with: .opacity),
                ))
            }
            .clipped()

            if let direction = createDirection {
                newInvoiceButton(direction)
                    .id(direction)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .animation(Motion.standard, value: invoiceSide)
    }

    /// Tlačítko nové faktury se neukáže, když uživatel podle `api_permissions` faktury daného směru vytvářet nesmí.
    var createDirection: InvoiceDirection? {
        let direction = invoiceSide.direction
        guard permissions.can(.create, direction.permissionResource, companyId: companyId) else { return nil }
        return direction
    }

    func newInvoiceButton(_ direction: InvoiceDirection) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            if FeatureFlags.scans, direction == .incoming { scanMenu }
            createButton(direction)
        }
        .padding(Theme.Spacing.l)
    }

    func createButton(_ direction: InvoiceDirection) -> some View {
        let title = direction == .outgoing ? "Nová faktura" : "Nová přijatá"
        return Button {
            navManager.createInvoice(companyId: companyId, direction: direction)
        } label: {
            Label(title, systemImage: "plus")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Theme.brandGradient, in: Capsule())
                .shadow(color: Theme.brand.opacity(0.45), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction.createTitle)
    }

    /// Nahrání dokladu: skener, fotky nebo Soubory – ze skenu server předvyplní fakturu.
    var scanMenu: some View {
        Menu {
            if ScanSource.cameraAvailable {
                Button { scanSource = .camera } label: { Label("Naskenovat doklad", systemImage: "camera.viewfinder") }
            }
            Button { scanSource = .photos } label: { Label("Vybrat z fotek", systemImage: "photo") }
            Button { scanSource = .files } label: { Label("Vybrat ze Souborů", systemImage: "folder") }
            Divider()
            Button { navManager.showScans(companyId: companyId) } label: { Label("Zobrazit skeny", systemImage: "list.bullet.rectangle") }
        } label: {
            Image(systemName: "doc.viewfinder")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 52, height: 52)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        }
        .accessibilityLabel("Nahrát doklad ke zpracování")
    }

    /// Detail faktury otevřený podle id a směru (z Přehledu); bez zoom přechodu, protože nemá zdrojovou kartu.
    @ViewBuilder
    func invoiceDetail(for route: InvoiceRoute) -> some View {
        if route.isIncoming {
            IncomingInvoiceDetailView(invoiceId: route.id)
                .environmentObject(incomingInvoicesVM)
        } else {
            OutgoingInvoiceDetailView(invoiceId: route.id)
                .environmentObject(outgoingInvoicesVM)
        }
    }

    @ViewBuilder
    func invoiceDetail(for invoice: Invoice) -> some View {
        switch invoiceSide {
        case .outgoing:
            OutgoingInvoiceDetailView(invoiceId: invoice.id)
                .environmentObject(outgoingInvoicesVM)
                .navigationTransition(.zoom(sourceID: invoice.id, in: invoiceNamespace))
        case .incoming:
            IncomingInvoiceDetailView(invoiceId: invoice.id)
                .environmentObject(incomingInvoicesVM)
                .navigationTransition(.zoom(sourceID: invoice.id, in: invoiceNamespace))
        }
    }
}

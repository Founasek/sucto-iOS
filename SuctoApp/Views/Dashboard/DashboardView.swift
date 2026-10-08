import SwiftUI

struct DashboardView: View {
    let companyId: Int
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var session: SessionManager
    @State private var selectedTab = 0
    @State private var slideEdge: Edge = .trailing

    @StateObject var outgoingInvoicesVM: OutgoingInvoicesViewModel
    @StateObject var incomingInvoicesVM: IncomingInvoicesViewModel
    @StateObject private var accountsVM: AccountsViewModel

    private let tabs: [SegmentedTabs.Item] = [
        .init(title: "Vydané", systemImage: "arrow.up.right.circle"),
        .init(title: "Přijaté", systemImage: "arrow.down.left.circle"),
        .init(title: "Účty", systemImage: "creditcard"),
    ]

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        _outgoingInvoicesVM = StateObject(wrappedValue: OutgoingInvoicesViewModel(companyId: companyId, session: session))
        _incomingInvoicesVM = StateObject(wrappedValue: IncomingInvoicesViewModel(companyId: companyId, session: session))
        _accountsVM = StateObject(wrappedValue: AccountsViewModel(companyId: companyId, session: session))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                SegmentedTabs(items: tabs, selection: Binding(
                    get: { selectedTab },
                    set: { newValue in
                        // Směr přechodu se nastaví dřív než samotná změna záložky.
                        slideEdge = newValue > selectedTab ? .trailing : .leading
                        selectedTab = newValue
                    },
                ))
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.s)

                Group {
                    switch selectedTab {
                    case 0:
                        OutgoingInvoicesView()
                            .environmentObject(outgoingInvoicesVM)
                    case 1:
                        IncomingInvoicesView()
                            .environmentObject(incomingInvoicesVM)
                    default:
                        BankAccountsView()
                            .environmentObject(accountsVM)
                    }
                }
                .id(selectedTab)
                .transition(.asymmetric(
                    insertion: .move(edge: slideEdge).combined(with: .opacity),
                    removal: .move(edge: slideEdge == .trailing ? .leading : .trailing).combined(with: .opacity),
                ))
            }
            .clipped()

            if selectedTab == 0 {
                newInvoiceButton
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .background(Theme.background)
        .animation(Motion.standard, value: selectedTab)
        .navigationTitle(session.selectedCompany?.name ?? "Přehled")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        navManager.goToCompanies()
                    } label: {
                        Label("Změnit firmu", systemImage: "building.2")
                    }

                    Button(role: .destructive) {
                        session.logout()
                        navManager.reset()
                    } label: {
                        Label("Odhlásit se", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
                .accessibilityLabel("Menu")
            }
        }
        .task {
            async let outgoing: Void = outgoingInvoicesVM.refresh()
            async let incoming: Void = incomingInvoicesVM.refresh()
            async let accounts: Void = accountsVM.fetchAccounts()
            _ = await (outgoing, incoming, accounts)
        }
    }

    private var newInvoiceButton: some View {
        Button {
            navManager.createOutgoingInvoice(companyId: companyId)
        } label: {
            Label("Nová faktura", systemImage: "plus")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Theme.brandGradient, in: Capsule())
                .shadow(color: Theme.brand.opacity(0.45), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .padding(Theme.Spacing.l)
        .accessibilityLabel("Nová faktura")
    }
}

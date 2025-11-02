import SwiftUI

struct DashboardView: View {
    let companyId: Int
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var session: SessionManager
    @State private var selectedTab = 0

    @StateObject var outgoingInvoicesVM: OutgoingInvoicesViewModel
    @StateObject var incomingInvoicesVM: IncomingInvoicesViewModel
    @StateObject private var accountsVM: AccountsViewModel

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        _outgoingInvoicesVM = StateObject(wrappedValue: OutgoingInvoicesViewModel(companyId: companyId, session: session))
        _incomingInvoicesVM = StateObject(wrappedValue: IncomingInvoicesViewModel(companyId: companyId, session: session))
        _accountsVM = StateObject(wrappedValue: AccountsViewModel(companyId: companyId, session: session))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                Picker("Tabs", selection: $selectedTab) {
                    Text("Vydané faktury").tag(0)
                    Text("Přijaté faktury").tag(1)
                    Text("Účty").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.accent)

                switch selectedTab {
                case 0:
                    OutgoingInvoicesView()
                        .environmentObject(outgoingInvoicesVM)
                case 1:
                    IncomingInvoicesView()
                        .environmentObject(incomingInvoicesVM)
                case 2:
                    BankAccountsView()
                        .environmentObject(accountsVM)
                default:
                    EmptyView()
                }
            }
            if selectedTab == 0 {
                Button {
                    navManager.createOutgoingInvoice(companyId: companyId)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
                .accessibilityLabel("Nová faktura")
            }
        }
        .navigationTitle("Vydané faktury")
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
                    Image(systemName: "line.3.horizontal")
                        .imageScale(.large)
                }
            }
        }
        .onAppear {
            Task {
                await outgoingInvoicesVM.fetchInvoices(page: 1)
                await incomingInvoicesVM.fetchInvoices(page: 1)
                await accountsVM.fetchAccounts()
            }
        }
    }
}

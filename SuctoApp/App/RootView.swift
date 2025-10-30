import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var navManager: NavigationManager
    
    @EnvironmentObject var outgoingInvoicesViewModel: OutgoingInvoicesViewModel

    var body: some View {
            CompaniesView(viewModel: CompaniesViewModel(session: session))
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .dashboard(let companyId):
                        DashboardView(companyId: companyId, session: session)
                            .environmentObject(navManager)
                            .environmentObject(session)

                    case .outgoingInvoiceDetail(let invoiceId):
                        OutgoingInvoiceDetailView(invoiceId: invoiceId)
                            .environmentObject(navManager)
                            .environmentObject(session)

                    case .createOutgoingInvoice(let companyId):
                        OutgoingInvoiceCreateView(companyId: companyId)
                            .environmentObject(navManager)
                            .environmentObject(session)

                    case .incomingInvoiceDetail(let invoice):
                        IncomingInvoiceDetailView(invoice: invoice)

                    case .accountDetail(let account):
                        AccountDetailView(account: account)
                            .environmentObject(navManager)
                            .environmentObject(session)
                    }
                }
            
        
    }
}

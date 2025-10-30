import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var navManager: NavigationManager

    @EnvironmentObject var outgoingInvoicesViewModel: OutgoingInvoicesViewModel

    var body: some View {
        CompaniesView(viewModel: CompaniesViewModel(session: session))
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case let .dashboard(companyId):
                    DashboardView(companyId: companyId, session: session)
                        .environmentObject(navManager)
                        .environmentObject(session)

                case let .outgoingInvoiceDetail(invoiceId):
                    OutgoingInvoiceDetailView(invoiceId: invoiceId)
                        .environmentObject(navManager)
                        .environmentObject(session)

                case let .createOutgoingInvoice(companyId):
                    OutgoingInvoiceCreateView(companyId: companyId)
                        .environmentObject(navManager)
                        .environmentObject(session)

                case let .incomingInvoiceDetail(invoice):
                    IncomingInvoiceDetailView(invoice: invoice)

                case let .accountDetail(account):
                    AccountDetailView(account: account)
                        .environmentObject(navManager)
                        .environmentObject(session)
                }
            }
    }
}

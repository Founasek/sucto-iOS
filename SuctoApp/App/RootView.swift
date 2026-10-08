import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        CompaniesView(viewModel: CompaniesViewModel(session: session))
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case let .dashboard(companyId):
                    DashboardView(companyId: companyId, session: session)

                case let .createOutgoingInvoice(companyId):
                    OutgoingInvoiceCreateView(companyId: companyId, session: session)
                }
            }
    }
}

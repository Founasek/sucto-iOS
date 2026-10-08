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

                case let .createInvoice(companyId, direction, scanId):
                    InvoiceCreateView(companyId: companyId, direction: direction, scanId: scanId, session: session)

                case let .scans(companyId):
                    ScansView(companyId: companyId, session: session)

                case let .partners(companyId):
                    PartnersView(companyId: companyId, session: session)

                case let .partnerDetail(companyId, partnerId):
                    PartnerDetailView(companyId: companyId, partnerId: partnerId, session: session)

                case let .cashVouchers(companyId):
                    CashVouchersView(companyId: companyId, session: session)

                case let .cashVoucherDetail(companyId, directionRaw, voucherId):
                    CashVoucherDetailView(
                        companyId: companyId,
                        direction: CashDirection(rawValue: directionRaw) ?? .income,
                        voucherId: voucherId,
                        session: session,
                    )
                }
            }
    }
}

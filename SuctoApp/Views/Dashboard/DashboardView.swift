import SwiftUI

struct DashboardView: View {
    let companyId: Int
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var permissions: PermissionsStore
    @Namespace var invoiceNamespace
    @State var mainTab = MainTab.overview
    @State var invoiceSide = InvoiceSide.outgoing
    @State var pohodaExportDirection: InvoiceDirection?
    @State var scanSource: ScanSource?
    @State var slideEdge: Edge = .trailing
    @State var csvFile: ShareableFile?
    @State var isExportingCSV = false
    @State var csvError: String?
    @Environment(\.scenePhase) var scenePhase

    @StateObject var overviewVM: OverviewViewModel
    @StateObject var scanUploader: ScanUploadViewModel
    @StateObject var outgoingInvoicesVM: OutgoingInvoicesViewModel
    @StateObject var incomingInvoicesVM: IncomingInvoicesViewModel

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        _overviewVM = StateObject(wrappedValue: OverviewViewModel(companyId: companyId, session: session))
        _scanUploader = StateObject(wrappedValue: ScanUploadViewModel(companyId: companyId, session: session))
        _outgoingInvoicesVM = StateObject(wrappedValue: OutgoingInvoicesViewModel(companyId: companyId, session: session))
        _incomingInvoicesVM = StateObject(wrappedValue: IncomingInvoicesViewModel(companyId: companyId, session: session))
    }

    /// Záložky, záhlaví a menu; zbytek (okna, upozornění) je ve `body`, ať kompilátor nemá jeden obří výraz.
    private var content: some View {
        TabView(selection: $mainTab) {
            Tab("Přehled", systemImage: "chart.bar.xaxis", value: MainTab.overview) {
                OverviewView()
                    .environmentObject(overviewVM)
                    .offlineBanner()
            }

            Tab("Faktury", systemImage: "doc.text", value: MainTab.invoices) {
                invoicesTab
                    .offlineBanner()
            }

            Tab("Pokladna", systemImage: "banknote", value: MainTab.cash) {
                CashVouchersView(companyId: companyId, session: session)
                    .offlineBanner()
            }
        }
        .task { await permissions.load(companyId: companyId, session: session) }
        .onAppear { consumePendingTarget() }
        .onChange(of: navManager.pendingTarget) { consumePendingTarget() }
        .task { await refreshDueSnapshot() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshDueSnapshot() } }
        }
        .background(Theme.background)
        // Cíl navigace musí být nad TabView: uvnitř záložky ho zásobník nenajde a detail faktury by se neotevřel.
        // Obě strany sdílejí typ `Invoice`, otevře se detail té, která je zrovna vybraná.
        .navigationDestination(for: Invoice.self) { invoice in
            invoiceDetail(for: invoice)
        }
        .navigationDestination(for: InvoiceRoute.self) { route in
            invoiceDetail(for: route)
        }
        .navigationTitle(session.selectedCompany?.name ?? "Přehled")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    menuItems
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
                .accessibilityLabel("Menu")
            }
        }
    }

    /// Okna a upozornění nad obsahem (export, nahrání dokladu).
    private var dialogs: some View {
        content
            .sheet(item: $csvFile) { file in
                ShareSheet(file: file)
            }
            .alert("Export se nezdařil", isPresented: Binding(get: { csvError != nil }, set: { if !$0 { csvError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(csvError ?? "")
            }
            .scanSourcePresenter(source: $scanSource, onFile: uploadScan, onFailure: { scanUploader.errorMessage = $0 })
            .alert(
                "Nahrání se nezdařilo",
                isPresented: Binding(get: { scanUploader.errorMessage != nil }, set: { if !$0 { scanUploader.errorMessage = nil } }),
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(scanUploader.errorMessage ?? "")
            }
    }

    var body: some View {
        dialogs
            .overlay {
                if scanUploader.isUploading {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        VStack(spacing: Theme.Spacing.m) {
                            ProgressView().controlSize(.large)
                            Text("Nahrávám doklad…").font(.subheadline)
                        }
                        .padding(Theme.Spacing.xl)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .transition(.opacity)
                }
            }
            .animation(Motion.standard, value: scanUploader.isUploading)
            .sheet(item: $pohodaExportDirection) { direction in
                PohodaExportSheet(companyId: companyId, session: session, direction: direction, mode: .period)
            }
            .task {
                async let outgoing: Void = outgoingInvoicesVM.refresh()
                async let incoming: Void = incomingInvoicesVM.refresh()
                _ = await (outgoing, incoming)
            }
    }
}

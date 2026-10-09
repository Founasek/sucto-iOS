import SwiftUI

/// Záložky dolní lišty.
private enum MainTab: Hashable {
    case overview, invoices, cash
}

/// Strana v záložce Faktury (přepínač nahoře).
private enum InvoiceSide: Int, CaseIterable {
    case outgoing, incoming

    var item: SegmentedTabs.Item {
        switch self {
        case .outgoing: .init(title: "Vydané", systemImage: "arrow.up.right.circle")
        case .incoming: .init(title: "Přijaté", systemImage: "arrow.down.left.circle")
        }
    }

    var direction: InvoiceDirection { self == .outgoing ? .outgoing : .incoming }
}

struct DashboardView: View {
    let companyId: Int
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var permissions: PermissionsStore
    @Namespace private var invoiceNamespace
    @State private var mainTab = MainTab.overview
    @State private var invoiceSide = InvoiceSide.outgoing
    @State private var pohodaExportDirection: InvoiceDirection?
    @State private var scanSource: ScanSource?
    @State private var slideEdge: Edge = .trailing
    @State private var csvFile: ShareableFile?
    @State private var isExportingCSV = false
    @State private var csvError: String?
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var overviewVM: OverviewViewModel
    @StateObject private var scanUploader: ScanUploadViewModel
    @StateObject var outgoingInvoicesVM: OutgoingInvoicesViewModel
    @StateObject var incomingInvoicesVM: IncomingInvoicesViewModel

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        _overviewVM = StateObject(wrappedValue: OverviewViewModel(companyId: companyId, session: session))
        _scanUploader = StateObject(wrappedValue: ScanUploadViewModel(companyId: companyId, session: session))
        _outgoingInvoicesVM = StateObject(wrappedValue: OutgoingInvoicesViewModel(companyId: companyId, session: session))
        _incomingInvoicesVM = StateObject(wrappedValue: IncomingInvoicesViewModel(companyId: companyId, session: session))
    }

    var body: some View {
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
                CashVouchersView(companyId: companyId, session: session, embedded: true)
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
        .navigationTitle(session.selectedCompany?.name ?? "Přehled")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if mainTab == .invoices {
                        Button {
                            pohodaExportDirection = invoiceSide.direction
                        } label: {
                            Label(
                                invoiceSide == .outgoing ? "Export vydaných do Pohody" : "Export přijatých do Pohody",
                                systemImage: "square.and.arrow.up",
                            )
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
                        navManager.showAccounts(companyId: companyId)
                    } label: {
                        Label("Účty", systemImage: "creditcard")
                    }

                    Button {
                        navManager.showPartners(companyId: companyId)
                    } label: {
                        Label("Partneři", systemImage: "person.2")
                    }

                    Button {
                        navManager.showSettings()
                    } label: {
                        Label("Nastavení", systemImage: "gearshape")
                    }

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

    /// Záložka Faktury: přepínač Vydané/Přijaté nahoře, seznam pod ním a plovoucí tlačítko nové faktury.
    private var invoicesTab: some View {
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
    private var createDirection: InvoiceDirection? {
        let direction = invoiceSide.direction
        guard permissions.can(.create, direction.permissionResource, companyId: companyId) else { return nil }
        return direction
    }

    private func newInvoiceButton(_ direction: InvoiceDirection) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            if FeatureFlags.scans, direction == .incoming { scanMenu }
            createButton(direction)
        }
        .padding(Theme.Spacing.l)
    }

    private func createButton(_ direction: InvoiceDirection) -> some View {
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
    private var scanMenu: some View {
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
}

private extension DashboardView {
    @ViewBuilder
    private func invoiceDetail(for invoice: Invoice) -> some View {
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

    /// Exportuje aktuální výběr faktur (hledání + filtry) do CSV a otevře sdílecí okno.
    private func exportCSV(direction: InvoiceDirection) async {
        isExportingCSV = true
        defer { isExportingCSV = false }
        do {
            let viewModel: PagedInvoicesViewModel = direction == .outgoing ? outgoingInvoicesVM : incomingInvoicesVM
            let invoices = try await viewModel.fetchAllMatching()
            let data = InvoiceCSVExporter.csv(for: invoices, direction: direction)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(InvoiceCSVExporter.fileName(direction: direction))
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            csvFile = ShareableFile(url: url)
        } catch is CancellationError {
            return
        } catch {
            csvError = error.localizedDescription
        }
    }

    /// Odkaz z widgetu: přepne záložku vydaných/přijatých a zapne filtr „Po splatnosti“.
    private func consumePendingTarget() {
        guard let target = navManager.pendingTarget else { return }
        navManager.pendingTarget = nil
        mainTab = .invoices
        invoiceSide = target.isIncoming ? .incoming : .outgoing
        if target.isIncoming {
            incomingInvoicesVM.filter = .overdue
        } else {
            outgoingInvoicesVM.filter = .overdue
        }
    }

    /// Obnoví data pro widget a upozornění na splatnost (běží na pozadí, chyby se ignorují).
    private func refreshDueSnapshot() async {
        guard let company = session.selectedCompany, company.id == companyId else { return }
        await DueSnapshotService(session: session).refresh(company: company)
    }

    private func uploadScan(_ file: MultipartFile) {
        Task {
            if await scanUploader.upload(file) {
                navManager.showScans(companyId: companyId)
            }
        }
    }
}

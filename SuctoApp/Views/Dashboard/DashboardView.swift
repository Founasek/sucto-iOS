import SwiftUI

/// Záložky dashboardu; pořadí odpovídá pořadí v přepínači.
private enum DashboardTab: Int, CaseIterable {
    case overview, outgoing, incoming, accounts

    var item: SegmentedTabs.Item {
        switch self {
        case .overview: .init(title: "Přehled", systemImage: "chart.bar.xaxis")
        case .outgoing: .init(title: "Vydané", systemImage: "arrow.up.right.circle")
        case .incoming: .init(title: "Přijaté", systemImage: "arrow.down.left.circle")
        case .accounts: .init(title: "Účty", systemImage: "creditcard")
        }
    }
}

struct DashboardView: View {
    let companyId: Int
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var permissions: PermissionsStore
    @State private var selectedTab = DashboardTab.overview.rawValue
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
    @StateObject private var accountsVM: AccountsViewModel

    private var visibleTabs: [DashboardTab] { DashboardTab.allCases }

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        _overviewVM = StateObject(wrappedValue: OverviewViewModel(companyId: companyId, session: session))
        _scanUploader = StateObject(wrappedValue: ScanUploadViewModel(companyId: companyId, session: session))
        _outgoingInvoicesVM = StateObject(wrappedValue: OutgoingInvoicesViewModel(companyId: companyId, session: session))
        _incomingInvoicesVM = StateObject(wrappedValue: IncomingInvoicesViewModel(companyId: companyId, session: session))
        _accountsVM = StateObject(wrappedValue: AccountsViewModel(companyId: companyId, session: session))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                SegmentedTabs(items: visibleTabs.map(\.item), selection: Binding(
                    get: { visibleTabs.firstIndex(of: tab) ?? 0 },
                    set: { index in
                        guard visibleTabs.indices.contains(index) else { return }
                        let newTab = visibleTabs[index]
                        // Směr přechodu se nastaví dřív než samotná změna záložky.
                        slideEdge = newTab.rawValue > selectedTab ? .trailing : .leading
                        selectedTab = newTab.rawValue
                    },
                ))
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.s)

                Group {
                    switch tab {
                    case .overview:
                        OverviewView()
                            .environmentObject(overviewVM)
                    case .outgoing:
                        OutgoingInvoicesView()
                            .environmentObject(outgoingInvoicesVM)
                    case .incoming:
                        IncomingInvoicesView()
                            .environmentObject(incomingInvoicesVM)
                    case .accounts:
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

            if let direction = createDirection {
                newInvoiceButton(direction)
                    .id(direction)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .offlineBanner()
        .task { await permissions.load(companyId: companyId, session: session) }
        .onAppear { consumePendingTarget() }
        .onChange(of: navManager.pendingTarget) { consumePendingTarget() }
        .task { await refreshDueSnapshot() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshDueSnapshot() } }
        }
        .background(Theme.background)
        .animation(Motion.standard, value: selectedTab)
        .navigationTitle(session.selectedCompany?.name ?? "Přehled")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if tab == .outgoing || tab == .incoming {
                        Button {
                            pohodaExportDirection = tab == .outgoing ? .outgoing : .incoming
                        } label: {
                            Label(
                                tab == .outgoing ? "Export vydaných do Pohody" : "Export přijatých do Pohody",
                                systemImage: "square.and.arrow.up",
                            )
                        }
                    }

                    if tab == .outgoing || tab == .incoming {
                        Button {
                            Task { await exportCSV(direction: tab == .outgoing ? .outgoing : .incoming) }
                        } label: {
                            Label("Exportovat seznam do CSV", systemImage: "tablecells")
                        }
                        .disabled(isExportingCSV)
                    }

                    if FeatureFlags.scans, tab == .incoming {
                        Button {
                            navManager.showScans(companyId: companyId)
                        } label: {
                            Label("Skeny faktur", systemImage: "doc.viewfinder")
                        }
                    }

                    Button {
                        navManager.showCashVouchers(companyId: companyId)
                    } label: {
                        Label("Pokladna", systemImage: "banknote")
                    }

                    Button {
                        navManager.showPartners(companyId: companyId)
                    } label: {
                        Label("Partneři", systemImage: "person.2")
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
            async let accounts: Void = accountsVM.fetchAccounts()
            _ = await (outgoing, incoming, accounts)
        }
    }

    /// Směr faktury, kterou lze na aktuální záložce vytvořit (na záložce Účty tlačítko není).
    /// Tlačítko se neukáže, když uživatel podle `api_permissions` faktury daného směru vytvářet nesmí.
    private var createDirection: InvoiceDirection? {
        let direction: InvoiceDirection? = switch tab {
        case .outgoing: .outgoing
        case .incoming: .incoming
        default: nil
        }
        guard let direction, permissions.can(.create, direction.permissionResource, companyId: companyId) else { return nil }
        return direction
    }

    private var tab: DashboardTab { DashboardTab(rawValue: selectedTab) ?? .overview }

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
        selectedTab = (target.isIncoming ? DashboardTab.incoming : DashboardTab.outgoing).rawValue
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

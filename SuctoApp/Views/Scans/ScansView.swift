//
//  ScansView.swift
//  SuctoApp
//

import SwiftUI

/// Seznam nahraných dokladů a jejich stav zpracování; ze zpracovaného lze vytvořit fakturu.
struct ScansView: View {
    @StateObject private var viewModel: ScansViewModel
    @StateObject private var uploader: ScanUploadViewModel
    @EnvironmentObject private var navManager: NavigationManager
    @State private var source: ScanSource?
    @State private var previewScan: Scan?

    init(companyId: Int, session: SessionManager) {
        _viewModel = StateObject(wrappedValue: ScansViewModel(companyId: companyId, session: session))
        _uploader = StateObject(wrappedValue: ScanUploadViewModel(companyId: companyId, session: session))
    }

    var body: some View {
        ScrollView {
            if viewModel.scans.isEmpty {
                emptyOrLoading
            } else {
                LazyVStack(spacing: Theme.Spacing.m) {
                    ForEach(Array(viewModel.scans.enumerated()), id: \.element.id) { index, scan in
                        Button {
                            open(scan)
                        } label: {
                            ScanRow(scan: scan, isUsed: viewModel.usedScanIds.contains(scan.id), viewModel: viewModel)
                        }
                        .buttonStyle(PressableCardStyle())
                        .staggeredAppear(index: index)
                        .onAppear {
                            if scan.id == viewModel.scans.last?.id {
                                Task { await viewModel.loadNextPage() }
                            }
                        }
                    }
                    if viewModel.isLoading {
                        ProgressView().padding(.vertical, Theme.Spacing.l)
                    }
                }
                .padding(Theme.Spacing.l)
            }
        }
        .background(Theme.background)
        .navigationTitle("Skeny faktur")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                uploadMenu
            }
        }
        .refreshable { await viewModel.refresh() }
        .task {
            await viewModel.refresh()
        }
        // Dokud server doklady zpracovává, stav se sám obnovuje (i po nahrání dalšího dokladu).
        .task(id: viewModel.hasPendingScans) {
            while !Task.isCancelled, viewModel.hasPendingScans {
                try? await Task.sleep(for: .seconds(8))
                if Task.isCancelled { break }
                await viewModel.poll()
            }
        }
        .onAppear { viewModel.reloadUsedScans() }
        .scanSourcePresenter(source: $source, onFile: upload, onFailure: { uploader.errorMessage = $0 })
        .sheet(item: $previewScan) { scan in
            ScanPreviewSheet(scan: scan, viewModel: viewModel)
        }
        .alert(
            "Nahrání se nezdařilo",
            isPresented: Binding(get: { uploader.errorMessage != nil }, set: { if !$0 { uploader.errorMessage = nil } }),
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(uploader.errorMessage ?? "")
        }
        .overlay {
            if uploader.isUploading {
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
        .animation(Motion.standard, value: uploader.isUploading)
    }

    // MARK: - Části

    @ViewBuilder
    private var emptyOrLoading: some View {
        if viewModel.isLoading {
            LoadingStateView(message: "Načítám skeny…")
        } else if let error = viewModel.errorMessage {
            ErrorStateView(message: error) {
                Task { await viewModel.refresh() }
            }
        } else {
            EmptyStateView(
                systemImage: "doc.viewfinder",
                message: "Zatím jste nenahráli žádný doklad.\nVyfoťte přijatou fakturu a sÚčto z ní předvyplní údaje.",
                actionTitle: ScanSource.cameraAvailable ? "Naskenovat doklad" : "Vybrat z fotek",
                action: { source = ScanSource.cameraAvailable ? .camera : .photos },
            )
        }
    }

    private var uploadMenu: some View {
        Menu {
            if ScanSource.cameraAvailable {
                Button { source = .camera } label: { Label("Naskenovat doklad", systemImage: "camera.viewfinder") }
            }
            Button { source = .photos } label: { Label("Vybrat z fotek", systemImage: "photo") }
            Button { source = .files } label: { Label("Vybrat ze Souborů", systemImage: "folder") }
        } label: {
            Image(systemName: "plus.circle.fill")
        }
        .accessibilityLabel("Nahrát doklad")
        .disabled(uploader.isUploading)
    }

    private func open(_ scan: Scan) {
        if scan.canCreateInvoice, !viewModel.usedScanIds.contains(scan.id) {
            navManager.createInvoice(companyId: viewModel.companyId, direction: .incoming, scanId: scan.id)
        } else {
            previewScan = scan
        }
    }

    private func upload(_ file: MultipartFile) {
        Task {
            if await uploader.upload(file) {
                await viewModel.refresh()
            }
        }
    }
}

// MARK: - Řádek

private struct ScanRow: View {
    let scan: Scan
    let isUsed: Bool
    @ObservedObject var viewModel: ScansViewModel
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            thumbnailView
                .frame(width: 56, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                if let created = scan.createdDisplay {
                    Text(created)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                stateBadge
            }

            Spacer(minLength: 0)

            if scan.canCreateInvoice, !isUsed {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .card()
        .accessibilityElement(children: .combine)
        // Náhled se načte znovu po změně stavu (čerstvě nahraný sken ho ještě mít nemusí).
        .task(id: scan.stateId) { thumbnail = await viewModel.image(for: scan) }
    }

    private var title: String {
        if let partner = scan.partnerName, !partner.isEmpty {
            if let total = scan.totalPrice, !total.isEmpty { return "\(partner) · \(total)" }
            return partner
        }
        return "Doklad"
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail {
            Image(uiImage: thumbnail).resizable().scaledToFill()
        } else {
            ZStack {
                Color.primary.opacity(0.06)
                Image(systemName: "doc.text").foregroundStyle(.secondary)
            }
        }
    }

    private var stateBadge: some View {
        let linked = scan.actuarialId != nil || isUsed
        let label = linked ? "Faktura vytvořena" : (scan.state?.title ?? scan.stateName ?? "—")
        let icon = linked ? "checkmark.seal.fill" : (scan.state?.systemImage ?? "questionmark.circle")
        let color: Color = linked || scan.state == .processed ? .green : (scan.state == .processing ? .orange : .blue)
        return Label(label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.14), in: Capsule())
            .symbolEffect(.pulse, isActive: scan.state == .processing)
    }
}

// MARK: - Náhled

private struct ScanPreviewSheet: View {
    let scan: Scan
    @ObservedObject var viewModel: ScansViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Group {
                if let image {
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: image).resizable().scaledToFit()
                    }
                } else if failed {
                    ErrorStateView(message: "Náhled se nepodařilo načíst.")
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Náhled dokladu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Hotovo") { dismiss() } }
            }
            .task {
                image = await viewModel.image(for: scan, version: "hd")
                failed = image == nil
            }
        }
    }
}

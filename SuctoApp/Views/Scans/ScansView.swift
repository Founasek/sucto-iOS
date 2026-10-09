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
            ScanPreviewSheet(scan: scan, isUsed: viewModel.usedScanIds.contains(scan.id), viewModel: viewModel) {
                previewScan = nil
                navManager.createInvoice(companyId: viewModel.companyId, direction: .incoming, scanId: scan.id)
            }
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

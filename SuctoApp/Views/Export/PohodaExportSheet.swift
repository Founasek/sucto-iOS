//
//  PohodaExportSheet.swift
//  SuctoApp
//

import SwiftUI

/// Export vydaných faktur do Pohoda XML – buď jedné faktury, nebo všech za období.
struct PohodaExportSheet: View {
    enum Mode {
        case invoice(id: Int, number: String)
        case period
    }

    let mode: Mode
    @StateObject private var viewModel: PohodaExportViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var from = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var to = Date()

    private let direction: InvoiceDirection

    init(companyId: Int, session: SessionManager, direction: InvoiceDirection = .outgoing, mode: Mode) {
        self.mode = mode
        self.direction = direction
        _viewModel = StateObject(wrappedValue: PohodaExportViewModel(companyId: companyId, direction: direction, session: session))
    }

    var body: some View {
        NavigationStack {
            Form {
                switch viewModel.phase {
                case .idle:
                    idleContent
                case let .loading(message, progress):
                    loadingContent(message: message, progress: progress)
                case let .finished(summary):
                    finishedContent(summary)
                case let .failed(message):
                    failedContent(message)
                }
            }
            .navigationTitle("Export do Pohody")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavřít") { dismiss() }
                }
            }
            .task {
                if case let .invoice(id, _) = mode, case .idle = viewModel.phase {
                    await viewModel.exportInvoice(id: id)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(viewModel.isRunning)
    }

    // MARK: - Stavy

    @ViewBuilder
    private var idleContent: some View {
        if case .period = mode {
            Section {
                DatePicker("Vystaveno od", selection: $from, displayedComponents: .date)
                DatePicker("Vystaveno do", selection: $to, displayedComponents: .date)
            } header: {
                Text("Období")
            } footer: {
                Text("Vyexportují se \(direction == .outgoing ? "vydané" : "přijaté") faktury (kromě konceptů a stornovaných) vystavené v tomto období.")
            }

            Section {
                Button {
                    Task { await viewModel.exportPeriod(from: from, to: to) }
                } label: {
                    Label("Vytvořit soubor pro Pohodu", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    private func loadingContent(message: String, progress: Double?) -> some View {
        Section {
            VStack(spacing: Theme.Spacing.m) {
                if let progress {
                    ProgressView(value: progress)
                } else {
                    ProgressView()
                }
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.l)
        }
    }

    @ViewBuilder
    private func finishedContent(_ summary: PohodaExportViewModel.Summary) -> some View {
        Section {
            VStack(spacing: Theme.Spacing.m) {
                Image(systemName: summary.exportedCount > 0 ? "checkmark.circle.fill" : "tray")
                    .font(.system(size: 44))
                    .foregroundStyle(summary.exportedCount > 0 ? Color.accentColor : Color.secondary)
                    .symbolEffect(.bounce, value: summary.exportedCount)
                Text(resultTitle(summary))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                if summary.skippedCount > 0 {
                    Text("Vynecháno \(summary.skippedCount) konceptů a stornovaných faktur.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.s)
        }

        if let file = summary.file {
            Section {
                ShareLink(item: file) {
                    Label("Sdílet nebo uložit soubor", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } footer: {
                Text("V Pohodě: Soubor → Datová komunikace → XML import. IČ firmy v Pohodě musí odpovídat IČ vaší firmy.")
            }
        }

        if !summary.failures.isEmpty {
            Section("Nepodařilo se převést") {
                ForEach(summary.failures) { failure in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(failure.number).font(.subheadline.weight(.semibold))
                        Text(failure.reason).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func failedContent(_ message: String) -> some View {
        Section {
            VStack(spacing: Theme.Spacing.m) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                Text(message)
                    .multilineTextAlignment(.center)
                Button("Zkusit znovu") {
                    Task { await retry() }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.m)
        }
    }

    private func resultTitle(_ summary: PohodaExportViewModel.Summary) -> String {
        switch summary.exportedCount {
        case 0: "Žádné faktury k exportu"
        case 1: "Vyexportována 1 faktura"
        case 2 ... 4: "Vyexportovány \(summary.exportedCount) faktury"
        default: "Vyexportováno \(summary.exportedCount) faktur"
        }
    }

    private func retry() async {
        switch mode {
        case let .invoice(id, _): await viewModel.exportInvoice(id: id)
        case .period: await viewModel.exportPeriod(from: from, to: to)
        }
    }
}

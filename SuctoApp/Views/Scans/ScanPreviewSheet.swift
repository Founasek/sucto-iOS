//
//  ScanPreviewSheet.swift
//  SuctoApp
//

import SwiftUI

struct ScanPreviewSheet: View {
    let scan: Scan
    let isUsed: Bool
    @ObservedObject var viewModel: ScansViewModel
    /// Vytvoří z dokladu přijatou fakturu (otevře formulář).
    let onCreateInvoice: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var failed = false

    private var isLinked: Bool { scan.actuarialId != nil || isUsed }

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
            .safeAreaInset(edge: .bottom) { statusBar }
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

    /// Proč se z klepnutí otevřel náhled a ne formulář faktury – a co s dokladem jde dělat dál.
    @ViewBuilder
    private var statusBar: some View {
        VStack(spacing: Theme.Spacing.s) {
            if isLinked {
                Label("Z tohoto dokladu už faktura vznikla.", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                Button("Vytvořit fakturu znovu", action: onCreateInvoice)
                    .buttonStyle(.bordered)
            } else if scan.isPending {
                Label(scan.state == .processing ? "Doklad se zpracovává." : "Doklad čeká na zpracování.", systemImage: "hourglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                Text("Fakturu z něj půjde vytvořit, jakmile bude zpracovaný. Stav se v seznamu obnovuje sám.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Zkusit předvyplnit i tak", action: onCreateInvoice)
                    .buttonStyle(.bordered)
                    .accessibilityHint("Požádá server o údaje z dokladu, ještě nemusí být k dispozici")
            } else if scan.state == .processed {
                Button("Vytvořit přijatou fakturu", action: onCreateInvoice)
                    .buttonStyle(.primary)
            }
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}

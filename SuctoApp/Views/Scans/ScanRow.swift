//
//  ScanRow.swift
//  SuctoApp
//

import SwiftUI

struct ScanRow: View {
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

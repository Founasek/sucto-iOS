//
//  CopyableRow.swift
//  SuctoApp
//

import SwiftUI

/// Řádek, jehož hodnotu lze klepnutím zkopírovat do schránky.
struct CopyableRow: View {
    let label: String
    let value: String?
    @State private var copied = false

    var body: some View {
        if let value, !value.isEmpty {
            Button {
                UIPasteboard.general.string = value
                copied = true
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    copied = false
                }
            } label: {
                HStack {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(copied ? "Zkopírováno" : value)
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(copied ? Color.accentColor : Color.primary)
                        .multilineTextAlignment(.trailing)
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(copied ? Color.accentColor : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: copied) { _, new in new }
            .animation(.snappy, value: copied)
            .accessibilityHint("Zkopíruje hodnotu do schránky")
        }
    }
}

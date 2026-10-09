//
//  PartnerContactRow.swift
//  SuctoApp
//

import SwiftUI

/// Řádek kontaktu; klepnutím otevře poštu / telefon / prohlížeč.
struct ContactRow: View {
    let label: String
    let value: String?
    /// `nil` = web (adresa se doplní o `https://`, pokud chybí).
    let scheme: String?
    let systemImage: String

    var body: some View {
        if let value, !value.isEmpty, let url = url(for: value) {
            Link(destination: url) {
                HStack {
                    Label(label, systemImage: systemImage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                        .multilineTextAlignment(.trailing)
                }
                .contentShape(Rectangle())
            }
            .accessibilityHint("Otevře \(label.lowercased())")
        }
    }

    private func url(for value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if let scheme {
            return URL(string: scheme + trimmed.replacingOccurrences(of: " ", with: ""))
        }
        return URL(string: trimmed.contains("://") ? trimmed : "https://\(trimmed)")
    }
}

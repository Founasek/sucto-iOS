//
//  DetailCard.swift
//  SuctoApp
//

import SwiftUI

/// Karta s nadpisem sekce používaná na detailu faktury.
struct DetailCard<Content: View>: View {
    let title: String?
    var systemImage: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if let title {
                HStack(spacing: Theme.Spacing.s) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(title.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                    Spacer()
                }
                .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .card()
    }
}

/// Řádek „popisek – hodnota“. Prázdné hodnoty se nezobrazí, pokud `hideWhenEmpty`.
struct DetailRow: View {
    let label: String
    let value: String?
    var valueColor: Color = .primary
    var bold = false
    var hideWhenEmpty = false

    var body: some View {
        if !(hideWhenEmpty && (value ?? "").isEmpty) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                // Hodnota zabere zbytek šířky a zalomí se (i dlouhý řetězec bez mezer), nikdy nepřeteče.
                Text(value ?? "-")
                    .font(.subheadline)
                    .fontWeight(bold ? .bold : .regular)
                    .foregroundStyle(valueColor)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

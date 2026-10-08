//
//  ErrorStateView.swift
//  SuctoApp
//
//  Created by Jan Founě on 01.11.2025.
//

import SwiftUI

struct ErrorStateView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 38))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text("Něco se nepovedlo")
                    .font(.title3.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Spacing.xl)

            if let retryAction {
                Button(action: retryAction) {
                    Label("Zkusit znovu", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 420)
        .accessibilityElement(children: .contain)
    }
}

#Preview("Chyba s tlačítkem") {
    ErrorStateView(
        message: "Nepodařilo se načíst fakturu. Zkontrolujte připojení a zkuste to znovu.",
        retryAction: {},
    )
}

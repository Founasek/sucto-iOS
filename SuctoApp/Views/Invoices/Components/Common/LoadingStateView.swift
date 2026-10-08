//
//  LoadingStateView.swift
//  SuctoApp
//
//  Created by Jan Founě on 01.11.2025.
//

import SwiftUI

struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            ProgressView()
                .controlSize(.large)
                .tint(.accentColor)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 420)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Načítání") {
    LoadingStateView(message: "Načítám faktury…")
}

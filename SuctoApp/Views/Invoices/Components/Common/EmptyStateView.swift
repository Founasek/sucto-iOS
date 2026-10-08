//
//  EmptyStateView.swift
//  SuctoApp
//
//  Created by Jan Founě on 31.10.2025.
//

import SwiftUI

struct EmptyStateView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounce = false
    let systemImage: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            ZStack {
                Circle()
                    .fill(Theme.brand.opacity(0.14))
                    .frame(width: 96, height: 96)
                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(Color.accentColor)
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.bounce, options: .nonRepeating, value: bounce)
            }
            .appear(scale: 0.7)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 420)
        .onAppear {
            guard !reduceMotion else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                bounce.toggle()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Žádná data") {
    EmptyStateView(
        systemImage: "doc.text.magnifyingglass",
        message: "Žádné faktury nejsou k dispozici.",
    )
}

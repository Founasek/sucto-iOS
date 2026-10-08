//
//  OfflineBanner.swift
//  SuctoApp
//

import SwiftUI

/// Upozornění, že se zobrazují uložená data, protože server není dostupný.
struct OfflineBanner: View {
    let date: Date?

    var body: some View {
        if let date {
            Label("Offline · data z \(date.formatted(.dateTime.day().month().hour().minute()))", systemImage: "icloud.slash")
                .font(.footnote.weight(.medium))
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.s)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
                .padding(.bottom, Theme.Spacing.s)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityElement(children: .combine)
        }
    }
}

private struct OfflineBannerModifier: ViewModifier {
    @EnvironmentObject private var session: SessionManager

    /// Inset leží uvnitř obrazovky, takže ho systém postaví nad spodní vyhledávací pole i další spodní lišty.
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            OfflineBanner(date: session.cachedDataDate)
                .animation(.snappy, value: session.cachedDataDate)
        }
    }
}

extension View {
    /// Pruh „Offline · data z …“ nad spodním okrajem obrazovky.
    func offlineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}

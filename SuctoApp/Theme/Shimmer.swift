//
//  Shimmer.swift
//  SuctoApp
//

import SwiftUI

private struct Shimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing,
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: proxy.size.width * phase)
                        .blendMode(.plusLighter)
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}

/// Kostra seznamu faktur zobrazená při prvním načítání.
struct InvoiceListSkeleton: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            ForEach(0 ..< 5, id: \.self) { _ in
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack {
                        RoundedRectangle(cornerRadius: 6).frame(width: 110, height: 16)
                        Spacer()
                        Capsule().frame(width: 80, height: 22)
                    }
                    RoundedRectangle(cornerRadius: 6).frame(width: 170, height: 14)
                    RoundedRectangle(cornerRadius: 6).frame(width: 130, height: 22)
                }
                .foregroundStyle(Color.primary.opacity(0.08))
                .card()
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .shimmer()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Načítám faktury")
    }
}

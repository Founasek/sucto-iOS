//
//  PaymentSuccessOverlay.swift
//  SuctoApp
//

import SwiftUI

private struct Checkmark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.midY + rect.height * 0.02))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.43, y: rect.maxY - rect.height * 0.28))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.22, y: rect.minY + rect.height * 0.30))
        return path
    }
}

/// Potvrzení úhrady: kroužek se dokreslí, objeví se fajfka a vlna.
struct PaymentSuccessOverlay: View {
    var title = "Zaplaceno"
    let message: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ring: CGFloat = 0
    @State private var check: CGFloat = 0
    @State private var pulse = false

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            ZStack {
                Circle()
                    .stroke(Theme.brand.opacity(0.35), lineWidth: 3)
                    .scaleEffect(pulse ? 1.6 : 1)
                    .opacity(pulse ? 0 : 0.8)

                Circle()
                    .trim(from: 0, to: ring)
                    .stroke(Theme.brandGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Checkmark()
                    .trim(from: 0, to: check)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 96, height: 96)

            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.title2.weight(.bold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.xxl)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 30, y: 12)
        .onAppear {
            if reduceMotion {
                ring = 1
                check = 1
                return
            }
            withAnimation(.easeOut(duration: 0.55)) { ring = 1 }
            withAnimation(.easeOut(duration: 0.35).delay(0.4)) { check = 1 }
            withAnimation(.easeOut(duration: 0.9).delay(0.55)) { pulse = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    PaymentSuccessOverlay(message: "Doklad č. 42")
}

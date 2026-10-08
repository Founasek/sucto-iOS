//
//  Motion.swift
//  SuctoApp
//
//  Pravidla pohybu: jednotné pružiny a časování, vše respektuje „Omezit pohyb“.
//

import SwiftUI

enum Motion {
    /// Běžné přechody a přepínání (rychlé, bez přestřelení).
    static let standard = Animation.snappy(duration: 0.35)
    /// Pomalejší, měkký pohyb (čísla, větší plochy).
    static let gentle = Animation.smooth(duration: 0.7)
    /// Hravý vstup prvků s drobným přestřelením.
    static let bouncy = Animation.spring(response: 0.55, dampingFraction: 0.68)
}

// MARK: - Vstup prvku

private struct AppearModifier: ViewModifier {
    let delay: Double
    let offset: CGFloat
    let scale: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(shown ? 1 : scale)
            .offset(y: shown ? 0 : offset)
            .onAppear {
                guard !shown else { return }
                if reduceMotion {
                    shown = true
                } else {
                    withAnimation(Motion.bouncy.delay(delay)) { shown = true }
                }
            }
    }
}

extension View {
    /// Prvek při prvním zobrazení vyjede (zprůhlední → zprůhlední, posune, zvětší) se zpožděním pro „kaskádu“.
    func appear(delay: Double = 0, offset: CGFloat = 18, scale: CGFloat = 0.96) -> some View {
        modifier(AppearModifier(delay: delay, offset: offset, scale: scale))
    }

    /// Kaskádový vstup pro položky seznamu – jen první obrazovka, aby se při rolování nerozbíhalo pořád dokola.
    @ViewBuilder
    func staggeredAppear(index: Int, limit: Int = 8) -> some View {
        if index < limit {
            appear(delay: Double(index) * 0.05, offset: 22)
        } else {
            self
        }
    }
}

// MARK: - Živé pozadí

/// Pomalu „dýchající“ gradient. Při „Omezit pohyb“ zůstane statický.
struct AnimatedMeshBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            mesh(time: 0)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                mesh(time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func mesh(time: TimeInterval) -> some View {
        let drift = { (speed: Double, phase: Double, amount: Double) -> Float in
            Float(sin(time * speed + phase) * amount)
        }
        return MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5 + drift(0.4, 0, 0.08), 0], [1, 0],
                [0, 0.5 + drift(0.3, 1, 0.08)], [0.6 + drift(0.35, 2, 0.15), 0.45 + drift(0.28, 4, 0.12)], [1, 0.5 + drift(0.33, 3, 0.08)],
                [0, 1], [0.5 + drift(0.37, 5, 0.08), 1], [1, 1],
            ],
            colors: [
                Theme.ink, Theme.inkSoft, Theme.ink,
                Theme.inkSoft, Color(hex: "#1F7A45"), Theme.inkSoft,
                Theme.ink, Theme.inkSoft, Color(hex: "#0A1F14"),
            ],
        )
        .ignoresSafeArea()
    }
}

// MARK: - Částka s „odpočtem“

/// Částka, jejíž číslice se po zobrazení otočí z nuly na cílovou hodnotu.
struct AnimatedAmount: View {
    let value: String?
    let currency: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        Text(FormatterHelper.formatPrice(revealed ? value : "0", currency: currency))
            .contentTransition(.numericText())
            .animation(Motion.gentle, value: value)
            .onAppear {
                if reduceMotion {
                    revealed = true
                } else {
                    withAnimation(Motion.gentle.delay(0.25)) { revealed = true }
                }
            }
    }
}

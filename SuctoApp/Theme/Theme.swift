//
//  Theme.swift
//  SuctoApp
//
//  Designový systém aplikace: rozestupy, zaoblení, barvy, karty a haptika.
//

import SwiftUI

enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let chip: CGFloat = 10
        static let card: CGFloat = 20
        static let control: CGFloat = 14
    }

    /// Značková zelená (světlá) – dekorace, přechody, ikony.
    static let brand = Color(hex: "#55B560")
    /// Tmavá „inkoustová“ zelená pro hero plochy a tmavé přechody.
    static let ink = Color(hex: "#0E2A1C")
    static let inkSoft = Color(hex: "#17402B")

    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)

    static let brandGradient = LinearGradient(
        colors: [Color(hex: "#2F9E55"), Color(hex: "#1B6B3D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
    )
}

// MARK: - Karta

private struct CardStyle: ViewModifier {
    var padding: CGFloat = Theme.Spacing.l

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5),
            )
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

extension View {
    /// Zaoblená karta se stínem a jemným okrajem.
    func card(padding: CGFloat = Theme.Spacing.l) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Šířka obsahu

extension View {
    /// Obsah `ScrollView` je vždy přesně tak široký jako obrazovka. Dlouhý text bez mezer (název firmy, e-mail, IBAN)
    /// nebo pevně široká tabulka ho tak nemůže roztáhnout za okraj, což by umožnilo posouvat stránku do stran.
    func fitsScreenWidth() -> some View {
        containerRelativeFrame(.horizontal)
    }
}

// MARK: - Peníze

extension Text {
    /// Číslice stejné šířky a zaoblené písmo – částky se v seznamech zarovnávají a čtou se rychleji.
    func moneyStyle(_ font: Font = .headline) -> some View {
        self.font(font.weight(.semibold))
            .fontDesign(.rounded)
            .monospacedDigit()
    }
}

// MARK: - Tlačítka

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Theme.brandGradient.opacity(isEnabled ? 1 : 0.4),
                in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous),
            )
            .shadow(color: Theme.brand.opacity(isEnabled ? 0.35 : 0), radius: 10, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

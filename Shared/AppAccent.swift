//
//  AppAccent.swift
//  Sdílený kód aplikace a widgetu: volitelná barva aplikace.
//

import SwiftUI

/// Předvolby barvy aplikace. Z každé se odvozuje celá paleta (tint, přechody, tmavé plochy), aby se vzhled
/// neskládal z náhodných odstínů. Výchozí je původní zelená.
enum AppAccent: String, CaseIterable, Identifiable {
    case green, blue, teal, purple, rose, orange, graphite

    var id: String { rawValue }

    static let storageKey = "appearance.accent"

    /// Aktuální volba. Čte se ze sdíleného úložiště, aby ji viděl i widget.
    static var current: AppAccent {
        get {
            let raw = DueSnapshotStore.sharedDefaults.string(forKey: storageKey) ?? ""
            return AppAccent(rawValue: raw) ?? .green
        }
        set { DueSnapshotStore.sharedDefaults.set(newValue.rawValue, forKey: storageKey) }
    }

    var title: String {
        switch self {
        case .green: "Zelená"
        case .blue: "Modrá"
        case .teal: "Tyrkysová"
        case .purple: "Fialová"
        case .rose: "Růžová"
        case .orange: "Oranžová"
        case .graphite: "Grafitová"
        }
    }

    /// Odstíny jedné předvolby (hex bez `#`).
    struct Palette {
        /// Barva ovládacích prvků a ikon ve světlém a tmavém režimu.
        let tintLight: String
        let tintDark: String
        /// Světlejší značková barva – dekorace, stíny, podklady ikon.
        let brand: String
        /// Přechod hero ploch a primárních tlačítek (bílý text musí být čitelný).
        let gradientStart: String
        let gradientEnd: String
        /// Tmavé plochy (mesh pozadí, zamykací obrazovka).
        let ink: String
        let inkSoft: String
        let meshHighlight: String
        let meshDeep: String
        /// Záře kolem tlačítek a indikátoru na zamykací obrazovce.
        let glow: String
        let glowSoft: String
    }

    var palette: Palette {
        switch self {
        case .green:
            Palette(
                tintLight: "2A7F45", tintDark: "5FCB7B", brand: "55B560",
                gradientStart: "2F9E55", gradientEnd: "1B6B3D",
                ink: "0E2A1C", inkSoft: "17402B", meshHighlight: "1F7A45", meshDeep: "0A1F14",
                glow: "7DFFB0", glowSoft: "4CD48A",
            )
        case .blue:
            Palette(
                tintLight: "2563EB", tintDark: "6EA8FF", brand: "4C8DF6",
                gradientStart: "3B82F6", gradientEnd: "1D4ED8",
                ink: "0E1E3A", inkSoft: "172B52", meshHighlight: "2456B8", meshDeep: "0A1428",
                glow: "9CC4FF", glowSoft: "6FA3F5",
            )
        case .teal:
            Palette(
                tintLight: "0F766E", tintDark: "4FD1C5", brand: "14B8A6",
                gradientStart: "14A39A", gradientEnd: "0B6B66",
                ink: "0B2A2A", inkSoft: "123F3E", meshHighlight: "0F7A74", meshDeep: "071C1C",
                glow: "8DF5E6", glowSoft: "4FD8C6",
            )
        case .purple:
            Palette(
                tintLight: "7C3AED", tintDark: "B79CFF", brand: "8B5CF6",
                gradientStart: "8B5CF6", gradientEnd: "5B21B6",
                ink: "1D1235", inkSoft: "2B1A4F", meshHighlight: "5B2FB8", meshDeep: "120A24",
                glow: "C9B2FF", glowSoft: "A98BF5",
            )
        case .rose:
            Palette(
                tintLight: "BE185D", tintDark: "FF8FB8", brand: "EC4899",
                gradientStart: "DB2777", gradientEnd: "9D174D",
                ink: "2E0F1E", inkSoft: "471730", meshHighlight: "A3205C", meshDeep: "1F0913",
                glow: "FFB3D1", glowSoft: "FF85B5",
            )
        case .orange:
            Palette(
                tintLight: "C2570C", tintDark: "FFA05C", brand: "F28C28",
                gradientStart: "E8741A", gradientEnd: "B4500A",
                ink: "2E1A0B", inkSoft: "47270F", meshHighlight: "A9570F", meshDeep: "1F1006",
                glow: "FFD09A", glowSoft: "FFB066",
            )
        case .graphite:
            Palette(
                tintLight: "374151", tintDark: "D1D5DB", brand: "6B7280",
                gradientStart: "4B5563", gradientEnd: "1F2937",
                ink: "111418", inkSoft: "1F242B", meshHighlight: "3A424D", meshDeep: "0A0C0F",
                glow: "E5E7EB", glowSoft: "9CA3AF",
            )
        }
    }

    /// Barva prvků – v tmavém režimu světlejší, aby měla dost kontrastu.
    var tint: Color {
        let p = palette
        return Color(UIColor { traits in
            UIColor(hexString: traits.userInterfaceStyle == .dark ? p.tintDark : p.tintLight)
        })
    }

    /// Protiváha k barvě aplikace pro náklady / přijaté (výnosy a vydané mají barvu aplikace). Oranžová, kdyby
    /// splývala s barvou aplikace, se nahradí modrou.
    var contrast: Color { self == .orange ? Color(hexString: "3B82F6") : Color(hexString: "F28C28") }

    var brand: Color { Color(hexString: palette.brand) }
    var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(hexString: palette.gradientStart), Color(hexString: palette.gradientEnd)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
    }
    var ink: Color { Color(hexString: palette.ink) }
    var inkSoft: Color { Color(hexString: palette.inkSoft) }
    var meshHighlight: Color { Color(hexString: palette.meshHighlight) }
    var meshDeep: Color { Color(hexString: palette.meshDeep) }
    var glow: Color { Color(hexString: palette.glow) }
    var glowSoft: Color { Color(hexString: palette.glowSoft) }
}

// MARK: - Hex

private func rgbComponents(_ hex: String) -> (Double, Double, Double) {
    var rgb: UInt64 = 0
    Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&rgb)
    return (Double((rgb >> 16) & 0xFF) / 255, Double((rgb >> 8) & 0xFF) / 255, Double(rgb & 0xFF) / 255)
}

private extension Color {
    init(hexString: String) {
        let (r, g, b) = rgbComponents(hexString)
        self.init(red: r, green: g, blue: b)
    }
}

private extension UIColor {
    convenience init(hexString: String) {
        let (r, g, b) = rgbComponents(hexString)
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

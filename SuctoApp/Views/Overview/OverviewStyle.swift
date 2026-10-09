//
//  OverviewStyle.swift
//  SuctoApp
//

import SwiftUI

/// Společné popisky a barvy přehledu.
enum OverviewStyle {
    static let shortMonths = ["led", "úno", "bře", "dub", "kvě", "čvn", "čvc", "srp", "zář", "říj", "lis", "pro"]
    static let longMonths = ["Leden", "Únor", "Březen", "Duben", "Květen", "Červen", "Červenec", "Srpen", "Září", "Říjen", "Listopad", "Prosinec"]
    static let revenueColor = Color(hex: "#2FAE5D")
    static let costColor = Color(hex: "#F28C28")

    static func compact(_ value: Double) -> String {
        let magnitude = abs(value)
        let sign = value < 0 ? "-" : ""
        switch magnitude {
        case 1_000_000...: return "\(sign)\(String(format: "%.1f", magnitude / 1_000_000).replacingOccurrences(of: ".", with: ",")) mil."
        case 10000...: return "\(sign)\(Int(magnitude / 1000)) tis."
        case 1000...: return "\(sign)\(String(format: "%.1f", magnitude / 1000).replacingOccurrences(of: ".", with: ",")) tis."
        default: return "\(Int(value))"
        }
    }
}

/// Popisky podle zdroje dat (účetní deník × přehled z faktur).
struct OverviewLabels {
    let isAccounting: Bool

    var revenue: String { isAccounting ? "Výnosy" : "Vydané" }
    var cost: String { isAccounting ? "Náklady" : "Přijaté" }
    var result: String { isAccounting ? "Hospodářský výsledek" : "Saldo faktur" }
    /// Vysvětlení výpočtu pod nadpisem karty (jen u přehledu z faktur).
    var resultHint: String? { isAccounting ? nil : "vydané − přijaté faktury, bez DPH" }
    var positive: String { isAccounting ? "Zisk" : "Převaha vydaných" }
    var negative: String { isAccounting ? "Ztráta" : "Převaha přijatých" }
}

enum OverviewComparison {
    /// „+12 %“ / „−5 %“ (typografické mínus), bez desetinných míst nad 10 %.
    static func format(_ value: Double) -> String {
        let magnitude = abs(value)
        let text = magnitude >= 10 ? String(format: "%.0f", magnitude) : String(format: "%.1f", magnitude).replacingOccurrences(of: ".", with: ",")
        return (value < 0 ? "\u{2212}" : "+") + text + " %"
    }
}

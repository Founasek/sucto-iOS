//
//  DevCredentials.swift
//  SuctoApp
//

import Foundation

/// Předvyplnění přihlášení při vývoji v simulátoru.
///
/// Hodnoty se čtou z proměnných prostředí `SUCTO_EMAIL` a `SUCTO_PASSWORD`, které se nastaví
/// v Xcode: Product → Scheme → Edit Scheme… → Run → Arguments → Environment Variables.
/// Uloží se do `xcuserdata` (je v .gitignore), takže se nedostanou do repozitáře.
/// V Release buildu se nepoužijí vůbec.
enum DevCredentials {
    static var email: String { value(for: "SUCTO_EMAIL") }
    static var password: String { value(for: "SUCTO_PASSWORD") }

    private static func value(for key: String) -> String {
        #if DEBUG
            ProcessInfo.processInfo.environment[key] ?? ""
        #else
            ""
        #endif
    }
}

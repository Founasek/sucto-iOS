//
//  ThemeManager.swift
//  SuctoApp
//

import Observation
import SwiftUI
import WidgetKit

/// Drží zvolenou barvu aplikace. Hodnotu ukládá do sdíleného úložiště (čte ji i widget) a po změně
/// obnoví widgety. Je `@Observable`: každé view, které při vykreslení přečte `Theme.…`, se po změně barvy
/// samo překreslí, aniž by se zahodil jeho stav.
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var accent: AppAccent {
        didSet {
            guard accent != oldValue else { return }
            AppAccent.current = accent
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private init() {
        accent = AppAccent.current
    }
}

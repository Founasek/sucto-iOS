//
//  ThemeManager.swift
//  SuctoApp
//

import SwiftUI
import WidgetKit

/// Drží zvolenou barvu aplikace. Hodnotu ukládá do sdíleného úložiště (čte ji i widget) a po změně
/// obnoví widgety.
@MainActor
final class ThemeManager: ObservableObject {
    @Published var accent: AppAccent {
        didSet {
            guard accent != oldValue else { return }
            AppAccent.current = accent
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    init() {
        accent = AppAccent.current
    }
}

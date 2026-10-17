//
//  LockWindowController.swift
//  SuctoApp
//

import Combine
import SwiftUI
import UIKit

/// Zamčená obrazovka a krytí v přepínači aplikací v samostatném okně nad celou aplikací.
/// Překryv uvnitř SwiftUI hierarchie by nepřekryl okna (sheety), která se zobrazují nad kořenem: otevřený sheet by byl
/// vidět v přepínači aplikací a po návratu použitelný bez ověření. Samostatné `UIWindow` s vyšší úrovní je překryje všechna.
@MainActor
final class LockWindowController: ObservableObject {
    private let lock: AppLock
    private var window: UIWindow?
    private var cancellables = Set<AnyCancellable>()

    private var isLoggedIn = false
    private var isInactive = false
    private var isLocked: Bool
    private var isEnabled: Bool
    /// Číslo posledního zobrazení – dozvuk zmizení nesmí schovat okno, které se mezitím zobrazilo znovu.
    private var generation = 0

    init(lock: AppLock) {
        self.lock = lock
        isLocked = lock.isLocked
        isEnabled = lock.isEnabled
        lock.$isLocked.sink { [weak self] in self?.isLocked = $0; self?.refresh() }.store(in: &cancellables)
        lock.$isEnabled.sink { [weak self] in self?.isEnabled = $0; self?.refresh() }.store(in: &cancellables)
        // Synchronně při odchodu z popředí, ještě před snímkem pro přepínač aplikací (stav scény přichází později).
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.setInactive(true) }.store(in: &cancellables)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.setInactive(false) }.store(in: &cancellables)
    }

    func setLoggedIn(_ value: Bool) {
        isLoggedIn = value
        refresh()
    }

    func setInactive(_ value: Bool) {
        isInactive = value
        refresh()
    }

    private var shouldCover: Bool { isLoggedIn && isEnabled && (isLocked || isInactive) }

    private func refresh() {
        if shouldCover { show() } else { hide() }
    }

    private func show() {
        generation += 1
        if let window, !window.isHidden {
            window.alpha = 1
            return
        }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
        let window = self.window ?? UIWindow(windowScene: scene)
        if self.window == nil {
            window.windowLevel = .alert + 1
            window.rootViewController = UIHostingController(rootView: LockScreen(lock: lock))
            self.window = window
        }
        // Rozepsaný text pod zamčenou obrazovkou by nechal otevřenou klávesnici.
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        window.alpha = 1
        window.makeKeyAndVisible()
    }

    private func hide() {
        guard let window, !window.isHidden else { return }
        let current = generation
        UIView.animate(withDuration: 0.25, animations: { window.alpha = 0 }) { [weak self] _ in
            guard let self, generation == current else { return }
            window.isHidden = true
            // Klávesnice a výběr se vrací do okna aplikace.
            window.windowScene?.windows.first { $0 !== window && $0.windowLevel == .normal }?.makeKey()
        }
    }
}

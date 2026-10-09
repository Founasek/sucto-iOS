//
//  AppLockOverlay.swift
//  SuctoApp
//

import SwiftUI

/// Překryv, který skryje obsah aplikace: zamčená obrazovka po návratu z pozadí a krytí v přepínači aplikací.
struct AppLockOverlay: View {
    @ObservedObject var lock: AppLock
    let isCovered: Bool

    var body: some View {
        ZStack {
            if lock.isEnabled, lock.isLocked || isCovered {
                LockScreen(lock: lock)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: lock.isLocked)
        .animation(.easeInOut(duration: 0.25), value: isCovered)
    }
}

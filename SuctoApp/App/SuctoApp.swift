//
//  SuctoApp.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

@main
struct SuctoApp: App {
    @StateObject private var session = SessionManager()
    @StateObject private var navManager = NavigationManager()
    @StateObject private var appLock = AppLock()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navManager.path) {
                Group {
                    if session.isLoggedIn {
                        RootView()
                    } else {
                        LoginView()
                    }
                }
                .onChange(of: session.isLoggedIn) { _, newValue in
                    if newValue {
                        appLock.markUnlocked()
                    } else {
                        navManager.reset()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                OfflineBanner(date: session.cachedDataDate)
            }
            // Na úrovni NavigationStack, aby je dostaly i obrazovky otevřené přes navigationDestination
            // (ty prostředí z kořenového view nedědí).
            .environmentObject(session)
            .environmentObject(navManager)
            .environmentObject(appLock)
            .accessibilityHidden(isCovered)
            .overlay {
                if session.isLoggedIn {
                    AppLockOverlay(lock: appLock, isCovered: scenePhase != .active)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background:
                    appLock.lock()
                case .active:
                    if session.isLoggedIn, appLock.isLocked {
                        Task { await appLock.unlock() }
                    }
                default:
                    break
                }
            }
            .task {
                if session.isLoggedIn, appLock.isLocked {
                    await appLock.unlock()
                }
            }
        }
    }

    private var isCovered: Bool {
        session.isLoggedIn && appLock.isEnabled && (appLock.isLocked || scenePhase != .active)
    }
}

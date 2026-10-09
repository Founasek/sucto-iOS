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
    @StateObject private var permissions = PermissionsStore()
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
                        permissions.reset()
                    }
                }
            }
            // Na úrovni NavigationStack, aby je dostaly i obrazovky otevřené přes navigationDestination
            // (ty prostředí z kořenového view nedědí).
            .environmentObject(session)
            .environmentObject(navManager)
            .environmentObject(appLock)
            .environmentObject(permissions)
            .accessibilityHidden(isCovered)
            .overlay {
                if session.isLoggedIn {
                    AppLockOverlay(lock: appLock, isCovered: scenePhase != .active)
                }
            }
            .onOpenURL { url in
                Task { await openOverdue(from: url) }
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background:
                    appLock.lock()
                case .active:
                    if session.isLoggedIn, appLock.isLocked {
                        Task { await appLock.unlockAutomatically() }
                    }
                default:
                    break
                }
            }
            .task {
                if session.isLoggedIn, appLock.isLocked {
                    await appLock.unlockAutomatically()
                }
            }
        }
    }

    /// Odkaz z widgetu (`sucto://overdue?...`): otevře firmu na seznamu faktur po splatnosti.
    private func openOverdue(from url: URL) async {
        guard session.isLoggedIn, let link = DueLink.parse(url) else { return }
        if session.selectedCompany?.id != link.companyId {
            let companies: [Company]? = try? await session.send(APIConstants.companies)
            guard let company = companies?.first(where: { $0.id == link.companyId }) else { return }
            session.selectedCompany = company
        }
        navManager.reset()
        navManager.pendingTarget = .init(isIncoming: link.isIncoming)
        navManager.goToDashboard(companyId: link.companyId)
    }

    private var isCovered: Bool {
        session.isLoggedIn && appLock.isEnabled && (appLock.isLocked || scenePhase != .active)
    }
}

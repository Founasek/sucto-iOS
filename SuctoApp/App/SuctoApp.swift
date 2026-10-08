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
                    if !newValue {
                        navManager.reset()
                    }
                }
            }
            // Na úrovni NavigationStack, aby je dostaly i obrazovky otevřené přes navigationDestination
            // (ty prostředí z kořenového view nedědí).
            .environmentObject(session)
            .environmentObject(navManager)
        }
    }
}

//
//  SuctoAppApp.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

// SuctoApp.swift
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
                            .environmentObject(session)
                            .environmentObject(navManager)
                    } else {
                        LoginView()
                            .environmentObject(session)
                    }
                }
                .onChange(of: session.isLoggedIn) { _, newValue in
                    if !newValue {
                        print("🔁 User logged out → resetting navigation")
                        navManager.reset()
                    }
                }
            }
        }
    }
}

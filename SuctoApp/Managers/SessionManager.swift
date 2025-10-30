//
//  SessionManager.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

@MainActor
class SessionManager: ObservableObject {
    @AppStorage("authToken") private var storedToken: String?

    @Published var authToken: String? {
        didSet {
            storedToken = authToken
            isLoggedIn = authToken != nil
            print("🌀 authToken changed → isLoggedIn: \(isLoggedIn)")
        }
    }

    @Published private(set) var isLoggedIn: Bool = false

    @Published var selectedCompanyId: Int?

    init() {
        authToken = storedToken
        isLoggedIn = storedToken != nil
    }

    func login(token: String) {
        authToken = token
    }

    func logout() {
        authToken = nil
        isLoggedIn = false
        print("🚪 User logged out (token expired or manual logout)")
    }
}

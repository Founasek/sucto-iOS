//
//  SessionManager.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

@MainActor
final class SessionManager: ObservableObject {
    private static let tokenKey = "authToken"

    @Published private(set) var authToken: String?
    @Published var selectedCompany: Company?

    var isLoggedIn: Bool { authToken != nil }

    init() {
        authToken = KeychainStore.read(Self.tokenKey) ?? Self.migrateLegacyToken()
    }

    func login(token: String) {
        KeychainStore.write(token, for: Self.tokenKey)
        authToken = token
    }

    func logout() {
        KeychainStore.delete(Self.tokenKey)
        authToken = nil
        selectedCompany = nil
    }

    /// Autorizovaný požadavek. Při 401 odhlásí uživatele a chybu pošle dál.
    func send<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
    ) async throws -> T {
        guard let token = authToken else {
            logout()
            throw APIError.unauthorized
        }
        do {
            return try await APIService.shared.request(endpoint: endpoint, method: method, token: token, body: body)
        } catch APIError.unauthorized {
            logout()
            throw APIError.unauthorized
        }
    }

    /// Dřívější verze ukládaly token do UserDefaults (@AppStorage) – přesune ho do Keychainu.
    private static func migrateLegacyToken() -> String? {
        let defaults = UserDefaults.standard
        guard let legacy = defaults.string(forKey: tokenKey) else { return nil }
        KeychainStore.write(legacy, for: tokenKey)
        defaults.removeObject(forKey: tokenKey)
        return legacy
    }
}

//
//  SessionManager.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI
import WidgetKit

@MainActor
final class SessionManager: ObservableObject {
    private static let tokenKey = "authToken"

    @Published private(set) var authToken: String?
    @Published var selectedCompany: Company?
    /// Nastaveno, pokud poslední čtení skončilo výpadkem připojení a zobrazila se uložená data.
    @Published private(set) var cachedDataDate: Date?

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
        ResponseCache.shared.clear()
        DueSnapshotStore.clear()
        DueNotifier.shared.cancelAll()
        WidgetCenter.shared.reloadAllTimelines()
        authToken = nil
        selectedCompany = nil
        cachedDataDate = nil
    }

    /// Autorizovaný požadavek. Při 401 odhlásí uživatele a chybu pošle dál.
    /// Čtení (GET) se ukládá do cache a při výpadku připojení se z ní doplní poslední známá data.
    func send<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
    ) async throws -> T {
        guard let token = authToken else {
            logout()
            throw APIError.unauthorized
        }
        let cacheable = ResponseCache.isCacheable(endpoint: endpoint, method: method)
        do {
            let data = try await APIService.shared.requestData(endpoint: endpoint, method: method, token: token, body: body)
            let value = try APIService.shared.decode(T.self, from: data, label: endpoint)
            if cacheable { ResponseCache.shared.store(data, for: endpoint) }
            if cachedDataDate != nil { cachedDataDate = nil }
            return value
        } catch APIError.unauthorized {
            logout()
            throw APIError.unauthorized
        } catch APIError.network where cacheable {
            guard
                let entry = ResponseCache.shared.load(for: endpoint),
                let value = try? APIService.shared.decode(T.self, from: entry.data, label: endpoint)
            else { throw APIError.network }
            cachedDataDate = entry.savedAt
            return value
        }
    }

    /// Nahraje soubor (`multipart/form-data`).
    func upload<T: Decodable>(_ endpoint: String, file: MultipartFile) async throws -> T {
        try await authorized { token in
            try await APIService.shared.upload(endpoint: endpoint, token: token, file: file)
        }
    }

    /// Stáhne binární data (např. náhled skenu).
    func download(_ endpoint: String) async throws -> Data {
        try await authorized { token in
            try await APIService.shared.download(endpoint: endpoint, token: token)
        }
    }

    /// Provede akci s tokenem; při 401 odhlásí uživatele.
    private func authorized<T>(_ action: (String) async throws -> T) async throws -> T {
        guard let token = authToken else {
            logout()
            throw APIError.unauthorized
        }
        do {
            return try await action(token)
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

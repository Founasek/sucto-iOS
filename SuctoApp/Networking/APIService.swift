//
//  APIService.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

@MainActor
class APIService {
    static let shared = APIService()
    private let baseURL = "https://www.sucto.cz/api/"
    private init() {}

    weak var session: SessionManager?

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        token: String? = nil,
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue(token, forHTTPHeaderField: "Auth-Token")
        }
        request.httpBody = body

        print("🌍 API Request → \(method.rawValue) \(url.absoluteString)")
        if let token { print("🔑 Token: \(token)") }
        if let body, let jsonBody = String(data: body, encoding: .utf8) {
            print("📦 Request body:\n\(jsonBody)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Status code: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                print("🚪 Token expired → logging out user")
                session?.logout()
                throw APIError.unauthorized
            }
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Raw response for \(endpoint):\n\(jsonString)")
        }

        // 📅 Nastavení správného dekodéru pro český formát datumu
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd. MM. yyyy"
        dateFormatter.locale = Locale(identifier: "cs_CZ")
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            print("✅ Successfully decoded response of type \(T.self)")
            return decoded
        } catch let decodingError as DecodingError {
            print("❌ Decoding error for endpoint: \(endpoint)")
            switch decodingError {
            case let .typeMismatch(type, context):
                print("🔹 Type mismatch for type \(type): \(context.debugDescription)")
                print("🔹 codingPath:", context.codingPath.map(\.stringValue).joined(separator: " → "))
            case let .valueNotFound(type, context):
                print("🔹 Value not found for type \(type): \(context.debugDescription)")
                print("🔹 codingPath:", context.codingPath.map(\.stringValue).joined(separator: " → "))
            case let .keyNotFound(key, context):
                print("🔹 Missing key '\(key.stringValue)': \(context.debugDescription)")
                print("🔹 codingPath:", context.codingPath.map(\.stringValue).joined(separator: " → "))
            case let .dataCorrupted(context):
                print("🔹 Data corrupted:", context.debugDescription)
            @unknown default:
                print("🔹 Unknown decoding error: \(decodingError.localizedDescription)")
            }
            throw APIError.decodingError
        } catch {
            print("❌ Other error: \(error.localizedDescription)")
            throw error
        }
    }
}

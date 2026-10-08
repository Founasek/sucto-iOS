//
//  APIService.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

/// Stateless HTTP klient. Token se doplňuje v `SessionManager.send`,
/// který zároveň odhlásí uživatele při 401.
final class APIService: Sendable {
    static let shared = APIService()
    private init() {}

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        token: String? = nil,
        body: Data? = nil,
    ) async throws -> T {
        guard let url = URL(string: APIConstants.baseURL + endpoint) else {
            throw APIError.badURL
        }

        var request = URLRequest(url: url, timeoutInterval: APIConstants.defaultTimeout)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue(token, forHTTPHeaderField: "Auth-Token")
        }
        request.httpBody = body

        Log.debug("🌍 \(method.rawValue) \(url.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            Log.debug("❌ Network error: \(error.localizedDescription)")
            throw APIError.network
        }

        if let httpResponse = response as? HTTPURLResponse {
            Log.debug("📡 Status \(httpResponse.statusCode) ← \(endpoint)")
            switch httpResponse.statusCode {
            case 200 ..< 300:
                break
            case 401:
                throw APIError.unauthorized
            case 400, 422:
                throw APIError.badRequest
            default:
                throw APIError.server(statusCode: httpResponse.statusCode)
            }
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            Log.debug("❌ Decoding \(T.self) failed for \(endpoint): \(error)")
            throw APIError.decodingError
        }
    }
}

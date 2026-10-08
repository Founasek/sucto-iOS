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

/// Odpověď bez obsahu (200 s prázdným tělem).
struct EmptyResponse: Decodable {}

/// Soubor odesílaný jako `multipart/form-data`.
struct MultipartFile {
    let fieldName: String
    let fileName: String
    let mimeType: String
    let data: Data
}

/// Stateless HTTP klient. Token se doplňuje v `SessionManager`,
/// který zároveň odhlásí uživatele při 401.
final class APIService: Sendable {
    static let shared = APIService()
    private init() {}

    // MARK: - JSON

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        token: String? = nil,
        body: Data? = nil,
    ) async throws -> T {
        let data = try await requestData(endpoint: endpoint, method: method, token: token, body: body)
        return try decode(T.self, from: data, label: endpoint)
    }

    /// Surová odpověď – volající ji může dekódovat a uložit do cache.
    func requestData(
        endpoint: String,
        method: HTTPMethod = .GET,
        token: String? = nil,
        body: Data? = nil,
    ) async throws -> Data {
        var request = try makeRequest(endpoint: endpoint, method: method, token: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return try await execute(request, label: endpoint)
    }

    // MARK: - Nahrání souboru

    func upload<T: Decodable>(
        endpoint: String,
        token: String,
        file: MultipartFile,
    ) async throws -> T {
        var request = try makeRequest(endpoint: endpoint, method: .POST, token: token)
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: \(file.mimeType)\r\n\r\n".utf8))
        body.append(file.data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        request.httpBody = body
        // Nahrávání může trvat déle než běžný dotaz.
        request.timeoutInterval = 120

        let data = try await execute(request, label: endpoint)
        return try decode(T.self, from: data, label: endpoint)
    }

    // MARK: - Binární data (např. náhled skenu)

    func download(endpoint: String, token: String) async throws -> Data {
        var request = try makeRequest(endpoint: endpoint, method: .GET, token: token)
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        return try await execute(request, label: endpoint)
    }

    // MARK: - Společné

    private func makeRequest(endpoint: String, method: HTTPMethod, token: String?) throws -> URLRequest {
        guard let url = URL(string: APIConstants.baseURL + endpoint) else {
            throw APIError.badURL
        }
        var request = URLRequest(url: url, timeoutInterval: APIConstants.defaultTimeout)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue(token, forHTTPHeaderField: "Auth-Token")
        }
        Log.debug("🌍 \(method.rawValue) \(url.absoluteString)")
        return request
    }

    private func execute(_ request: URLRequest, label: String) async throws -> Data {
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
            Log.debug("📡 Status \(httpResponse.statusCode) ← \(label)")
            switch httpResponse.statusCode {
            case 200 ..< 300:
                break
            case 401:
                throw APIError.unauthorized
            case 403:
                Log.debug("🚫 403 body: \(String(data: data.prefix(300), encoding: .utf8) ?? "<binární>")")
                throw APIError.forbidden(message: Self.serverMessage(in: data))
            case 400, 422:
                throw APIError.badRequest(message: Self.serverMessage(in: data))
            default:
                throw APIError.server(statusCode: httpResponse.statusCode)
            }
        }
        return data
    }

    func decode<T: Decodable>(_: T.Type, from data: Data, label: String) throws -> T {
        // Některé akce (např. odeslání e-mailem) vrací 200 s prázdným tělem.
        let payload = data.isEmpty ? Data("{}".utf8) : data
        do {
            return try JSONDecoder().decode(T.self, from: payload)
        } catch {
            Log.debug("❌ Decoding \(T.self) failed for \(label): \(error)")
            throw APIError.decodingError
        }
    }

    /// API při chybě vrací `{"errors": ["…"]}` – zprávu ukážeme uživateli.
    private static func serverMessage(in data: Data) -> String? {
        struct Payload: Decodable { let errors: [String]? }
        return (try? JSONDecoder().decode(Payload.self, from: data))?.errors?.first
    }
}

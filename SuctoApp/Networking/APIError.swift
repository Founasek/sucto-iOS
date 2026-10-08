//
//  APIError.swift
//  SuctoApp
//
//  Created by Jan Founě on 01.11.2025.
//

import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case network
    case decodingError
    case badRequest
    case badURL
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            "Neplatný token. Přihlaste se prosím znovu."
        case .network:
            "Chyba připojení k serveru."
        case .decodingError:
            "Nepodařilo se zpracovat odpověď serveru."
        case .badRequest:
            "Nesprávné parametry."
        case .badURL:
            "Chyba v URL adrese."
        case let .server(statusCode):
            "Server vrátil chybu (\(statusCode))."
        }
    }
}

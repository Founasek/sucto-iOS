//
//  APIError.swift
//  SuctoApp
//
//  Created by Jan Founě on 01.11.2025.
//

import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case forbidden(message: String?)
    case network
    case decodingError
    case badRequest(message: String?)
    case badURL
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            "Neplatný token. Přihlaste se prosím znovu."
        case let .forbidden(message):
            message ?? "K této části nemáte oprávnění."
        case .network:
            "Chyba připojení k serveru."
        case .decodingError:
            "Nepodařilo se zpracovat odpověď serveru."
        case let .badRequest(message):
            message ?? "Nesprávné parametry."
        case .badURL:
            "Chyba v URL adrese."
        case let .server(statusCode):
            statusCode == 413 ? "Soubor je příliš velký." : "Server vrátil chybu (\(statusCode))."
        }
    }
}

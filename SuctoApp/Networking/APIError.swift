//
//  APIError.swift
//  SuctoApp
//
//  Created by Jan Founě on 01.11.2025.
//

import SwiftUI

enum APIError: LocalizedError {
    case unauthorized
    case network
    case decodingError
    case badRequest
    case badURL

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Neplatný token. Přihlaste se prosím znovu."
        case .network:
            return "Chyba připojení k serveru."
        case .decodingError:
            return "Nepodařilo se zpracovat odpověď serveru."
        case .badRequest:
            return "Nesprávné parametry."
        case .badURL:
            return "Chyba v URL adrese."
        }
    }
}

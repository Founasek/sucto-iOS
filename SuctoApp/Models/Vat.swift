//
//  Vat.swift
//  SuctoApp
//
//  Created by Jan Founě on 30.10.2025.
//


struct Vat: Identifiable, Codable {
    let id: Int
    let value: String
    let valid_from: String
    let valid_to: String?
}
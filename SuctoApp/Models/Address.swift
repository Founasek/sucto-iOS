//
//  Address.swift
//  SuctoApp
//
//  Created by Jan Founě on 28.10.2025.
//


import Foundation

struct Address: Codable {
    let street: String?
    let city: String?
    let cityPart: String?
    let zip: String?

    enum CodingKeys: String, CodingKey {
        case street
        case city
        case cityPart = "city_part"
        case zip
    }
}
//
//  Company.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//


import Foundation

struct Company: Identifiable, Decodable {
    let id: Int
    let name: String
    let ic: String
    let is_taxable: Bool
    let country_id: Int
    let email: String
    let logo: String?
}

//
//  LoginResponse.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//


import Foundation

struct LoginResponse: Decodable {
    let email: String
    let authentication_token: String
}

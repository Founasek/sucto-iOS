//
//  ActuarialType.swift
//  SuctoApp
//

import Foundation

/// Typ dokladu z `GET api/actuarial_types` (faktura, výzva k platbě, opravný doklad).
struct ActuarialType: Decodable, Identifiable {
    let id: Int
}

//
//  ActuarialType.swift
//  SuctoApp
//

import Foundation

/// Typ dokladu z `GET api/actuarial_types` (faktura, výzva k platbě, opravný doklad).
struct ActuarialType: Decodable, Identifiable {
    let id: Int
}

/// Typy dokladů z dokumentace (`GET api/actuarial_types`: 1 invoice, 2 call_for_payment, 3 correcting) – pro filtr.
enum ActuarialKind: Int, CaseIterable {
    case invoice = 1
    case callForPayment = 2
    case correcting = 3

    var title: String {
        switch self {
        case .invoice: "Faktura"
        case .callForPayment: "Výzva k platbě"
        case .correcting: "Opravný doklad"
        }
    }
}

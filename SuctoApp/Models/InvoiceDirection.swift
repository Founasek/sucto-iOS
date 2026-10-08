//
//  InvoiceDirection.swift
//  SuctoApp
//

import Foundation

/// Směr faktury – určuje endpointy a popisky ve sdíleném formuláři.
enum InvoiceDirection: Hashable {
    case outgoing
    case incoming

    var createTitle: String {
        switch self {
        case .outgoing: "Nová vydaná faktura"
        case .incoming: "Nová přijatá faktura"
        }
    }

    var partnerLabel: String {
        switch self {
        case .outgoing: "Odběratel"
        case .incoming: "Dodavatel"
        }
    }

    var partnerPlaceholder: String {
        switch self {
        case .outgoing: "Vyberte odběratele"
        case .incoming: "Vyberte dodavatele"
        }
    }

    /// U vydané faktury číslo přiděluje server, u přijaté ho zadává uživatel (číslo dodavatele).
    var numberIsEditable: Bool { self == .incoming }

    func newEndpoint(companyId: Int) -> String {
        switch self {
        case .outgoing: APIConstants.newOutgoingInvoice(companyId: companyId)
        case .incoming: APIConstants.newIncomingInvoice(companyId: companyId)
        }
    }

    func createEndpoint(companyId: Int) -> String {
        switch self {
        case .outgoing: APIConstants.createOutgoingInvoice(companyId: companyId)
        case .incoming: APIConstants.createIncomingInvoice(companyId: companyId)
        }
    }
}

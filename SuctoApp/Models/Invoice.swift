//
//  Invoice.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import Foundation

struct Invoice: Identifiable, Codable, Hashable {
    let id: Int
    let actuarialType: String
    let actuarialNumber: String
    let issueDateAt: String?
    let uzpDateAt: String?
    let dueDateAt: String?
    let status: String
    let statusId: Int
    let basePrice: String?
    let endPrice: String?
    let remaining: String?
    let variableSymbol: String?
    let currency: Currency?
    let printNotice: String?
    let footNotice: String?
    let externalNumber: String?
    let orderNumber: String?
    let taxable : Bool?
    let vat : String?
    let pay : String?
    
    let account: Account?

    // U vydané faktury
    let customer: Customer?
    // U přijaté faktury
    let supplier: Supplier?

    // Položky faktury
    let items: [InvoiceItem]?

    enum CodingKeys: String, CodingKey {
        case id
        case actuarialType = "actuarial_type"
        case actuarialNumber = "actuarial_number"
        case uzpDateAt = "uzp_date_at"
        case dueDateAt = "due_date_at"
        case status
        case statusId = "status_id"
        case issueDateAt = "issue_date_at"
        case basePrice = "base_price"
        case endPrice = "end_price"
        case remaining
        case variableSymbol = "variable_symbol"
        case currency
        case printNotice = "print_notice"
        case footNotice = "foot_notice"
        case customer
        case supplier
        case items
        case externalNumber = "external_number"
        case orderNumber = "order_number"
        case account
        case taxable
        case vat
        case pay
    }
}

extension Invoice {
    enum Status: Int, Codable, CaseIterable {
        case concept = 1
        case prepare
        case sent
        case displayed
        case commented
        case corrected
        case partlyPaid
        case paid
        case archived
        case storno
        case done
        
        var title: String {
            switch self {
            case .concept: return "Koncept"
            case .prepare: return "Připraveno"
            case .sent: return "Odesláno"
            case .displayed: return "Zobrazeno"
            case .commented: return "Okomentováno"
            case .corrected: return "Opraveno"
            case .partlyPaid: return "Částečně uhrazeno"
            case .paid: return "Zaplaceno"
            case .archived: return "Archivováno"
            case .storno: return "Stornováno"
            case .done: return "Dokončeno"
            }
        }
        
        var color: String {
            switch self {
            case .concept: return "#9CA3AF" // šedá
            case .prepare: return "#3B82F6" // modrá
            case .sent: return "#2563EB"
            case .displayed: return "#10B981" // zelená
            case .commented: return "#F59E0B" // oranžová
            case .corrected: return "#FBBF24"
            case .partlyPaid: return "#FCD34D"
            case .paid: return "#22C55E"
            case .archived: return "#6B7280"
            case .storno: return "#EF4444" // červená
            case .done: return "#16A34A"
            }
        }
    }
    
    var invoiceStatus: Status? {
        Status(rawValue: statusId)
    }
}


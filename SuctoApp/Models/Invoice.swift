//
//  Invoice.swift
//  SuctoApp
//
//  Created by Jan Founě on 17.09.2025.
//

import SwiftUI

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
    let taxable: Bool?
    let vat: String?
    let pay: String?

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
            case .concept: "Koncept"
            case .prepare: "Připraveno"
            case .sent: "Odesláno"
            case .displayed: "Zobrazeno"
            case .commented: "Okomentováno"
            case .corrected: "Opraveno"
            case .partlyPaid: "Částečně uhrazeno"
            case .paid: "Zaplaceno"
            case .archived: "Archivováno"
            case .storno: "Stornováno"
            case .done: "Dokončeno"
            }
        }

        var color: String {
            switch self {
            case .concept: "#9CA3AF" // šedá
            case .prepare: "#3B82F6" // modrá
            case .sent: "#2563EB"
            case .displayed: "#10B981" // zelená
            case .commented: "#F59E0B" // oranžová
            case .corrected: "#FBBF24"
            case .partlyPaid: "#FCD34D"
            case .paid: "#22C55E"
            case .archived: "#6B7280"
            case .storno: "#EF4444" // červená
            case .done: "#16A34A"
            }
        }
    }

    var invoiceStatus: Status? {
        Status(rawValue: statusId)
    }

    var isPaid: Bool { invoiceStatus == .paid || invoiceStatus == .done }

    var dueDate: Date? { dueDateAt?.toDate() }

    /// Nezaplacená faktura po datu splatnosti (storno a koncepty se nepočítají).
    var isOverdue: Bool {
        guard !isPaid, invoiceStatus != .storno, invoiceStatus != .concept,
              let dueDate else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date())
    }

    /// Barva textu stavu v seznamech a detailu.
    var statusColor: Color { tone.color }
}

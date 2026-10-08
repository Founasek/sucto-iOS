//
//  StatusBadge.swift
//  SuctoApp
//

import SwiftUI

/// Sémantický význam stavu faktury – z něj se odvozuje barva a ikona.
enum InvoiceTone {
    case success, warning, danger, info, neutral

    var color: Color {
        switch self {
        case .success: .green
        case .warning: .orange
        case .danger: .red
        case .info: .blue
        case .neutral: .gray
        }
    }

    var icon: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .warning: "clock.fill"
        case .danger: "exclamationmark.circle.fill"
        case .info: "paperplane.fill"
        case .neutral: "doc.fill"
        }
    }
}

extension Invoice {
    var tone: InvoiceTone {
        if isOverdue { return .danger }
        switch invoiceStatus {
        case .paid, .done: return .success
        case .storno: return .danger
        case .partlyPaid, .commented, .corrected: return .warning
        case .sent, .displayed, .prepare: return .info
        case .concept, .archived, .none: return .neutral
        }
    }

    /// Text do odznaku – po splatnosti zdůrazníme prodlení.
    var badgeTitle: String {
        isOverdue ? "Po splatnosti" : status
    }
}

struct StatusBadge: View {
    let invoice: Invoice

    var body: some View {
        let tone = invoice.tone
        Label(invoice.badgeTitle, systemImage: tone.icon)
            .font(.caption.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(tone.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tone.color.opacity(0.14), in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Stav: \(invoice.badgeTitle)")
    }
}

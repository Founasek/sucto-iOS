//
//  DashboardTabs.swift
//  SuctoApp
//

import SwiftUI

/// Záložky dolní lišty.
enum MainTab: Hashable {
    case overview, invoices, cash
}

/// Strana v záložce Faktury (přepínač nahoře).
enum InvoiceSide: Int, CaseIterable {
    case outgoing, incoming

    var item: SegmentedTabs.Item {
        switch self {
        case .outgoing: .init(title: "Vydané", systemImage: "arrow.up.right.circle")
        case .incoming: .init(title: "Přijaté", systemImage: "arrow.down.left.circle")
        }
    }

    var direction: InvoiceDirection { self == .outgoing ? .outgoing : .incoming }
}

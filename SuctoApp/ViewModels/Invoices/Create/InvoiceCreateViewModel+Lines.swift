//
//  InvoiceCreateViewModel+Lines.swift
//  SuctoApp
//

import Foundation

/// Položky faktury ve formuláři: prázdný řádek, dopočet částek a součty.
extension InvoiceCreateViewModel {
    func makeEmptyLine() -> InvoiceCreateLine {
        InvoiceCreateLine(
            vatId: availableVats.first?.id ?? 108,
            lineableType: "Actuarial",
            name: "",
            quantity: 0,
            unitPrice: 0,
            basePrice: 0,
            tax: 0,
            totalPrice: 0,
            unitName: nil,
        )
    }

    /// Součty za celou fakturu (základ, DPH, celkem) pro náhled ve formuláři.
    var totals: InvoiceTotals {
        InvoiceTotals(lines: items.map(calculated))
    }

    /// Základ, DPH a celkem položky se v UI neupravují, proto je dopočítáme před odesláním.
    func calculated(_ line: InvoiceCreateLine) -> InvoiceCreateLine {
        let rate = availableVats.first { $0.id == line.vatId }.flatMap { Double($0.value) } ?? 0
        return InvoiceLineMath.applying(to: line, vatRate: rate)
    }
}

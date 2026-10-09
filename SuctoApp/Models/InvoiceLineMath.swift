//
//  InvoiceLineMath.swift
//  SuctoApp
//

import Foundation

/// Částky jednoho řádku faktury: základ, DPH a celkem.
struct LineAmounts: Equatable {
    let base: Double
    let tax: Double
    let total: Double
}

/// Výpočty částek řádků a faktury na jednom místě (čisté funkce, snadno testovatelné).
enum InvoiceLineMath {
    /// Základ = množství × cena za jednotku po slevě; DPH = základ × sazba; celkem = základ + DPH.
    static func amounts(quantity: Double, unitPrice: Double, discountPercent: Double = 0, vatRate: Double) -> LineAmounts {
        let base = quantity * unitPrice * (1 - discountPercent / 100)
        let tax = base * vatRate / 100
        return LineAmounts(base: base, tax: tax, total: base + tax)
    }

    /// Řádek s dopočtenými částkami (formulář nové faktury sleva řádků nemá).
    static func applying(to line: InvoiceCreateLine, vatRate: Double) -> InvoiceCreateLine {
        let result = amounts(quantity: line.quantity, unitPrice: line.unitPrice, vatRate: vatRate)
        var line = line
        line.basePrice = result.base
        line.tax = result.tax
        line.totalPrice = result.total
        return line
    }
}

/// Součty za celou fakturu.
struct InvoiceTotals: Equatable {
    var base = 0.0
    var tax = 0.0
    var total = 0.0

    init() {}

    init(lines: [InvoiceCreateLine]) {
        for line in lines {
            base += line.basePrice
            tax += line.tax
            total += line.totalPrice
        }
    }
}

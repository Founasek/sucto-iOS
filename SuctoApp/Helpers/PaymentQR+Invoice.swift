//
//  PaymentQR+Invoice.swift
//  SuctoApp
//

import Foundation

extension Invoice {
    /// IBAN z faktury; když chybí, z účtu faktury, a nakonec ze tuzemského čísla účtu s kódem banky.
    var paymentIBAN: String? {
        let bank = account?.bankAccount
        let candidates = [iban?.value, bank?.iban]
        if let direct = candidates.compactMap(\.self).first(where: { PaymentQR.normalizedIBAN($0) != nil }) {
            return PaymentQR.normalizedIBAN(direct)
        }
        if let number = bankNumber?.value, let converted = PaymentQR.czechIBAN(accountNumber: number, bankCode: bank?.bankCode) {
            return converted
        }
        if let number = bank?.account, let converted = PaymentQR.czechIBAN(accountNumber: number, bankCode: bank?.bankCode) {
            return converted
        }
        return nil
    }

    /// Podklady pro QR platbu, nebo `nil` (zaplaceno, žádná částka, chybí použitelný účet).
    /// Částka je zbývající dluh, případně celková částka u faktury bez údaje o zbývajícím.
    func paymentQRInput(recipientName: String?) -> PaymentQR.Input? {
        guard !isPaid, invoiceStatus != .storno, invoiceStatus != .concept, let paymentIBAN else { return nil }
        let remainingAmount = remaining.flatMap(Double.init) ?? 0
        let total = endPrice.flatMap(Double.init) ?? 0
        let amount = remainingAmount > 0 ? remainingAmount : total
        guard amount > 0 else { return nil }
        return PaymentQR.Input(
            iban: paymentIBAN,
            amount: amount,
            currency: currency?.isoCode ?? "CZK",
            variableSymbol: variableSymbol ?? actuarialNumber,
            message: "Faktura \(actuarialNumber)",
            dueDate: dueDate,
            recipientName: recipientName,
        )
    }
}

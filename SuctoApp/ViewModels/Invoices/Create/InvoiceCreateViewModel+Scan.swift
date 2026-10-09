//
//  InvoiceCreateViewModel+Scan.swift
//  SuctoApp
//

import Foundation

extension InvoiceCreateViewModel {
    /// Předvyplní údaje z dokladu: číslo faktury, měnu a dodavatele (hledá se podle IČ).
    func applyScan(_ scan: InvoiceInitResponse) async {
        if let external = scan.externalNumber, !external.isEmpty { actuarialNumber = external }
        if let currencyId = scan.currency?.id {
            selectedCurrency = availableCurrencies.first { $0.id == currencyId }
        }
        guard let supplier = scan.supplier, supplier.name != nil || supplier.ic != nil else { return }
        scanSupplier = supplier

        if let ic = supplier.ic, !ic.isEmpty {
            await searchPartners(ic)
            selectedPartner = availablePartners.first { $0.ic == ic }
            applyPartnerDefaults()
            scanSupplierNotMatched = selectedPartner == nil
            if selectedPartner == nil { await searchPartners("") }
        } else {
            scanSupplierNotMatched = true
        }
    }
}

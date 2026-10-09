//
//  AppRoute.swift
//  SuctoApp
//
//  Created by Jan Founě on 16.09.2025.
//

import Foundation

enum AppRoute: Hashable {
    case dashboard(companyId: Int)
    case createInvoice(companyId: Int, direction: InvoiceDirection, scanId: String?)
    case duplicateInvoice(companyId: Int, direction: InvoiceDirection, invoiceId: Int)
    case settings
    case accounts(companyId: Int)
    case scans(companyId: Int)
    case partners(companyId: Int)
    case partnerDetail(companyId: Int, partnerId: Int)
    case cashVoucherDetail(companyId: Int, directionRaw: String, voucherId: Int)
}

/// Odkaz na detail faktury z míst, která mají jen její id (např. karta nejbližších splatností v Přehledu).
/// Cíl navigace je v dashboardu, kde jsou view modely seznamů, takže se detail chová stejně jako po klepnutí v seznamu.
struct InvoiceRoute: Hashable {
    let id: Int
    let isIncoming: Bool
}

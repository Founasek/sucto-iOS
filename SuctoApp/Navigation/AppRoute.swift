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
    case scans(companyId: Int)
    case partners(companyId: Int)
    case partnerDetail(companyId: Int, partnerId: Int)
    case cashVouchers(companyId: Int)
    case cashVoucherDetail(companyId: Int, directionRaw: String, voucherId: Int)
}

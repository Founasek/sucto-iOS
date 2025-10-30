//
//  AppRoute.swift
//  SuctoApp
//
//  Created by Jan Founě on 16.09.2025.
//

import Foundation


enum AppRoute: Hashable {
    case dashboard(companyId: Int)
    case outgoingInvoiceDetail(invoiceId: Int)
    case incomingInvoiceDetail(invoice: Invoice)
    case accountDetail(account: Account)
    case createOutgoingInvoice(companyId: Int)
}


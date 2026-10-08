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
    case scans(companyId: Int)
}

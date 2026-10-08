//
//  AppRoute.swift
//  SuctoApp
//
//  Created by Jan Founě on 16.09.2025.
//

import Foundation

enum AppRoute: Hashable {
    case dashboard(companyId: Int)
    case createOutgoingInvoice(companyId: Int)
}

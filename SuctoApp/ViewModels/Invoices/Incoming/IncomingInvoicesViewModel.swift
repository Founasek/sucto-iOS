//
//  IncomingInvoicesViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import SwiftUI

@MainActor
final class IncomingInvoicesViewModel: PagedInvoicesViewModel {
    init(companyId: Int, session: SessionManager) {
        super.init(companyId: companyId, session: session, direction: .incoming)
    }
}

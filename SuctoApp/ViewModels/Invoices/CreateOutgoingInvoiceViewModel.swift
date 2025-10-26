//
//  CreateOutgoingInvoiceViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//


import SwiftUI

@MainActor
class CreateOutgoingInvoiceViewModel: ObservableObject {
    
    let companyId: Int
    var session: SessionManager
    
    @Published var actuarialNumber = ""
    @Published var issueDate = Date()
    @Published var dueDate = Date()
    @Published var currencyId: Int? = nil
    @Published var partnerId: Int? = nil
    @Published var accountId: Int? = nil
    @Published var actuarialTypeId: Int? = 1
    
    @Published var items: [InvoiceItem] = []
    
    @Published var availablePartners: [Partner] = []
    @Published var availableCurrencies: [Currency] = []
    @Published var availableAccounts: [Account] = []
    
    
    @Published var errorMessage: String?
    @Published var creationSuccess = false
    
    var totalAmount: Double {
        items.reduce(0) { partialResult, item in
            let quantity = item.quantity ?? 0
            let unitPrice = item.unit_price ?? 0
            return partialResult + (quantity * unitPrice)
        }
    }

    var selectedCurrencyCode: String {
        availableCurrencies.first(where: { $0.id == currencyId })?.isoCode ?? "CZK"
    }

    
    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }
    
    func loadInitialData() async {
        guard let token = session.authToken else {
            errorMessage = "Token není k dispozici"
            print("❌ Token není k dispozici")
            return
        }
        
        print("✅ /Session success:")
        
        do {
            // Načteme nové faktury z /new
            let newInvoice: OutgoingInvoiceNewResponse = try await APIService.shared.request(
                endpoint: APIConstants.getNewOutgoingInvoice(companyId: companyId),
                method: .GET,
                token: token
            )
            
            
            print("✅ /new invoice response:")
            dump(newInvoice) // vypíše kompletní strukturu objektu
            
            actuarialNumber = newInvoice.actuarial_number
            issueDate = newInvoice.issueDate ?? Date()
            dueDate = newInvoice.dueDate ?? Date()

            currencyId = newInvoice.currency?.id ?? 1
            partnerId = newInvoice.customer?.id ?? 0
            items = newInvoice.items
       
            // Dostupní partneři
            availablePartners = try await APIService.shared.request(
                endpoint: APIConstants.getPartners(companyId: companyId),
                method: .GET,
                token: token
            )
            print("✅ Partners response:")
            //dump(availablePartners)
            
            if let first = availablePartners.first, let firstId = first.id {
                partnerId = firstId
            }

         
            // Dostupné měny
            availableCurrencies = try await APIService.shared.request(
                endpoint: APIConstants.getCurrencies(),
                method: .GET,
                token: token
            )
            print("✅ Currencies response:")
            //dump(availableCurrencies)
            
            if let firstCurrency = availableCurrencies.first, let firstId = firstCurrency.id {
                currencyId = firstId
            }
            
            // Dostupné bankovní účty
            availableAccounts = try await APIService.shared.request(
                endpoint: APIConstants.getBankAccounts(companyId: companyId),
                method: .GET,
                token: token
            )
            print("✅ Bank Accounts response:")
            //dump(availableAccounts)
            
            if let firstBankAccount = availableAccounts.first, let firstId = firstBankAccount.id {
                accountId = firstId
            }
           
           
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Chyba při načítání dat: \(error.localizedDescription)")
        }
    }

    
    func addEmptyItem() {
        items.append(InvoiceItem(id: UUID(), name: "", quantity: nil, unit_price: nil))
    }
    
    func removeItem(_ item: InvoiceItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func createInvoice() async {
        guard let token = session.authToken else {
            errorMessage = "Token není k dispozici"
            return
        }
        
        do {
            let body: [String: Any] = [
                "partner_id": partnerId,
                "account_id": accountId,
                "currency_id": currencyId,
                "actuarial_number": actuarialNumber,
                "actuarial_type_id": actuarialTypeId ?? 1,
                "issue_date_at": ISO8601DateFormatter().string(from: issueDate),
                "due_date_at": ISO8601DateFormatter().string(from: dueDate),
                "uzp_date_at": ISO8601DateFormatter().string(from: issueDate),
                "lines": items.map { [
                    "name": $0.name,
                    "quantity": $0.quantity ?? 0,
                    "unit_price": $0.unit_price ?? 0,
                    "base_price": ($0.unit_price ?? 0) * ($0.quantity ?? 0),
                    "vat_id": 108 //$0.vat_id
                ]}
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📦 JSON Body:")
                print(jsonString)
            }

            
            let _: OutgoingInvoiceCreatedResponse = try await APIService.shared.request(
                endpoint: APIConstants.createOutgoingInvoice(companyId: companyId),
                method: .POST,
                token: token,
                body: jsonData
            )
            
            creationSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

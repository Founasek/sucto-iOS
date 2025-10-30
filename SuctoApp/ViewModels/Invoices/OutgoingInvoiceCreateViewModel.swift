//
//  CreateOutgoingInvoiceViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//


import SwiftUI

@MainActor
class OutgoingInvoiceCreateViewModel: ObservableObject {
    
    let companyId: Int
    var session: SessionManager
    
    // MARK: - Faktura
    @Published var actuarialNumber = ""
    @Published var variableSymbol = ""
    @Published var printNotice = "Fakturujeme Vám následující položky:"
    @Published var orderNumber = ""
    @Published var issueDate = Date()
    @Published var dueDate = Date()
    
    @Published var selectedAccount: Account? = nil
    @Published var selectedCurrency: Currency? = nil
    @Published var selectedPartner: Partner? = nil
    
    @Published var actuarialTypeId: Int? = 1
    
    @Published var items: [CreateInvoiceLine] = []
    
    // MARK: - Reference data
    @Published var availablePartners: [Partner] = []
    @Published var availableCurrencies: [Currency] = []
    @Published var availableAccounts: [Account] = []
    
    // MARK: - Stav UI
    @Published var errorMessage: String?
    @Published var creationSuccess = false
    
    // MARK: - Init
    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }
    
    // MARK: - Načtení výchozích dat
    func loadInitialData() async {
        guard let token = session.authToken else {
            errorMessage = "Token není k dispozici"
            print("❌ Token není k dispozici")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        do {
            // Načteme výchozí údaje pro novou fakturu
            let newInvoice: OutgoingInvoiceInitResponse = try await APIService.shared.request(
                endpoint: APIConstants.getNewOutgoingInvoice(companyId: companyId),
                method: .GET,
                token: token
            )
            
            // Naplníme ViewModel daty
            actuarialNumber = newInvoice.actuarial_number
            issueDate = newInvoice.issueDate ?? Date()
            dueDate = newInvoice.dueDate ?? Date()
            //currencyId = newInvoice.currency?.id ?? 1
            //partnerId = newInvoice.customer?.id
            items = newInvoice.items
            
            // Získání číselné části faktury pro variabilní symbol
            let numericPart = actuarialNumber.filter { $0.isNumber }
            variableSymbol = String(numericPart)
            
            // Dostupní partneři
            availablePartners = try await APIService.shared.request(
                endpoint: APIConstants.getPartners(companyId: companyId),
                method: .GET,
                token: token
            )
            
            // Dostupné měny
            availableCurrencies = try await APIService.shared.request(
                endpoint: APIConstants.getCurrencies(),
                method: .GET,
                token: token
            )
            
            // Dostupné bankovní účty
            availableAccounts = try await APIService.shared.request(
                endpoint: APIConstants.getBankAccounts(companyId: companyId),
                method: .GET,
                token: token
            )
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Chyba při načítání dat: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Vytvoření faktury
    func createInvoice() async {
        guard let token = session.authToken else {
            errorMessage = "Token není k dispozici"
            return
        }
        
        // Kontrola povinných polí
        /*
        guard let partnerId = selectedPartner?.id,
              let accountId = selectedAccount?.id,
              let currencyId = selectedCurrency?.id,
              let actuarialTypeId = actuarialTypeId,
              !items.isEmpty else {
            errorMessage = "Vyplňte všechny povinné údaje a položky"
            return
        }
         */
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        
        // 🧱 Sestavení request objektu
        let requestBody = OutgoingInvoiceCreateRequest(
            actuarialNumber: actuarialNumber,
            variableSymbol: variableSymbol,
            actuarialTypeId: actuarialTypeId ?? 0,
            partnerId: selectedPartner?.id ?? 0,
            accountId: selectedAccount?.id ?? 0,
            currencyId: selectedCurrency?.id ?? 0,
            iban: selectedAccount?.bankAccount?.iban ?? "",
            swift: selectedAccount?.bankAccount?.swift ?? "",
            bankNumber: selectedAccount?.bankAccount?.bankCode ?? "",
            vatRegimeId: 1,
            issueDateAt: formatter.string(from: issueDate),
            dueDateAt: formatter.string(from: dueDate),
            uzpDateAt: formatter.string(from: issueDate),
            printNotice: printNotice,
            orderNumber: orderNumber, lines: items
        )
        
        
        
        do {
            
            // 🔧 Kódování do JSONu
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let jsonData = try encoder.encode(requestBody)
            
            // Pro kontrolu — můžeš si nechat vytisknout JSON
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📦 JSON Body:")
                print(jsonString)
            }
            
            
            // POST na API
            let _: OutgoingInvoiceCreatedResponse = try await APIService.shared.request(
                endpoint: APIConstants.createOutgoingInvoice(companyId: companyId),
                method: .POST,
                token: token,
                body: jsonData
            )
            
            creationSuccess = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            creationSuccess = false
        }
    }
    
    func updateLine(_ line: inout CreateInvoiceLine) {
        line.basePrice = line.unitPrice * line.quantity
        line.totalPrice = line.basePrice + line.tax
    }

}

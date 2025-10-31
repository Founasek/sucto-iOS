//
//  OutgoingInvoiceCreateViewModel.swift
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
    @Published var actuarialTypeId: Int? = 1

    @Published var selectedPartner: Partner?
    @Published var selectedAccount: Account?
    @Published var selectedCurrency: Currency?
    @Published var selectedPaymentType: PaymentType?
    @Published var selectedVatRegime: VatRegime?
    @Published var selectedVats: Vat?

    @Published var issueDate = Date()
    @Published var dueDate = Date()
    @Published var uzpDate = Date()

    @Published var printNotice = "Fakturujeme Vám následující položky:"
    @Published var footNotice = ""
    @Published var orderNumber = ""

    @Published var items: [OutgoingInvoiceCreateLine] = []

    // MARK: - Reference data

    @Published var availablePartners: [Partner] = []
    @Published var availableCurrencies: [Currency] = []
    @Published var availableAccounts: [Account] = []
    @Published var availablePaymentTypes: [PaymentType] = []
    @Published var availableVatRegimes: [VatRegime] = []
    @Published var availableVats: [Vat] = []

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
                token: token,
            )

            // Naplníme ViewModel daty
            actuarialNumber = newInvoice.actuarialNumber
            issueDate = newInvoice.issueDate ?? Date()
            dueDate = newInvoice.dueDate ?? Date()
            // currencyId = newInvoice.currency?.id ?? 1
            // partnerId = newInvoice.customer?.id
            items = newInvoice.items

            // Získání číselné části faktury pro variabilní symbol
            let numericPart = actuarialNumber.filter(\.isNumber)
            variableSymbol = String(numericPart)

            // Dostupní partneři
            availablePartners = try await APIService.shared.request(
                endpoint: APIConstants.getPartners(companyId: companyId),
                method: .GET,
                token: token,
            )

            // Dostupné měny
            availableCurrencies = try await APIService.shared.request(
                endpoint: APIConstants.getCurrencies(),
                method: .GET,
                token: token,
            )

            // Dostupné bankovní účty
            availableAccounts = try await APIService.shared.request(
                endpoint: APIConstants.getBankAccounts(companyId: companyId),
                method: .GET,
                token: token,
            )

            availablePaymentTypes = try await APIService.shared.request(
                endpoint: APIConstants.GetPaymentTypes(companyId: companyId),
                method: .GET,
                token: token,
            )

            availableVatRegimes = try await APIService.shared.request(
                endpoint: APIConstants.GetVatRegimes(countryId: 1),
                method: .GET,
                token: token,
            )

            let vats: [Vat] = try await APIService.shared.request(
                endpoint: APIConstants.GetVats(countryId: 1),
                method: .GET,
                token: token,
            )

            availableVats = vats.filter { $0.valid_to == nil }

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
            actuarialTypeId: actuarialTypeId ?? 1,
            partnerId: selectedPartner?.id ?? 0,
            accountId: selectedAccount?.id ?? 0,
            currencyId: selectedCurrency?.id ?? 0,
            iban: selectedAccount?.bankAccount?.iban ?? "",
            swift: selectedAccount?.bankAccount?.swift ?? "",
            bankNumber: selectedAccount?.bankAccount?.bankCode ?? "",
            paymentTypeId: selectedPaymentType?.id ?? 0,
            vatRegimeId: selectedVatRegime?.id ?? 0,
            issueDateAt: formatter.string(from: issueDate),
            dueDateAt: formatter.string(from: dueDate),
            uzpDateAt: formatter.string(from: uzpDate),
            printNotice: printNotice,
            footNotice: footNotice,
            orderNumber: orderNumber, lines: items,
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
                body: jsonData,
            )

            creationSuccess = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            creationSuccess = false
        }
    }

    func updateLine(_ line: inout OutgoingInvoiceCreateLine) {
        line.basePrice = line.unitPrice * line.quantity
        line.totalPrice = line.basePrice + line.tax
    }
}

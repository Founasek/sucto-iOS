//
//  OutgoingInvoiceCreateViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import SwiftUI

@MainActor
final class OutgoingInvoiceCreateViewModel: ObservableObject {
    let companyId: Int
    private let session: SessionManager

    // MARK: - Faktura

    @Published var actuarialNumber = ""
    @Published var variableSymbol = ""
    @Published var actuarialTypeId: Int? = 1

    @Published var selectedPartner: Partner?
    @Published var selectedAccount: Account?
    @Published var selectedCurrency: Currency?
    @Published var selectedPaymentType: PaymentType?
    @Published var selectedVatRegime: VatRegime?

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
    @Published var isSubmitting = false

    // MARK: - Init

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    // MARK: - Načtení výchozích dat

    func loadInitialData() async {
        do {
            // Výchozí údaje pro novou fakturu
            let newInvoice: OutgoingInvoiceInitResponse = try await session.send(
                APIConstants.newOutgoingInvoice(companyId: companyId),
            )

            actuarialNumber = newInvoice.actuarialNumber
            issueDate = newInvoice.issueDate ?? Date()
            dueDate = newInvoice.dueDate ?? Date()
            uzpDate = newInvoice.uzpDateAt?.toDate() ?? issueDate
            items = newInvoice.items

            // Variabilní symbol = číselná část čísla faktury
            variableSymbol = actuarialNumber.filter(\.isNumber)

            // Sazby a režimy DPH závisí na zemi vybrané firmy (výchozí ČR).
            let countryId = session.selectedCompany?.countryId ?? 1

            async let currencies: [Currency] = session.send(APIConstants.currencies)
            async let accounts: [Account] = session.send(APIConstants.bankAccounts(companyId: companyId))
            async let paymentTypes: [PaymentType] = session.send(APIConstants.paymentTypes(companyId: companyId))
            async let vatRegimes: [VatRegime] = session.send(APIConstants.vatRegimes(countryId: countryId))
            async let vats: [Vat] = session.send(APIConstants.vats(countryId: countryId))

            await searchPartners("")
            availableCurrencies = try await currencies
            availableAccounts = try await accounts
            availablePaymentTypes = try await paymentTypes
            availableVatRegimes = try await vatRegimes
            availableVats = try await vats.filter { $0.validTo == nil }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// DPH režim se podle API posílá jen u plátců DPH.
    var isCompanyTaxable: Bool { session.selectedCompany?.isTaxable ?? true }

    /// Vyhledá odběratele na serveru (název, IČ, DIČ, adresa). Prázdný dotaz vrátí prvních 50.
    func searchPartners(_ query: String) async {
        do {
            availablePartners = try await session.send(
                APIConstants.partners(companyId: companyId, query: query.trimmingCharacters(in: .whitespaces)),
            )
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Vytvoření faktury

    func createInvoice() async {
        guard !isSubmitting else { return }

        guard let partner = selectedPartner, let partnerId = partner.id,
              let account = selectedAccount, let accountId = account.id,
              let currencyId = selectedCurrency?.id,
              !isCompanyTaxable || selectedVatRegime != nil
        else {
            errorMessage = isCompanyTaxable
                ? "Vyplňte odběratele, účet, měnu a DPH režim."
                : "Vyplňte odběratele, účet a měnu."
            return
        }
        guard !items.isEmpty, items.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            errorMessage = "Přidejte alespoň jednu pojmenovanou položku."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let requestBody = OutgoingInvoiceCreateRequest(
            actuarialNumber: actuarialNumber,
            variableSymbol: variableSymbol,
            actuarialTypeId: actuarialTypeId ?? 1,
            partnerId: partnerId,
            accountId: accountId,
            currencyId: currencyId,
            iban: account.bankAccount?.iban ?? "",
            swift: account.bankAccount?.swift ?? "",
            bankNumber: account.bankAccount?.bankCode ?? "",
            paymentTypeId: selectedPaymentType?.id,
            vatRegimeId: isCompanyTaxable ? selectedVatRegime?.id : nil,
            issueDateAt: Self.apiDateFormatter.string(from: issueDate),
            dueDateAt: Self.apiDateFormatter.string(from: dueDate),
            uzpDateAt: Self.apiDateFormatter.string(from: uzpDate),
            printNotice: printNotice,
            footNotice: footNotice,
            orderNumber: orderNumber,
            lines: items.map(calculated),
        )

        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            let _: OutgoingInvoiceCreatedResponse = try await session.send(
                APIConstants.createOutgoingInvoice(companyId: companyId),
                method: .POST,
                body: jsonData,
            )
            creationSuccess = true
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            creationSuccess = false
        }
    }

    // MARK: - Položky

    func makeEmptyLine() -> OutgoingInvoiceCreateLine {
        OutgoingInvoiceCreateLine(
            vatId: availableVats.first?.id ?? 108,
            lineableType: "Actuarial",
            name: "",
            quantity: 0,
            unitPrice: 0,
            basePrice: 0,
            tax: 0,
            totalPrice: 0,
            unitName: nil,
        )
    }

    struct Totals {
        var base = 0.0
        var tax = 0.0
        var total = 0.0
    }

    /// Součty za celou fakturu (základ, DPH, celkem) pro náhled ve formuláři.
    var totals: Totals {
        var result = Totals()
        for line in items.map(calculated) {
            result.base += line.basePrice
            result.tax += line.tax
            result.total += line.totalPrice
        }
        return result
    }

    /// Základ a celkem položky se v UI neupravují, proto je dopočítáme před odesláním.
    private func calculated(_ line: OutgoingInvoiceCreateLine) -> OutgoingInvoiceCreateLine {
        var line = line
        let rate = availableVats.first { $0.id == line.vatId }.flatMap { Double($0.value) } ?? 0
        line.basePrice = line.quantity * line.unitPrice
        line.tax = line.basePrice * rate / 100
        line.totalPrice = line.basePrice + line.tax
        return line
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

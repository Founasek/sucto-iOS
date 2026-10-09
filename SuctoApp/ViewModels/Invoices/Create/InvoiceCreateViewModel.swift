//
//  InvoiceCreateViewModel.swift
//  SuctoApp
//
//  Created by Jan Founě on 13.10.2025.
//

import SwiftUI

@MainActor
final class InvoiceCreateViewModel: ObservableObject {
    let companyId: Int
    let direction: InvoiceDirection
    /// Je-li zadané, formulář se předvyplní z naskenovaného dokladu.
    let scanId: String?
    /// Je-li zadané, formulář se předvyplní jako kopie existující faktury.
    let copyFromInvoiceId: Int?
    let session: SessionManager

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

    @Published var items: [InvoiceCreateLine] = []

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
    /// Výchozí data (číslo, sazby, doklad ze skenu…) se nepodařilo načíst – formulář nemá smysl ukazovat.
    @Published private(set) var loadFailed = false
    /// Dodavatel přečtený ze skenu (pro upozornění nad formulářem).
    @Published var scanSupplier: InitSupplier?
    /// `true`, pokud se dodavatel ze skenu nepodařilo spárovat s partnerem.
    @Published var scanSupplierNotMatched = false

    // MARK: - Init

    init(
        companyId: Int,
        direction: InvoiceDirection,
        scanId: String? = nil,
        copyFromInvoiceId: Int? = nil,
        session: SessionManager,
    ) {
        self.companyId = companyId
        self.direction = direction
        self.scanId = scanId
        self.copyFromInvoiceId = copyFromInvoiceId
        self.session = session
        if direction == .incoming { printNotice = "" }
    }

    var isCopy: Bool { copyFromInvoiceId != nil }

    // MARK: - Načtení výchozích dat

    func loadInitialData() async {
        loadFailed = false
        do {
            // Výchozí údaje pro novou fakturu
            let initEndpoint = scanId.map { APIConstants.newIncomingInvoiceFromScan(companyId: companyId, scanId: $0) }
                ?? direction.newEndpoint(companyId: companyId)
            let newInvoice: InvoiceInitResponse = try await session.send(initEndpoint)

            actuarialNumber = newInvoice.actuarialNumber ?? ""
            issueDate = newInvoice.issueDate ?? Date()
            dueDate = newInvoice.dueDate ?? Date()
            uzpDate = newInvoice.uzpDateAt?.toDate() ?? issueDate
            items = newInvoice.items

            // Variabilní symbol = číselná část čísla faktury
            if direction == .outgoing {
                variableSymbol = actuarialNumber.filter(\.isNumber)
            }

            // Sazby a režimy DPH závisí na zemi vybrané firmy (výchozí ČR).
            let countryId = session.selectedCompany?.countryId ?? 1

            async let currencies: [Currency] = session.send(APIConstants.currencies)
            async let accounts: [Account] = session.send(APIConstants.bankAccounts(companyId: companyId))
            async let paymentTypes: [PaymentType] = session.send(APIConstants.paymentTypes(companyId: companyId))
            async let vatRegimes: [VatRegime] = session.send(APIConstants.vatRegimes(countryId: countryId))
            async let vats: [Vat] = session.send(APIConstants.vats(countryId: countryId))
            // Typ dokladu je jen doplněk – při selhání zůstane výchozí hodnota.
            async let types: [ActuarialType]? = try? session.send(APIConstants.actuarialTypes)

            await searchPartners("")
            availableCurrencies = try await currencies
            availableAccounts = try await accounts
            availablePaymentTypes = try await paymentTypes
            availableVatRegimes = try await vatRegimes
            availableVats = try await vats.filter { $0.validTo == nil }
            if let invoiceType = await types?.first { actuarialTypeId = invoiceType.id }

            // Řádky bez sazby (např. ze skenu) dostanou první dostupnou sazbu DPH.
            let defaultVat = availableVats.first?.id ?? 0
            items = items.map { line in
                var line = line
                if line.vatId == 0 { line.vatId = defaultVat }
                return line
            }

            if scanId != nil { await applyScan(newInvoice) }
            if let copyFromInvoiceId { await applyCopy(of: copyFromInvoiceId) }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            loadFailed = true
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

    /// Po výběru partnera předvyplní splatnost (podle `invoice_due`) a měnu, pokud ještě není zvolená.
    func applyPartnerDefaults() {
        guard let partner = selectedPartner else { return }
        if let days = partner.invoiceDue, days > 0 {
            dueDate = Calendar.current.date(byAdding: .day, value: days, to: issueDate) ?? dueDate
        }
        if selectedCurrency == nil, let currencyId = partner.currency?.id {
            selectedCurrency = availableCurrencies.first { $0.id == currencyId }
        }
    }
}

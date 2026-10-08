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

    init(companyId: Int, direction: InvoiceDirection, scanId: String? = nil, session: SessionManager) {
        self.companyId = companyId
        self.direction = direction
        self.scanId = scanId
        self.session = session
        if direction == .incoming { printNotice = "" }
    }

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
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            loadFailed = true
        }
    }

    /// Předvyplní údaje z dokladu: číslo faktury, měnu a dodavatele (hledá se podle IČ).
    private func applyScan(_ scan: InvoiceInitResponse) async {
        if let external = scan.externalNumber, !external.isEmpty { actuarialNumber = external }
        if let currencyId = scan.currency?.id {
            selectedCurrency = availableCurrencies.first { $0.id == currencyId }
        }
        guard let supplier = scan.supplier, supplier.name != nil || supplier.ic != nil else { return }
        scanSupplier = supplier

        if let ic = supplier.ic, !ic.isEmpty {
            await searchPartners(ic)
            selectedPartner = availablePartners.first { $0.ic == ic }
            applyPartnerDefaults()
            scanSupplierNotMatched = selectedPartner == nil
            if selectedPartner == nil { await searchPartners("") }
        } else {
            scanSupplierNotMatched = true
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

    // MARK: - Vytvoření faktury

    func createInvoice() async {
        guard !isSubmitting else { return }

        guard let partner = selectedPartner, let partnerId = partner.id,
              let account = selectedAccount, let accountId = account.id,
              let currencyId = selectedCurrency?.id,
              !isCompanyTaxable || selectedVatRegime != nil
        else {
            let partner = direction.partnerLabel.lowercased()
            errorMessage = isCompanyTaxable
                ? "Vyplňte \(partner)e, účet, měnu a DPH režim."
                : "Vyplňte \(partner)e, účet a měnu."
            return
        }
        guard !actuarialNumber.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Vyplňte číslo faktury."
            return
        }
        guard !items.isEmpty, items.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            errorMessage = "Přidejte alespoň jednu pojmenovanou položku."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let requestBody = InvoiceCreateRequest(
            actuarialNumber: actuarialNumber,
            variableSymbol: variableSymbol,
            actuarialTypeId: actuarialTypeId ?? 1,
            partnerId: partnerId,
            accountId: accountId,
            currencyId: currencyId,
            iban: direction == .outgoing ? account.bankAccount?.iban ?? "" : nil,
            swift: direction == .outgoing ? account.bankAccount?.swift ?? "" : nil,
            bankNumber: direction == .outgoing ? account.bankAccount?.bankCode ?? "" : nil,
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
            let _: InvoiceCreatedResponse = try await session.send(
                direction.createEndpoint(companyId: companyId),
                method: .POST,
                body: jsonData,
            )
            creationSuccess = true
            errorMessage = nil
            if let scanId { ScanLinkStore.markUsed(scanId) }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            creationSuccess = false
        }
    }

    // MARK: - Položky

    func makeEmptyLine() -> InvoiceCreateLine {
        InvoiceCreateLine(
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
    private func calculated(_ line: InvoiceCreateLine) -> InvoiceCreateLine {
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

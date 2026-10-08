//
//  PartnerFormViewModel.swift
//  SuctoApp
//

import SwiftUI

@MainActor
final class PartnerFormViewModel: ObservableObject {
    enum Mode {
        case create
        case edit(PartnerRecord)
    }

    static let languages: [(code: String, title: String)] = [("cs", "Čeština"), ("en", "Angličtina"), ("es", "Španělština")]

    let companyId: Int
    let mode: Mode
    private let session: SessionManager

    @Published var name = ""
    @Published var ic = ""
    @Published var dic = ""
    @Published var isTaxable = false
    @Published var isCustomer = true
    @Published var isSupplier = false

    @Published var street = ""
    @Published var city = ""
    @Published var zip = ""
    @Published var countryId: Int?

    @Published var email = ""
    @Published var phone = ""
    @Published var web = ""

    @Published var currencyId: Int?
    @Published var language = "cs"
    @Published var invoiceDue = ""

    @Published private(set) var countries: [Country] = []
    @Published private(set) var currencies: [Currency] = []
    @Published private(set) var isLoadingReferenceData = true
    @Published private(set) var referenceDataFailed = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    init(companyId: Int, mode: Mode, session: SessionManager) {
        self.companyId = companyId
        self.mode = mode
        self.session = session
        if case let .edit(partner) = mode { prefill(from: partner) }
    }

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var title: String { isEditing ? "Upravit partnera" : "Nový partner" }

    // MARK: - Validace

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isEmailValid: Bool {
        let value = email.trimmingCharacters(in: .whitespaces)
        if value.isEmpty { return true }
        guard let at = value.firstIndex(of: "@") else { return false }
        let domain = value[value.index(after: at)...]
        return value.startIndex < at && domain.contains(".") && !domain.hasSuffix(".") && !value.contains(" ")
    }

    var isDueValid: Bool {
        let value = invoiceDue.trimmingCharacters(in: .whitespaces)
        return value.isEmpty || (Int(value).map { $0 >= 0 } ?? false)
    }

    var canSave: Bool {
        !trimmedName.isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && !zip.trimmingCharacters(in: .whitespaces).isEmpty
            && countryId != nil && currencyId != nil
            && isEmailValid && isDueValid && !isSaving
    }

    // MARK: - Načtení

    func loadReferenceData() async {
        isLoadingReferenceData = true
        referenceDataFailed = false
        defer { isLoadingReferenceData = false }
        do {
            async let loadedCountries: [Country] = session.send(APIConstants.countries)
            async let loadedCurrencies: [Currency] = session.send(APIConstants.currencies)
            countries = try await loadedCountries.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            currencies = try await loadedCurrencies
            applyDefaults()
        } catch is CancellationError {
            return
        } catch {
            referenceDataFailed = true
            errorMessage = error.localizedDescription
        }
    }

    /// U nového partnera: země a měna firmy, jazyk podle země.
    private func applyDefaults() {
        guard !isEditing else { return }
        if countryId == nil { countryId = session.selectedCompany?.countryId }
        if currencyId == nil, let country = countries.first(where: { $0.id == countryId }) {
            currencyId = country.currency?.id
            language = country.defaultLanguage.flatMap { code in Self.languages.contains { $0.code == code } ? code : nil } ?? "cs"
        }
    }

    private func prefill(from partner: PartnerRecord) {
        name = partner.name
        ic = partner.ic ?? ""
        dic = partner.dic ?? ""
        isTaxable = partner.isTaxable
        isCustomer = partner.isCustomer
        isSupplier = partner.isSupplier
        street = partner.address?.street ?? ""
        city = partner.address?.city ?? ""
        zip = partner.address?.zip ?? ""
        countryId = partner.address?.countryId
        email = partner.email ?? ""
        phone = partner.phone ?? ""
        web = partner.web ?? ""
        currencyId = partner.currencyId
        language = partner.invoicingLanguage ?? "cs"
        invoiceDue = partner.invoiceDueDays.map(String.init) ?? ""
    }

    // MARK: - Uložení

    /// Uloží partnera. Vrací uloženého partnera, nebo `nil` (chyba je v `errorMessage`).
    func save() async -> PartnerRecord? {
        guard canSave, let countryId, let currencyId else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        func clean(_ value: String) -> String? {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        let body = PartnerRequest(partner: PartnerBody(
            name: trimmedName,
            ic: clean(ic),
            dic: clean(dic),
            email: clean(email),
            phone: clean(phone),
            web: clean(web),
            invoicingLanguage: language,
            invoiceDue: Int(invoiceDue.trimmingCharacters(in: .whitespaces)),
            isTaxable: isTaxable,
            isSupplier: isSupplier,
            isCustomer: isCustomer,
            currencyId: currencyId,
            address: PartnerAddressBody(street: clean(street), city: city.trimmingCharacters(in: .whitespaces), zip: zip.trimmingCharacters(in: .whitespaces), countryId: countryId),
        ))

        do {
            let data = try JSONEncoder().encode(body)
            switch mode {
            case .create:
                let created: PartnerRecord = try await session.send(
                    APIConstants.createPartner(companyId: companyId),
                    method: .POST,
                    body: data,
                )
                return created
            case let .edit(partner):
                let updated: PartnerRecord = try await session.send(
                    APIConstants.partner(companyId: companyId, partnerId: partner.id),
                    method: .PATCH,
                    body: data,
                )
                return updated
            }
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

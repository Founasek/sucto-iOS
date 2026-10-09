//
//  InvoiceCreateViewModel+Submit.swift
//  SuctoApp
//

import Foundation

/// Odeslání faktury na server.
extension InvoiceCreateViewModel {
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

    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

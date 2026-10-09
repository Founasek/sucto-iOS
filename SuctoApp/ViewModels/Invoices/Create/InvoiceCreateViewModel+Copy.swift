//
//  InvoiceCreateViewModel+Copy.swift
//  SuctoApp
//

import Foundation

extension InvoiceCreateViewModel {
    /// Protistrana zdrojové faktury: vydaná nese id partnera, přijatá jen údaje dodavatele.
    private struct Counterpart {
        let id: Int?
        let ic: String?
        let name: String?
    }

    /// Předvyplní formulář z existující faktury: protistranu, měnu, účet, poznámky a položky.
    /// Číslo a data zůstávají nové (z `new` endpointu); splatnost se zachová jako počet dnů od vystavení.
    func applyCopy(of invoiceId: Int) async {
        let endpoint = direction == .outgoing
            ? APIConstants.outgoingInvoiceDetail(companyId: companyId, invoiceId: invoiceId)
            : APIConstants.incomingInvoiceDetail(companyId: companyId, invoiceId: invoiceId)
        guard let source: Invoice = try? await session.send(endpoint) else {
            errorMessage = "Zdrojovou fakturu se nepodařilo načíst, formulář je prázdný."
            return
        }

        let counterpart = direction == .outgoing
            ? Counterpart(id: source.customer?.id, ic: source.customer?.ic, name: source.customer?.name)
            : Counterpart(id: nil, ic: source.supplier?.ic, name: source.supplier?.name)
        await selectPartner(matching: counterpart)

        if let currencyId = source.currency?.id {
            selectedCurrency = availableCurrencies.first { $0.id == currencyId }
        }
        if let accountId = source.account?.id {
            selectedAccount = availableAccounts.first { $0.id == accountId }
        }
        printNotice = source.printNotice ?? printNotice
        footNotice = source.footNotice ?? ""
        orderNumber = source.orderNumber ?? ""
        keepDueDays(of: source)

        let defaultVat = availableVats.first?.id ?? 0
        let lines: [InvoiceCreateLine] = (source.items ?? []).map { item in
            var line = makeEmptyLine()
            line.name = item.name
            line.quantity = item.quantity.flatMap { Double($0) } ?? 1
            line.unitPrice = item.unitPrice.flatMap { Double($0) } ?? 0
            line.unitName = item.unitName
            line.vatId = item.vatId ?? defaultVat
            return line
        }
        if !lines.isEmpty { items = lines }
    }

    /// Partner se hledá podle id, pak IČ, pak názvu (hledá se podle IČ, jinak názvu).
    private func selectPartner(matching counterpart: Counterpart) async {
        let query = (counterpart.ic?.isEmpty == false ? counterpart.ic : counterpart.name) ?? ""
        guard !query.isEmpty else { return }
        await searchPartners(query)
        selectedPartner = availablePartners.first { counterpart.id != nil && $0.id == counterpart.id }
            ?? availablePartners.first { counterpart.ic != nil && $0.ic == counterpart.ic }
            ?? availablePartners.first { $0.name == counterpart.name }
        if selectedPartner == nil { await searchPartners("") }
    }

    private func keepDueDays(of source: Invoice) {
        guard let issue = source.issueDateAt?.toDate(), let due = source.dueDateAt?.toDate() else { return }
        let days = Calendar.current.dateComponents([.day], from: issue, to: due).day ?? -1
        guard days >= 0 else { return }
        dueDate = Calendar.current.date(byAdding: .day, value: days, to: issueDate) ?? dueDate
    }
}

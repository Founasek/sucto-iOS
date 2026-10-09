//
//  PohodaExporter.swift
//  SuctoApp
//
//  Převod vydaných faktur na Pohoda XML (dataPack, verze 2.0) pro import v Pohodě:
//  Soubor → Datová komunikace → XML import.
//

import Foundation

enum PohodaExporter {
    /// Vydané faktury (`issuedInvoice`) nebo přijaté (`receivedInvoice`).
    enum Direction {
        case issued, received

        var invoiceType: String {
            switch self {
            case .issued: "issuedInvoice"
            case .received: "receivedInvoice"
            }
        }
    }

    // MARK: - Veřejné API

    /// Převede faktury do jednoho dataPacku. Faktury, které nejdou převést, se přeskočí a vrátí se jako `failures`.
    ///
    /// `companyICO` je IČ naší firmy – musí odpovídat firmě otevřené v Pohodě. U vydaných faktur se při jeho
    /// absenci vezme IČ vystavitele z dokladu; u přijatých je povinné (doklad nese jen dodavatele).
    static func makeXML(for invoices: [Invoice], direction: Direction = .issued, companyICO: String? = nil) throws -> Result {
        let issuerICO = direction == .issued ? invoices.compactMap { $0.supplier?.ic }.first(where: { !$0.isEmpty }) : nil
        guard let ico = [companyICO, issuerICO].compactMap(\.self).first(where: { !$0.isEmpty }) else {
            throw ExportError.missingIssuer
        }

        var items: [String] = []
        var failures: [Failure] = []
        for invoice in invoices {
            do {
                try items.append(dataPackItem(for: invoice, direction: direction))
            } catch {
                failures.append(Failure(id: invoice.id, number: invoice.actuarialNumber, reason: error.localizedDescription))
            }
        }

        var xml = #"<?xml version="1.0" encoding="UTF-8"?>"# + "\n"
        xml += "<dat:dataPack id=\"SuctoApp\" ico=\"\(escape(ico))\" application=\"SuctoApp\" version=\"2.0\" note=\"Export faktur ze sÚčto\""
        xml += " xmlns:dat=\"http://www.stormware.cz/schema/version_2/data.xsd\""
        xml += " xmlns:inv=\"http://www.stormware.cz/schema/version_2/invoice.xsd\""
        xml += " xmlns:typ=\"http://www.stormware.cz/schema/version_2/type.xsd\">\n"
        xml += items.joined()
        xml += "</dat:dataPack>\n"
        return Result(data: Data(xml.utf8), exportedCount: items.count, failures: failures)
    }

    // MARK: - Jedna faktura

    private static func dataPackItem(for invoice: Invoice, direction: Direction) throws -> String {
        guard invoice.actuarialType == "FA" else { throw ExportError.unsupportedType(invoice.actuarialType) }
        let currency = (invoice.currency?.isoCode ?? "CZK").uppercased()
        guard currency.count == 3, currency.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            throw ExportError.unsupportedCurrency(currency)
        }
        guard let lines = invoice.items, !lines.isEmpty else { throw ExportError.missingItems }

        // U vydané faktury rozhoduje, zda je plátcem naše firma (vystavitel), u přijaté dodavatel.
        let isVATPayer = invoice.supplier?.isTaxable ?? invoice.taxable ?? false
        let converted = try lines.map { try convert($0, isVATPayer: isVATPayer, currency: currency) }

        var xml = "  <dat:dataPackItem id=\"FA-\(escape(invoice.actuarialNumber))\" version=\"2.0\">\n"
        xml += "    <inv:invoice version=\"2.0\">\n"
        xml += try header(for: invoice, direction: direction)
        xml += "      <inv:invoiceDetail>\n"
        xml += converted.map(\.xml).joined()
        xml += "      </inv:invoiceDetail>\n"
        xml += summary(of: converted, isVATPayer: isVATPayer, currency: currency)
        xml += "    </inv:invoice>\n"
        xml += "  </dat:dataPackItem>\n"
        return xml
    }

    /// Protistrana dokladu: u vydané faktury odběratel, u přijaté dodavatel.
    private struct Counterparty {
        let name: String?
        let city: String?
        let street: String?
        let zip: String?
        let ic: String?
        let dic: String?
    }

    private static func counterparty(of invoice: Invoice, direction: Direction) -> Counterparty? {
        switch direction {
        case .issued:
            guard let c = invoice.customer else { return nil }
            return Counterparty(name: c.name, city: c.city, street: c.street, zip: c.zip, ic: c.ic, dic: c.dic)
        case .received:
            guard let s = invoice.supplier else { return nil }
            return Counterparty(name: s.name, city: s.city, street: s.street, zip: s.zip, ic: s.ic, dic: s.dic)
        }
    }

    private static func header(for invoice: Invoice, direction: Direction) throws -> String {
        var xml = "      <inv:invoiceHeader>\n"
        xml += "        <inv:invoiceType>\(direction.invoiceType)</inv:invoiceType>\n"
        switch direction {
        case .issued:
            xml += "        <inv:number><typ:numberRequested>\(escape(invoice.actuarialNumber))</typ:numberRequested></inv:number>\n"
        case .received:
            // Evidenční číslo přidělí Pohoda; číslo dokladu dodavatele jde do originalDocument (po symVar dle schématu).
            break
        }
        let symbol = (invoice.variableSymbol?.isEmpty == false ? invoice.variableSymbol : nil)
            ?? (direction == .received ? invoice.actuarialNumber.filter(\.isNumber) : nil)
        if let symbol, !symbol.isEmpty {
            xml += "        <inv:symVar>\(escape(String(symbol.prefix(20))))</inv:symVar>\n"
        }
        if direction == .received {
            xml += "        <inv:originalDocument>\(escape(String(invoice.actuarialNumber.prefix(32))))</inv:originalDocument>\n"
        }
        if let issued = try isoDate(invoice.issueDateAt) { xml += "        <inv:date>\(issued)</inv:date>\n" }
        if let taxable = try isoDate(invoice.uzpDateAt) { xml += "        <inv:dateTax>\(taxable)</inv:dateTax>\n" }
        if let due = try isoDate(invoice.dueDateAt) { xml += "        <inv:dateDue>\(due)</inv:dateDue>\n" }

        let text = (invoice.printNotice?.isEmpty == false ? invoice.printNotice : nil) ?? "Faktura \(invoice.actuarialNumber)"
        xml += "        <inv:text>\(escape(String(text.prefix(240))))</inv:text>\n"

        if let partner = counterparty(of: invoice, direction: direction) {
            xml += "        <inv:partnerIdentity>\n          <typ:address>\n"
            xml += element("typ:company", partner.name.map { String($0.prefix(96)) }, indent: 12)
            xml += element("typ:city", partner.city, indent: 12)
            xml += element("typ:street", partner.street, indent: 12)
            xml += element("typ:zip", partner.zip.map { $0.filter { !$0.isWhitespace } }, indent: 12)
            xml += element("typ:ico", partner.ic, indent: 12)
            xml += element("typ:dic", partner.dic, indent: 12)
            xml += "          </typ:address>\n        </inv:partnerIdentity>\n"
        }

        let isCash = invoice.account?.isCashAccount ?? false
        xml += "        <inv:paymentType><typ:paymentType>\(isCash ? "cash" : "draft")</typ:paymentType></inv:paymentType>\n"
        if let order = invoice.orderNumber, !order.isEmpty {
            xml += "        <inv:numberOrder>\(escape(String(order.prefix(20))))</inv:numberOrder>\n"
        }
        xml += "      </inv:invoiceHeader>\n"
        return xml
    }
}

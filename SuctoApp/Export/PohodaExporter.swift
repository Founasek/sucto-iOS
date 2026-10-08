//
//  PohodaExporter.swift
//  SuctoApp
//
//  Převod vydaných faktur na Pohoda XML (dataPack, verze 2.0) pro import v Pohodě:
//  Soubor → Datová komunikace → XML import.
//

import Foundation

enum PohodaExporter {
    enum ExportError: LocalizedError {
        case unsupportedType(String)
        case unsupportedCurrency(String)
        case unsupportedVATRate(String)
        case missingIssuer
        case missingItems
        case invalidAmount(String)
        case invalidDate(String)

        var errorDescription: String? {
            switch self {
            case let .unsupportedType(type):
                "typ dokladu „\(type)“ (export podporuje jen faktury FA)"
            case let .unsupportedCurrency(code):
                "neplatný kód měny „\(code)“"
            case let .unsupportedVATRate(rate):
                "sazba DPH \(rate) % (podporované jsou 21, 12 a 0)"
            case .missingIssuer:
                "chybí údaje o vystaviteli (IČ)"
            case .missingItems:
                "faktura nemá žádné položky"
            case let .invalidAmount(value):
                "neplatná částka „\(value)“"
            case let .invalidDate(value):
                "neplatné datum „\(value)“"
            }
        }
    }

    /// Faktura, kterou se nepodařilo převést, a důvod.
    struct Failure: Identifiable {
        let id: Int
        let number: String
        let reason: String
    }

    struct Result {
        let data: Data
        let exportedCount: Int
        let failures: [Failure]
    }

    // MARK: - Veřejné API

    /// Převede faktury do jednoho dataPacku. Faktury, které nejdou převést, se přeskočí a vrátí se jako `failures`.
    static func makeXML(for invoices: [Invoice]) throws -> Result {
        guard let ico = invoices.compactMap({ $0.supplier?.ic }).first(where: { !$0.isEmpty }) else {
            throw ExportError.missingIssuer
        }

        var items: [String] = []
        var failures: [Failure] = []
        for invoice in invoices {
            do {
                try items.append(dataPackItem(for: invoice))
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

    private static func dataPackItem(for invoice: Invoice) throws -> String {
        guard invoice.actuarialType == "FA" else { throw ExportError.unsupportedType(invoice.actuarialType) }
        let currency = (invoice.currency?.isoCode ?? "CZK").uppercased()
        guard currency.count == 3, currency.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            throw ExportError.unsupportedCurrency(currency)
        }
        guard let lines = invoice.items, !lines.isEmpty else { throw ExportError.missingItems }

        let isVATPayer = invoice.supplier?.isTaxable ?? invoice.taxable ?? false
        let converted = try lines.map { try convert($0, isVATPayer: isVATPayer, currency: currency) }

        var xml = "  <dat:dataPackItem id=\"FA-\(escape(invoice.actuarialNumber))\" version=\"2.0\">\n"
        xml += "    <inv:invoice version=\"2.0\">\n"
        xml += try header(for: invoice)
        xml += "      <inv:invoiceDetail>\n"
        xml += converted.map(\.xml).joined()
        xml += "      </inv:invoiceDetail>\n"
        xml += summary(of: converted, isVATPayer: isVATPayer, currency: currency)
        xml += "    </inv:invoice>\n"
        xml += "  </dat:dataPackItem>\n"
        return xml
    }

    private static func header(for invoice: Invoice) throws -> String {
        var xml = "      <inv:invoiceHeader>\n"
        xml += "        <inv:invoiceType>issuedInvoice</inv:invoiceType>\n"
        xml += "        <inv:number><typ:numberRequested>\(escape(invoice.actuarialNumber))</typ:numberRequested></inv:number>\n"
        if let symbol = invoice.variableSymbol, !symbol.isEmpty {
            xml += "        <inv:symVar>\(escape(String(symbol.prefix(20))))</inv:symVar>\n"
        }
        if let issued = try isoDate(invoice.issueDateAt) { xml += "        <inv:date>\(issued)</inv:date>\n" }
        if let taxable = try isoDate(invoice.uzpDateAt) { xml += "        <inv:dateTax>\(taxable)</inv:dateTax>\n" }
        if let due = try isoDate(invoice.dueDateAt) { xml += "        <inv:dateDue>\(due)</inv:dateDue>\n" }

        let text = (invoice.printNotice?.isEmpty == false ? invoice.printNotice : nil) ?? "Faktura \(invoice.actuarialNumber)"
        xml += "        <inv:text>\(escape(String(text.prefix(240))))</inv:text>\n"

        if let customer = invoice.customer {
            xml += "        <inv:partnerIdentity>\n          <typ:address>\n"
            xml += element("typ:company", customer.name.map { String($0.prefix(96)) }, indent: 12)
            xml += element("typ:city", customer.city, indent: 12)
            xml += element("typ:street", customer.street, indent: 12)
            xml += element("typ:zip", customer.zip.map { $0.filter { !$0.isWhitespace } }, indent: 12)
            xml += element("typ:ico", customer.ic, indent: 12)
            xml += element("typ:dic", customer.dic, indent: 12)
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

    // MARK: - Položky

    private enum Rate: String {
        case none, low, high

        init(percent: Decimal) throws {
            switch percent {
            case 21: self = .high
            case 12: self = .low
            case 0: self = .none
            default: throw ExportError.unsupportedVATRate("\(percent)")
            }
        }

        var percent: Int {
            switch self {
            case .high: 21
            case .low: 12
            case .none: 0
            }
        }
    }

    private struct ConvertedLine {
        let xml: String
        let rate: Rate
        let base: Decimal
        let vat: Decimal
        let total: Decimal
    }

    private static func convert(_ line: InvoiceItem, isVATPayer: Bool, currency: String) throws -> ConvertedLine {
        let quantity = try decimal(line.quantity ?? "1")
        let unitPrice = try decimal(line.unitPrice ?? "0")
        let base = try decimal(line.basePrice ?? line.unitPrice ?? "0")
        let rate = isVATPayer ? try Rate(percent: decimal(line.vat ?? "0")) : .none
        let vat = isVATPayer ? try decimal(line.tax ?? "0") : 0
        let total = isVATPayer ? try decimal(line.totalPrice ?? "\(base + vat)") : base

        var xml = "        <inv:invoiceItem>\n"
        xml += "          <inv:text>\(escape(String(line.name.prefix(90))))</inv:text>\n"
        xml += "          <inv:quantity>\(quantity)</inv:quantity>\n"
        if let unit = line.unitName, !unit.isEmpty {
            xml += "          <inv:unit>\(escape(String(unit.prefix(10))))</inv:unit>\n"
        }
        xml += "          <inv:payVAT>false</inv:payVAT>\n"
        xml += "          <inv:rateVAT>\(rate.rawValue)</inv:rateVAT>\n"
        if rate != .none { xml += "          <inv:percentVAT>\(rate.percent)</inv:percentVAT>\n" }
        if let discount = try? decimal(line.discountPercentage ?? "0"), discount > 0 {
            xml += "          <inv:discountPercentage>\(discount)</inv:discountPercentage>\n"
        }
        // Částky v cizí měně jdou do foreignCurrency; kurz neposíláme, přepočet udělá Pohoda.
        let container = currency == "CZK" ? "inv:homeCurrency" : "inv:foreignCurrency"
        xml += "          <\(container)>\n"
        xml += "            <typ:unitPrice>\(unitPrice)</typ:unitPrice>\n"
        xml += "            <typ:price>\(base)</typ:price>\n"
        xml += "            <typ:priceVAT>\(vat)</typ:priceVAT>\n"
        if currency == "CZK" { xml += "            <typ:priceSum>\(total)</typ:priceSum>\n" }
        xml += "          </\(container)>\n"
        xml += "        </inv:invoiceItem>\n"
        return ConvertedLine(xml: xml, rate: rate, base: base, vat: vat, total: total)
    }

    private static func summary(of lines: [ConvertedLine], isVATPayer: Bool, currency: String) -> String {
        func sum(_ rate: Rate, _ value: (ConvertedLine) -> Decimal) -> Decimal {
            lines.filter { $0.rate == rate }.reduce(0) { $0 + value($1) }
        }

        var xml = "      <inv:invoiceSummary>\n"
        xml += "        <inv:roundingDocument>none</inv:roundingDocument>\n"

        if currency != "CZK" {
            // Cizí měna: celková cena a kód měny, kurz a rozpad DPH dopočítá Pohoda.
            let total = lines.reduce(0) { $0 + $1.total }
            xml += "        <inv:foreignCurrency>\n"
            xml += "          <typ:currency><typ:ids>\(currency)</typ:ids></typ:currency>\n"
            xml += "          <typ:priceSum>\(total)</typ:priceSum>\n"
            xml += "        </inv:foreignCurrency>\n"
            xml += "      </inv:invoiceSummary>\n"
            return xml
        }

        xml += "        <inv:homeCurrency>\n"
        // Bez DPH se uvádí základ i u neplátců; ostatní skupiny jen u plátce.
        xml += "          <typ:priceNone>\(sum(.none) { $0.base })</typ:priceNone>\n"
        if isVATPayer {
            xml += "          <typ:priceLow>\(sum(.low) { $0.base })</typ:priceLow>\n"
            xml += "          <typ:priceLowVAT>\(sum(.low) { $0.vat })</typ:priceLowVAT>\n"
            xml += "          <typ:priceLowSum>\(sum(.low) { $0.total })</typ:priceLowSum>\n"
            xml += "          <typ:priceHigh>\(sum(.high) { $0.base })</typ:priceHigh>\n"
            xml += "          <typ:priceHighVAT>\(sum(.high) { $0.vat })</typ:priceHighVAT>\n"
            xml += "          <typ:priceHighSum>\(sum(.high) { $0.total })</typ:priceHighSum>\n"
        }
        xml += "        </inv:homeCurrency>\n"
        xml += "      </inv:invoiceSummary>\n"
        return xml
    }

    // MARK: - Pomocné

    private static func decimal(_ string: String) throws -> Decimal {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard let value = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")) else {
            throw ExportError.invalidAmount(string)
        }
        return value
    }

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Datum z API („dd. MM. yyyy“) na ISO. Prázdná hodnota → `nil`.
    private static func isoDate(_ apiDate: String?) throws -> String? {
        guard let apiDate, !apiDate.isEmpty else { return nil }
        guard let date = apiDate.toDate() else { throw ExportError.invalidDate(apiDate) }
        return isoFormatter.string(from: date)
    }

    private static func element(_ name: String, _ value: String?, indent: Int) -> String {
        guard let value, !value.isEmpty else { return "" }
        return String(repeating: " ", count: indent) + "<\(name)>\(escape(value))</\(name)>\n"
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

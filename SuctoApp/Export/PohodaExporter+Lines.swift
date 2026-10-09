//
//  PohodaExporter+Lines.swift
//  SuctoApp
//

import Foundation

/// Položky faktury: přepočet řádků na Pohodu a součtový blok (sazby DPH, zaokrouhlení).
extension PohodaExporter {
    // MARK: - Položky

    enum Rate: String {
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

    struct ConvertedLine {
        let xml: String
        let rate: Rate
        let base: Decimal
        let vat: Decimal
        let total: Decimal
    }

    static func convert(_ line: InvoiceItem, isVATPayer: Bool, currency: String) throws -> ConvertedLine {
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

    static func summary(of lines: [ConvertedLine], isVATPayer: Bool, currency: String) -> String {
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
}

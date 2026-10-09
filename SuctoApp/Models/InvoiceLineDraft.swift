//
//  InvoiceLineDraft.swift
//  SuctoApp
//

import Foundation

/// Položka faktury upravovaná ve formuláři (přidání nebo úprava řádku existující faktury).
struct InvoiceLineDraft: Equatable {
    var name = ""
    var quantity: Double? = 1
    var unitName = ""
    var unitPrice: Double?
    var vatId: Int?
    var discountPercentage: Double?

    init() {}

    init(_ item: InvoiceItem) {
        name = item.name
        quantity = item.quantity.flatMap { Double($0) }
        unitName = item.unitName ?? ""
        unitPrice = item.unitPrice.flatMap { Double($0) }
        vatId = item.vatId
        discountPercentage = item.discountPercentage.flatMap { Double($0) }.flatMap { $0 == 0 ? nil : $0 }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && quantity != nil && unitPrice != nil && vatId != nil
            && (discountPercentage ?? 0) >= 0 && (discountPercentage ?? 0) <= 100
    }

    /// Částky řádku stejně jako při vytváření faktury: základ, DPH a celkem (se započtenou slevou).
    func amounts(vatRate: Double) -> LineAmounts {
        InvoiceLineMath.amounts(
            quantity: quantity ?? 0,
            unitPrice: unitPrice ?? 0,
            discountPercent: discountPercentage ?? 0,
            vatRate: vatRate,
        )
    }
}

/// Tělo pro přidání/úpravu řádku. Dokumentace v příkladech používá pole jednou přímo v těle (POST)
/// a jednou v obalu `line` (PATCH), proto se posílají obě varianty se stejnými hodnotami.
struct InvoiceLineFields: Encodable {
    let name: String
    let quantity: Double
    let unitName: String?
    let unitPrice: Double
    let vatId: Int
    let tax: Double
    let basePrice: Double
    let totalPrice: Double
    let discountPercentage: Double

    enum CodingKeys: String, CodingKey {
        case name, quantity, tax
        case unitName = "unit_name"
        case unitPrice = "unit_price"
        case vatId = "vat_id"
        case basePrice = "base_price"
        case totalPrice = "total_price"
        case discountPercentage = "discount_percentage"
    }
}

struct InvoiceLineRequest: Encodable {
    let fields: InvoiceLineFields

    private enum WrapperKey: String, CodingKey { case line }

    func encode(to encoder: Encoder) throws {
        try fields.encode(to: encoder)
        var wrapper = encoder.container(keyedBy: WrapperKey.self)
        try wrapper.encode(fields, forKey: .line)
    }

    init?(_ draft: InvoiceLineDraft, vatRate: Double) {
        guard draft.isValid, let quantity = draft.quantity, let unitPrice = draft.unitPrice, let vatId = draft.vatId else { return nil }
        let amounts = draft.amounts(vatRate: vatRate)
        let unit = draft.unitName.trimmingCharacters(in: .whitespaces)
        fields = InvoiceLineFields(
            name: draft.name.trimmingCharacters(in: .whitespaces),
            quantity: quantity,
            unitName: unit.isEmpty ? nil : unit,
            unitPrice: unitPrice,
            vatId: vatId,
            tax: amounts.tax,
            basePrice: amounts.base,
            totalPrice: amounts.total,
            discountPercentage: draft.discountPercentage ?? 0,
        )
    }
}

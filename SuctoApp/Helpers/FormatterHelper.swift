//
//  FormatterHelper.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import Foundation

enum FormatterHelper {
    /// Formatter se vytváří jen jednou – seznamy ho volají pro každý řádek.
    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " " // např. 100 000,00
        formatter.decimalSeparator = ","
        return formatter
    }()

    static func formatPrice(_ value: String?, currency: String?) -> String {
        guard let value, let doubleValue = Double(value) else { return value ?? "" }

        let formattedValue = priceFormatter.string(from: NSNumber(value: doubleValue)) ?? "\(doubleValue)"
        if let currency {
            return "\(formattedValue) \(currency)"
        }
        return formattedValue
    }
}

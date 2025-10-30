//
//  FormatterHelper.swift
//  SuctoApp
//
//  Created by Jan Founě on 19.09.2025.
//

import Foundation

enum FormatterHelper {
    static func formatPrice(_ value: String?, currency: String?) -> String {
        guard let value, let doubleValue = Double(value) else { return value ?? "" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " " // např. 100 000,00
        formatter.decimalSeparator = ","

        let formattedValue = formatter.string(from: NSNumber(value: doubleValue)) ?? "\(doubleValue)"
        if let currency {
            return "\(formattedValue) \(currency)"
        }
        return formattedValue
    }
}

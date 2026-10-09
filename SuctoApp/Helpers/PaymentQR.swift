//
//  PaymentQR.swift
//  SuctoApp
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

/// QR platba podle české bankovní normy SPAYD (`SPD*1.0*ACC:…*AM:…*CC:…`), kterou umí přečíst bankovní aplikace.
enum PaymentQR {
    struct Input {
        var iban: String
        var amount: Double
        var currency: String
        var variableSymbol: String?
        var message: String?
        var dueDate: Date?
        var recipientName: String?
    }

    /// Řetězec pro QR kód, nebo `nil`, pokud chybí platný IBAN či částka.
    static func spayd(_ input: Input) -> String? {
        guard let iban = normalizedIBAN(input.iban), input.amount > 0 else { return nil }
        var parts = ["SPD", "1.0", "ACC:\(iban)", "AM:" + String(format: "%.2f", input.amount)]
        parts.append("CC:\(input.currency.uppercased().prefix(3))")
        if let name = clean(input.recipientName, limit: 35) { parts.append("RN:\(name)") }
        if let vs = input.variableSymbol?.filter(\.isNumber).prefix(10), !vs.isEmpty { parts.append("X-VS:\(vs)") }
        if let message = clean(input.message, limit: 60) { parts.append("MSG:\(message)") }
        if let due = input.dueDate { parts.append("DT:" + dateFormatter.string(from: due)) }
        return parts.joined(separator: "*")
    }

    /// IBAN bez mezer, velkými písmeny; neplatný tvar (délka, kontrolní součet) vrací `nil`.
    static func normalizedIBAN(_ value: String) -> String? {
        let iban = value.filter { !$0.isWhitespace }.uppercased()
        guard (15 ... 34).contains(iban.count), iban.allSatisfy({ $0.isLetter || $0.isNumber }) else { return nil }
        return ibanRemainder(iban) == 1 ? iban : nil
    }

    /// Tuzemské číslo účtu „předčíslí-číslo/kód banky“ (např. „19-2000145399/0800“) na IBAN.
    static func czechIBAN(accountNumber: String, bankCode: String? = nil) -> String? {
        var text = accountNumber.filter { !$0.isWhitespace }
        var code = bankCode?.filter(\.isNumber)
        if let slash = text.firstIndex(of: "/") {
            code = String(text[text.index(after: slash)...]).filter(\.isNumber)
            text = String(text[..<slash])
        }
        guard let code, code.count == 4 else { return nil }
        let pieces = text.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        let prefix = pieces.count == 2 ? pieces[0] : ""
        let number = pieces.last ?? ""
        guard prefix.count <= 6, number.count <= 10, !number.isEmpty,
              (prefix + number).allSatisfy(\.isNumber)
        else { return nil }
        let bban = code + String(repeating: "0", count: 6 - prefix.count) + prefix
            + String(repeating: "0", count: 10 - number.count) + number
        let check = 98 - remainder97(of: bban + "123500")
        return "CZ" + String(format: "%02d", check) + bban
    }

    /// QR obrázek (vysoký rozlišením, bez rozmazání při zvětšení).
    static func image(for text: String, size: CGFloat = 600) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Pomocné

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Text pro SPAYD: bez diakritiky, bez zakázané hvězdičky a řídicích znaků, zkrácený na limit.
    private static func clean(_ value: String?, limit: Int) -> String? {
        guard let value else { return nil }
        let folded = value.folding(options: .diacriticInsensitive, locale: Locale(identifier: "cs_CZ"))
            .replacingOccurrences(of: "*", with: " ")
            .filter { $0.isASCII && !$0.isNewline }
            .trimmingCharacters(in: .whitespaces)
        return folded.isEmpty ? nil : String(folded.prefix(limit))
    }

    /// Kontrolní zbytek IBAN: první čtyři znaky se přesunou na konec a vyhodnotí se jako číslo.
    private static func ibanRemainder(_ iban: String) -> Int {
        remainder97(of: String(iban.dropFirst(4) + iban.prefix(4)))
    }

    /// Zbytek po dělení 97 u dlouhého čísla zapsaného textem; písmena se převedou A=10 … Z=35.
    private static func remainder97(of text: String) -> Int {
        var remainder = 0
        for character in text.uppercased() {
            let value: Int = if let digit = character.wholeNumberValue {
                digit
            } else if let ascii = character.asciiValue, character.isLetter {
                Int(ascii) - 55
            } else {
                0
            }
            for digit in String(value) {
                remainder = (remainder * 10 + (digit.wholeNumberValue ?? 0)) % 97
            }
        }
        return remainder
    }
}

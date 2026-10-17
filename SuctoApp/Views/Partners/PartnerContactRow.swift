//
//  PartnerContactRow.swift
//  SuctoApp
//

import SwiftUI

/// Řádek kontaktu; klepnutím otevře poštu / telefon / prohlížeč.
struct ContactRow: View {
    let label: String
    let value: String?
    /// `nil` = web (adresa se doplní o `https://`, pokud chybí).
    let scheme: String?
    let systemImage: String

    var body: some View {
        if let value, !value.isEmpty, let url = url(for: value) {
            Link(destination: url) {
                HStack {
                    Label(label, systemImage: systemImage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(Theme.tint)
                        .multilineTextAlignment(.trailing)
                }
                .contentShape(Rectangle())
            }
            .accessibilityHint("Otevře \(label.lowercased())")
        }
    }

    /// Odkaz jen pro očekávaná schémata. Hodnotu může zadat kdokoli s přístupem k partnerovi (nebo přijde z ARES),
    /// takže z ní nesmí vzniknout `sms://`, `facetime://`, vlastní schéma jiné aplikace ani hlavičky `mailto:` (`?cc=`, `&body=`).
    private func url(for value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        switch scheme {
        case "mailto:":
            guard !trimmed.isEmpty, trimmed.rangeOfCharacter(from: Self.unsafeInAddress) == nil else { return nil }
            return URL(string: "mailto:" + trimmed)
        case "tel:":
            let number = trimmed.filter { !" -()./".contains($0) }
            guard !number.isEmpty, number.allSatisfy({ "+0123456789".contains($0) }) else { return nil }
            return URL(string: "tel:" + number)
        default:
            let text = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
            guard let components = URLComponents(string: text),
                  let urlScheme = components.scheme?.lowercased(), ["http", "https"].contains(urlScheme),
                  let host = components.host, !host.isEmpty
            else { return nil }
            return components.url
        }
    }

    /// Znaky, kterými by se do `mailto:` dostaly další příjemci, hlavičky nebo tělo zprávy.
    private static let unsafeInAddress = CharacterSet(charactersIn: "?&#%,;<>\"\\").union(.whitespacesAndNewlines).union(.controlCharacters)
}

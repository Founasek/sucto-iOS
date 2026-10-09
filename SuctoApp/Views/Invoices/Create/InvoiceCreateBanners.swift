//
//  InvoiceCreateBanners.swift
//  SuctoApp
//

import SwiftUI

/// Upozornění nad formulářem vytvářeným ze skenu: co se z dokladu přečetlo.
struct ScanBanner: View {
    let supplier: InitSupplier
    let notMatched: Bool

    var body: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Předvyplněno z naskenovaného dokladu")
                        .font(.subheadline.weight(.semibold))
                    Text([supplier.name, supplier.ic.map { "IČ \($0)" }].compactMap(\.self).joined(separator: " · "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(notMatched
                        ? "Dodavatele jsme v adresáři partnerů nenašli – vyberte ho ručně. Údaje zkontrolujte."
                        : "Údaje před vytvořením zkontrolujte.")
                        .font(.footnote)
                        .foregroundStyle(notMatched ? Color.orange : Color.secondary)
                }
            } icon: {
                Image(systemName: "doc.viewfinder").foregroundStyle(Color.accentColor)
            }
        }
    }
}

/// Upozornění nad formulářem vytvářeným jako kopie existující faktury.
struct CopyBanner: View {
    var body: some View {
        Section {
            Label("Předvyplněno podle existující faktury. Zkontrolujte data, částky a číslo.", systemImage: "doc.on.doc")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

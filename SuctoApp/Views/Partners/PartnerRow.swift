//
//  PartnerRow.swift
//  SuctoApp
//

import SwiftUI

/// Karta partnera: iniciála, název, IČ a město, štítky Odběratel / Dodavatel.
struct PartnerRow: View {
    let partner: PartnerRecord

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            ZStack {
                Theme.brandGradient
                Image(systemName: partner.avatarSymbol)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(partner.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if partner.isCustomer || partner.isSupplier {
                    HStack(spacing: Theme.Spacing.xs) {
                        if partner.isCustomer { RoleTag(title: "Odběratel") }
                        if partner.isSupplier { RoleTag(title: "Dodavatel") }
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String? {
        let parts = [partner.ic.flatMap { $0.isEmpty ? nil : "IČ \($0)" }, partner.address?.city]
            .compactMap(\.self)
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

struct RoleTag: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Theme.brand.opacity(0.18), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}

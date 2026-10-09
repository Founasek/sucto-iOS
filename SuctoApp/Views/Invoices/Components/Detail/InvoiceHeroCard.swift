//
//  InvoiceHeroCard.swift
//  SuctoApp
//

import SwiftUI

/// Úvodní karta detailu: stav, protistrana a hlavní částka.
struct InvoiceHeroCard: View {
    let invoice: Invoice
    let counterparty: String?
    /// Zda ukázat základ bez DPH (jen u plátce).
    let showBasePrice: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text(invoice.actuarialNumber)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                StatusBadge(invoice: invoice)
                    .padding(2)
                    .background(.white, in: Capsule())
                    .id(invoice.statusId)
                    .transition(.scale.combined(with: .opacity))
            }

            Text(counterparty ?? "—")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Částka k úhradě")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                AnimatedAmount(value: invoice.endPrice, currency: invoice.currency?.symbol)
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if showBasePrice {
                    Text("bez DPH \(FormatterHelper.formatPrice(invoice.basePrice, currency: invoice.currency?.symbol))")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.top, Theme.Spacing.xs)

            if let due = invoice.dueDateAt {
                Label("Splatnost \(due)", systemImage: "calendar")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(invoice.isOverdue ? Color(hex: "#FFB4AB") : .white.opacity(0.85))
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Theme.brandGradient
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 220)
                    .offset(x: 130, y: -90)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous)),
        )
        .shadow(color: Theme.brand.opacity(0.3), radius: 18, y: 10)
        .animation(Motion.bouncy, value: invoice.statusId)
        .accessibilityElement(children: .combine)
    }
}

//
//  OverviewTopPartiesCard.swift
//  SuctoApp
//

import SwiftUI

/// Největší odběratelé (z vydaných faktur) a dodavatelé (z přijatých) roku jako dvě stránky slideru; uvnitř po měnách.
struct OverviewTopPartiesCard: View {
    let sections: [CurrencySection]
    let labels: OverviewLabels

    private enum Side: String, CaseIterable, Identifiable {
        case customers = "Odběratelé"
        case suppliers = "Dodavatelé"

        var id: String { rawValue }
        var color: Color { self == .customers ? OverviewStyle.revenueColor : OverviewStyle.costColor }
        var systemImage: String { self == .customers ? "arrow.down.left.circle" : "arrow.up.right.circle" }
    }

    @State private var scrolledID: String?

    private func parties(_ side: Side, in section: CurrencySection) -> [RankedParty] {
        side == .customers ? section.topCustomers : section.topSuppliers
    }

    /// Strany, které mají aspoň jednoho partnera v nějaké měně.
    private var visibleSides: [Side] {
        Side.allCases.filter { side in sections.contains { !parties(side, in: $0).isEmpty } }
    }

    private var currentSide: String { scrolledID ?? visibleSides.first?.id ?? "" }

    var body: some View {
        if !visibleSides.isEmpty {
            DetailCard(title: "Největší partneři", systemImage: "person.2") {
                if visibleSides.count == 1, let side = visibleSides.first {
                    page(for: side)
                } else {
                    sideChips
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: Theme.Spacing.l) {
                            ForEach(visibleSides) { side in
                                page(for: side)
                                    .containerRelativeFrame(.horizontal)
                                    .id(side.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $scrolledID)
                    .sensoryFeedback(.selection, trigger: scrolledID)
                }
                Text("Podle základu faktur bez DPH za zvolený rok.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .appear(delay: 0.3)
        }
    }

    private var sideChips: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(visibleSides) { side in
                let isSelected = currentSide == side.id
                Button {
                    withAnimation(Motion.standard) { scrolledID = side.id }
                } label: {
                    Label(side.rawValue, systemImage: side.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .background(
                            isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.surface),
                            in: Capsule(),
                        )
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(isSelected ? 0 : 0.08), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }

    /// Jedna strana: pro každou měnu žebříček pěti největších.
    private func page(for side: Side) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            ForEach(sections) { section in
                let list = parties(side, in: section)
                if !list.isEmpty {
                    if sections.count > 1 {
                        Text(section.currency).font(.subheadline.weight(.bold))
                    }
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, party in
                        HStack {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 22, alignment: .leading)
                            Text(party.name).font(.subheadline).lineLimit(1)
                            Spacer()
                            Text(FormatterHelper.formatWhole(party.amount, currency: section.currency))
                                .moneyStyle(.subheadline)
                                .foregroundStyle(side.color)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
    }
}

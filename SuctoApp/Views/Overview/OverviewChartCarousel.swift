//
//  OverviewChartCarousel.swift
//  SuctoApp
//

import SwiftUI

/// Grafy jednotlivých měn jako posuvný „slider“; chipy s měnou nahoře zároveň ukazují, která je vidět, a po klepnutí na ni přeskočí.
/// U jediné měny je to obyčejná karta bez chipů.
struct OverviewChartCarousel: View {
    let sections: [CurrencySection]
    let labels: OverviewLabels

    @State private var scrolledID: String?

    var body: some View {
        if sections.count == 1, let section = sections.first {
            OverviewChartCard(section: section, labels: labels, showsCurrency: false)
        } else {
            VStack(spacing: Theme.Spacing.s) {
                chips
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: Theme.Spacing.m) {
                        ForEach(sections) { section in
                            OverviewChartCard(section: section, labels: labels, showsCurrency: true)
                                .containerRelativeFrame(.horizontal)
                                .id(section.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledID)
                .scrollClipDisabled()
            }
            .sensoryFeedback(.selection, trigger: scrolledID)
        }
    }

    private var current: String { scrolledID ?? sections.first?.id ?? "" }

    private var chips: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(sections) { section in
                let isSelected = current == section.id
                Button {
                    withAnimation(Motion.standard) { scrolledID = section.id }
                } label: {
                    Text(section.currency)
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
                .accessibilityLabel("Graf \(section.currency)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }
}

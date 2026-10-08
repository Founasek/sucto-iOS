//
//  SegmentedTabs.swift
//  SuctoApp
//

import SwiftUI

/// Přepínač sekcí s plynule putující „pilulkou“ pod vybranou položkou.
struct SegmentedTabs: View {
    struct Item: Identifiable {
        let title: String
        let systemImage: String
        var id: String { title }
    }

    let items: [Item]
    @Binding var selection: Int
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                let isSelected = selection == index
                Button {
                    withAnimation(.snappy(duration: 0.3)) { selection = index }
                } label: {
                    Label(item.title, systemImage: item.systemImage)
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(isSelected ? .semibold : .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Theme.brandGradient)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                                    .shadow(color: Theme.brand.opacity(0.35), radius: 8, y: 3)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5))
        .sensoryFeedback(.selection, trigger: selection)
    }
}

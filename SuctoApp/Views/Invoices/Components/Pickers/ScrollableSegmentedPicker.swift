//
//  ScrollableSegmentedPicker.swift
//  SuctoApp
//
//  Created by Jan Founě on 02.11.2025.
//

import SwiftUI

struct ScrollableSegmentedPicker: View {
    @Binding var selectedTab: Int
    let tabs: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tabs.indices, id: \.self) { index in
                    Text(tabs[index])
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(selectedTab == index ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedTab == index ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(selectedTab == index ? .accentColor : .primary)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 44)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }
}

#Preview {
    @Previewable @State var selectedTab = 0
    ScrollableSegmentedPicker(
        selectedTab: $selectedTab,
        tabs: ["Vydané faktury", "Přijaté faktury", "Přijaté doklady", "Vydané doklady", "Účty"]
    )
}

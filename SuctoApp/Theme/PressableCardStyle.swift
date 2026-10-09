//
//  PressableCardStyle.swift
//  SuctoApp
//

import SwiftUI

/// Jemné zmáčknutí karty při klepnutí, bez výchozí modré barvy odkazu.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.primary)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

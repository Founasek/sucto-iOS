//
//  LoadingStateView.swift
//  SuctoApp
//
//  Created by Jan Founě on 01.11.2025.
//

import SwiftUI

struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentColor)

            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height * 0.6)
    }
}

#Preview("Načítání") {
    LoadingStateView(message: "Načítám faktury…")
}

/*
 LoadingStateView(message: "Načítám faktury…")
 */

//
//  ErrorStateView.swift
//  SuctoApp
//
//  Created by Jan Founě on 01.11.2025.
//

import SwiftUI

struct ErrorStateView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Nastala chyba")
                .font(.headline)
                .foregroundColor(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label("Zkusit znovu", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height * 0.6)
    }
}

#Preview("Základní chyba") {
    ErrorStateView(message: "Nepodařilo se načíst data ze serveru.")
}

#Preview("Chyba s tlačítkem") {
    ErrorStateView(
        message: "Nepodařilo se načíst fakturu. Zkontrolujte připojení a zkuste to znovu.",
        retryAction: {
            print("Retry stisknuto")
        }
    )
}

/*
 ErrorStateView(
     message: "Nepodařilo se načíst data ze serveru.",
     retryAction: { Task { await viewModel.loadInitialData() } }
 )

 */

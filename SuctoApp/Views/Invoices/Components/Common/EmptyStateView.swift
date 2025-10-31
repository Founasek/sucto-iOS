//
//  EmptyStateView.swift
//  SuctoApp
//
//  Created by Jan Founě on 31.10.2025.
//


import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let message: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(message)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: UIScreen.main.bounds.height * 0.6)
    }
}

//
//  ShareSheet.swift
//  SuctoApp
//

import SwiftUI
import UIKit

/// Soubor určený ke sdílení (např. CSV). Po zavření sdílecího okna se dočasný soubor smaže.
struct ShareableFile: Identifiable {
    let url: URL
    var id: URL { url }
}

struct ShareSheet: UIViewControllerRepresentable {
    let file: ShareableFile

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [file.url], applicationActivities: nil)
        let url = file.url
        controller.completionWithItemsHandler = { _, _, _, _ in try? FileManager.default.removeItem(at: url) }
        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

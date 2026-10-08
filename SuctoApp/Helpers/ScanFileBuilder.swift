//
//  ScanFileBuilder.swift
//  SuctoApp
//

import PDFKit
import UIKit

/// Připraví soubor k nahrání: jedna strana → JPEG, více stran → PDF.
enum ScanFileBuilder {
    private static let maximumDimension: CGFloat = 2500

    static func make(from images: [UIImage]) -> MultipartFile? {
        guard !images.isEmpty else { return nil }
        let stamp = fileStamp()

        if images.count == 1, let data = jpeg(images[0]) {
            return MultipartFile(fieldName: "scan[attachment]", fileName: "faktura_\(stamp).jpg", mimeType: "image/jpeg", data: data)
        }

        let document = PDFDocument()
        for (index, image) in images.enumerated() {
            if let page = PDFPage(image: downscaled(image)) { document.insert(page, at: index) }
        }
        guard let data = document.dataRepresentation() else { return nil }
        return MultipartFile(fieldName: "scan[attachment]", fileName: "faktura_\(stamp).pdf", mimeType: "application/pdf", data: data)
    }

    /// Soubor vybraný ve Files (PDF se nahraje beze změny, obrázek se zmenší).
    static func make(fromFileAt url: URL) -> MultipartFile? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return nil }

        if url.pathExtension.lowercased() == "pdf" {
            return MultipartFile(fieldName: "scan[attachment]", fileName: url.lastPathComponent, mimeType: "application/pdf", data: data)
        }
        guard let image = UIImage(data: data) else { return nil }
        return make(from: [image])
    }

    static func make(fromImageData data: Data) -> MultipartFile? {
        guard let image = UIImage(data: data) else { return nil }
        return make(from: [image])
    }

    // MARK: - Pomocné

    private static func jpeg(_ image: UIImage) -> Data? {
        downscaled(image).jpegData(compressionQuality: 0.85)
    }

    private static func downscaled(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maximumDimension else { return image }
        let scale = maximumDimension / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func fileStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}

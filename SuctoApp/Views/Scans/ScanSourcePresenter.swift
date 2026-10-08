//
//  ScanSourcePresenter.swift
//  SuctoApp
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import VisionKit

/// Odkud se doklad získá.
enum ScanSource: Identifiable {
    case camera, photos, files
    var id: Self { self }

    /// Skener dokumentů potřebuje skutečný fotoaparát (v simulátoru není).
    static var cameraAvailable: Bool { VNDocumentCameraViewController.isSupported }
}

/// Obalí VisionKit skener dokumentů (ořez a narovnání stránky).
private struct DocumentScanner: UIViewControllerRepresentable {
    let onFinish: ([UIImage]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_: VNDocumentCameraViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner
        init(_ parent: DocumentScanner) { self.parent = parent }

        func documentCameraViewController(_: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            parent.onFinish((0 ..< scan.pageCount).map { scan.imageOfPage(at: $0) })
        }

        func documentCameraViewControllerDidCancel(_: VNDocumentCameraViewController) {
            parent.onCancel()
        }

        func documentCameraViewController(_: VNDocumentCameraViewController, didFailWithError _: Error) {
            parent.onCancel()
        }
    }
}

private struct ScanSourcePresenterModifier: ViewModifier {
    @Binding var source: ScanSource?
    /// Zpracuje připravený soubor (nahrání na server).
    let onFile: (MultipartFile) -> Void
    let onFailure: (String) -> Void

    @State private var showPhotos = false
    @State private var showFiles = false
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            .onChange(of: source) { _, newValue in
                guard let newValue else { return }
                switch newValue {
                case .camera: showCamera = true
                case .photos: showPhotos = true
                case .files: showFiles = true
                }
                source = nil
            }
            .fullScreenCover(isPresented: $showCamera) {
                DocumentScanner { images in
                    showCamera = false
                    deliver(ScanFileBuilder.make(from: images))
                } onCancel: {
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotos, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    let data = try? await item.loadTransferable(type: Data.self)
                    photoItem = nil
                    deliver(data.flatMap(ScanFileBuilder.make(fromImageData:)))
                }
            }
            .fileImporter(isPresented: $showFiles, allowedContentTypes: [.pdf, .image]) { result in
                if case let .success(url) = result {
                    deliver(ScanFileBuilder.make(fromFileAt: url))
                }
            }
    }

    private func deliver(_ file: MultipartFile?) {
        if let file {
            onFile(file)
        } else {
            onFailure("Soubor se nepodařilo načíst.")
        }
    }
}

extension View {
    /// Zobrazí skener, výběr z fotek nebo ze Souborů podle `source` a výsledný soubor předá dál.
    func scanSourcePresenter(
        source: Binding<ScanSource?>,
        onFile: @escaping (MultipartFile) -> Void,
        onFailure: @escaping (String) -> Void = { _ in },
    ) -> some View {
        modifier(ScanSourcePresenterModifier(source: source, onFile: onFile, onFailure: onFailure))
    }
}

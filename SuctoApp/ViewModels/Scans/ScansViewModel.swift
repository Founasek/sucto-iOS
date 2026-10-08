//
//  ScansViewModel.swift
//  SuctoApp
//

import SwiftUI

/// Nahrávání skenů – sdílené dashboardem i seznamem skenů.
@MainActor
final class ScanUploadViewModel: ObservableObject {
    @Published private(set) var isUploading = false
    @Published var errorMessage: String?

    let companyId: Int
    private let session: SessionManager

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    /// Vrací `true`, pokud se nahrání povedlo.
    func upload(_ file: MultipartFile) async -> Bool {
        isUploading = true
        defer { isUploading = false }
        do {
            let _: EmptyResponse = try await session.upload(APIConstants.createScan(companyId: companyId), file: file)
            errorMessage = nil
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

@MainActor
final class ScansViewModel: ObservableObject {
    @Published private(set) var scans: [Scan] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasMorePages = true
    /// Skeny, ze kterých už v aplikaci vznikla faktura (viz `ScanLinkStore`).
    @Published private(set) var usedScanIds = ScanLinkStore.usedIds()

    let companyId: Int
    private let session: SessionManager
    private var currentPage = 1
    private var generation = 0
    private let thumbnails = NSCache<NSString, UIImage>()

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    var hasPendingScans: Bool { scans.contains(where: \.isPending) }

    func refresh() async {
        generation += 1
        currentPage = 1
        hasMorePages = true
        isLoading = false
        await loadNextPage()
    }

    func reloadUsedScans() {
        usedScanIds = ScanLinkStore.usedIds()
    }

    /// Tichá aktualizace první stránky (kontrola stavu zpracování) – nezahazuje už načtené další stránky.
    func poll() async {
        guard !isLoading,
              let result: [Scan] = try? await session.send(APIConstants.scans(companyId: companyId, page: 1))
        else { return }
        var updated = scans
        for scan in result {
            if let index = updated.firstIndex(where: { $0.id == scan.id }) { updated[index] = scan }
        }
        let known = Set(updated.map(\.id))
        scans = result.filter { !known.contains($0.id) } + updated
    }

    func loadNextPage() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        let myGeneration = generation
        defer { if myGeneration == generation { isLoading = false } }

        let page = currentPage
        do {
            let result: [Scan] = try await session.send(APIConstants.scans(companyId: companyId, page: page))
            guard myGeneration == generation else { return }
            scans = page == 1 ? result : scans + result.filter { new in !scans.contains { $0.id == new.id } }
            hasMorePages = !result.isEmpty
            currentPage = page + 1
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard myGeneration == generation else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Obrázek skenu (`thumb` pro seznam, `hd` pro náhled). Výsledky se drží v paměti.
    func image(for scan: Scan, version: String = "thumb") async -> UIImage? {
        let key = "\(scan.id)-\(version)" as NSString
        if let cached = thumbnails.object(forKey: key) { return cached }
        do {
            let data = try await session.download(
                APIConstants.scanData(companyId: companyId, scanId: scan.id, version: version),
            )
            guard let image = UIImage(data: data) else { return nil }
            thumbnails.setObject(image, forKey: key)
            return image
        } catch {
            return nil
        }
    }
}

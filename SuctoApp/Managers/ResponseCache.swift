//
//  ResponseCache.swift
//  SuctoApp
//

import CryptoKit
import Foundation

/// Diskový cache odpovědí GET, ze které se čte jen při výpadku připojení.
/// Data jsou finanční, proto jsou šifrovaná systémem (`completeFileProtection`)
/// a při odhlášení se mažou.
final class ResponseCache: Sendable {
    static let shared = ResponseCache()

    struct Entry {
        let data: Data
        let savedAt: Date
    }

    /// Starší záznamy se zahodí – zastaralá data by mohla mást víc než chybová hláška.
    private static let maxAge: TimeInterval = 30 * 24 * 3600

    private let directory: URL

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("ResponseCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        removeExpired()
    }

    /// Cachují se jen čtení bez hledání (hledané výrazy by cache zbytečně zahltily), bez předvyplněných formulářů
    /// a bez akcí. Úhrada faktury je v API `GET .../pay` (vytvoří pokladní doklad) – z cache by při výpadku
    /// připojení vrátila falešný úspěch.
    static func isCacheable(endpoint: String, method: HTTPMethod) -> Bool {
        let path = endpoint.split(separator: "?").first.map(String.init) ?? endpoint
        return method == .GET
            && !endpoint.contains("_cont")
            && !path.hasSuffix("/new")
            && !path.hasSuffix("/pay")
    }

    func store(_ data: Data, for endpoint: String) {
        let url = fileURL(for: endpoint)
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    func load(for endpoint: String) -> Entry? {
        let url = fileURL(for: endpoint)
        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let modified = attributes[.modificationDate] as? Date,
            Date().timeIntervalSince(modified) < Self.maxAge,
            let data = try? Data(contentsOf: url)
        else { return nil }
        return Entry(data: data, savedAt: modified)
    }

    func clear() {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        files.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    private func removeExpired() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
        )) ?? []
        for file in files {
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            if let modified, Date().timeIntervalSince(modified) >= Self.maxAge {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private func fileURL(for endpoint: String) -> URL {
        let digest = SHA256.hash(data: Data(endpoint.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name)
    }
}

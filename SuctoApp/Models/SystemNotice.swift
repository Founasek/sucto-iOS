//
//  SystemNotice.swift
//  SuctoApp
//

import Foundation

/// Zpráva ze sÚčta z `GET companies/{id}/dashboard` (`system_informations`: id, title, created_at, description, image).
struct SystemNotice: Identifiable, Equatable {
    let id: Int
    let title: String
    let createdAt: String?
    let description: String?
}

private struct RawSystemNotice: Decodable {
    let id: Int?
    let title: String?
    let createdAt: String?
    let description: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, description
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decodeIfPresent(Int.self, forKey: .id)
        title = container.lossyString(.title)
        createdAt = container.lossyString(.createdAt)
        description = container.lossyString(.description)
    }
}

/// Odpověď dashboardu. Dokumentace ukazuje objekt, tvar je ale tolerantní i k poli zpráv.
struct DashboardResponse: Decodable {
    let notices: [SystemNotice]

    private enum CodingKeys: String, CodingKey { case systemInformations = "system_informations" }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raws: [RawSystemNotice] = if let list = try? container.decode([RawSystemNotice].self, forKey: .systemInformations) {
            list
        } else if let single = try? container.decode(RawSystemNotice.self, forKey: .systemInformations) {
            [single]
        } else {
            []
        }
        notices = raws.compactMap { raw in
            guard let id = raw.id, let title = raw.title, !title.isEmpty else { return nil }
            return SystemNotice(id: id, title: title, createdAt: raw.createdAt, description: raw.description)
        }
    }
}

/// Které zprávy už uživatel zavřel (ukládá se jen id).
enum SystemNoticeStore {
    private static let key = "dismissedSystemNotices"

    static func isDismissed(_ id: Int) -> Bool {
        (UserDefaults.standard.array(forKey: key) as? [Int])?.contains(id) ?? false
    }

    static func dismiss(_ id: Int) {
        var ids = (UserDefaults.standard.array(forKey: key) as? [Int]) ?? []
        if !ids.contains(id) { ids.append(id) }
        UserDefaults.standard.set(ids, forKey: key)
    }
}

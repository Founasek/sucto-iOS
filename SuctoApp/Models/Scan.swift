//
//  Scan.swift
//  SuctoApp
//

import Foundation

/// Stav skenu podle API (`state_id`).
enum ScanState: Int {
    case uploaded = 1
    case processing = 2
    case processed = 3

    var title: String {
        switch self {
        case .uploaded: "Nahraná"
        case .processing: "Ve zpracování"
        case .processed: "Zpracovaná"
        }
    }

    var systemImage: String {
        switch self {
        case .uploaded: "arrow.up.circle.fill"
        case .processing: "hourglass"
        case .processed: "checkmark.circle.fill"
        }
    }
}

/// Naskenovaný doklad nahraný do sÚčto.
struct Scan: Identifiable, Hashable, Decodable {
    let id: String
    let contentType: String?
    let stateId: Int?
    let stateName: String?
    let createdAt: String?
    let actuarialId: Int?
    let partnerName: String?
    let totalPrice: String?

    var state: ScanState? { stateId.flatMap(ScanState.init(rawValue:)) }

    /// Měsíce (1. a 2. pád) pro čtení data ve tvaru „St 19. srpen 2020 13:05 +0200“.
    private static let monthNames: [String: Int] = {
        let names = [
            ["leden", "ledna"], ["únor", "února"], ["březen", "března"], ["duben", "dubna"],
            ["květen", "května"], ["červen", "června"], ["červenec", "července"], ["srpen", "srpna"],
            ["září"], ["říjen", "října"], ["listopad", "listopadu"], ["prosinec", "prosince"],
        ]
        var result: [String: Int] = [:]
        for (index, forms) in names.enumerated() {
            for form in forms {
                result[form] = index + 1
            }
        }
        return result
    }()

    /// Přečte datum nahrání z textu API; při jiném tvaru vrátí `nil`.
    static func parseCreated(_ text: String) -> Date? {
        let pattern = #"^\S+\s+(\d{1,2})\.\s+(\S+)\s+(\d{4})\s+(\d{1,2}):(\d{2})\s+([+-])(\d{2})(\d{2})$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }
        func group(_ index: Int) -> String? {
            Range(match.range(at: index), in: text).map { String(text[$0]) }
        }
        guard let day = group(1).flatMap(Int.init),
              let month = group(2).flatMap({ monthNames[$0.lowercased()] }),
              let year = group(3).flatMap(Int.init),
              let hour = group(4).flatMap(Int.init),
              let minute = group(5).flatMap(Int.init),
              let sign = group(6),
              let offsetHours = group(7).flatMap(Int.init),
              let offsetMinutes = group(8).flatMap(Int.init)
        else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        let seconds = (offsetHours * 3600 + offsetMinutes * 60) * (sign == "-" ? -1 : 1)
        guard let zone = TimeZone(secondsFromGMT: seconds) else { return nil }
        calendar.timeZone = zone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))
    }

    /// Datum nahrání v čitelné podobě; když se formát nepodaří přečíst, vrátí text z API.
    var createdDisplay: String? {
        guard let createdAt else { return nil }
        guard let date = Self.parseCreated(createdAt) else { return createdAt }
        return date.formatted(.dateTime.day().month(.wide).year().hour().minute().locale(Locale(identifier: "cs_CZ")))
    }

    /// Ze zpracovaného skenu bez navázané faktury lze vytvořit fakturu.
    var canCreateInvoice: Bool { state == .processed && actuarialId == nil }

    /// Skeny, které server ještě zpracovává (kvůli obnovování seznamu).
    var isPending: Bool { state == .uploaded || state == .processing }

    enum CodingKeys: String, CodingKey {
        case id
        case contentType = "content_type"
        case stateId = "state_id"
        case stateName = "state"
        case createdAt = "created_at"
        case actuarialId = "actuarial_id"
        case partnerName = "partner_name"
        case totalPrice = "total_price"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        contentType = container.lossyString(.contentType)
        stateId = try? container.decodeIfPresent(Int.self, forKey: .stateId)
        stateName = container.lossyString(.stateName)
        createdAt = container.lossyString(.createdAt)
        actuarialId = try? container.decodeIfPresent(Int.self, forKey: .actuarialId)
        partnerName = container.lossyString(.partnerName)
        totalPrice = container.lossyString(.totalPrice)
    }
}

//
//  DueNotifier.swift
//  SuctoApp
//

import Foundation
import UserNotifications

/// Denní upozornění na splatnosti (v 9:00). Plánuje se z posledního snapshotu při každém obnovení dat v aplikaci,
/// takže se bez otevření aplikace nové faktury neprojeví. V textu nejsou částky ani jména (zobrazí se na zamčené obrazovce).
@MainActor
final class DueNotifier: ObservableObject {
    static let shared = DueNotifier()

    private static let enabledKey = "dueNotificationsEnabled"
    private static let identifierPrefix = "due-"
    private static let daysAhead = 14
    private static let hour = 9

    @Published private(set) var isEnabled: Bool

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    /// Zapne/vypne upozornění. Zapnutí vyžádá oprávnění; vrací `false`, pokud ho uživatel nedal.
    @discardableResult
    func setEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            let granted = await (try? UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else {
                isEnabled = false
                UserDefaults.standard.set(false, forKey: Self.enabledKey)
                return false
            }
            isEnabled = true
            UserDefaults.standard.set(true, forKey: Self.enabledKey)
            if let snapshot = DueSnapshotStore.load() { await reschedule(from: snapshot) }
        } else {
            isEnabled = false
            UserDefaults.standard.set(false, forKey: Self.enabledKey)
            cancelAll()
        }
        return true
    }

    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func reschedule(from snapshot: DueSnapshot) async {
        guard isEnabled else { return }
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) },
        )

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        var isFirst = true

        for offset in 0 ..< Self.daysAhead {
            guard
                let day = calendar.date(byAdding: .day, value: offset, to: today),
                let fireDate = calendar.date(bySettingHour: Self.hour, minute: 0, second: 0, of: day),
                fireDate > now
            else { continue }

            let dueThatDay = snapshot.items.filter { calendar.startOfDay(for: $0.dueDate) == day }
            let overdue = isFirst ? snapshot.items.count(where: { calendar.startOfDay(for: $0.dueDate) < day }) : 0
            guard !dueThatDay.isEmpty || overdue > 0 else { continue }
            isFirst = false

            let toPay = dueThatDay.filter(\.isIncoming).count
            let toReceive = dueThatDay.count - toPay
            var lines: [String] = []
            if toPay > 0 { lines.append("K úhradě (přijaté): \(toPay)") }
            if toReceive > 0 { lines.append("Čekáme platbu (vydané): \(toReceive)") }
            if overdue > 0 { lines.append("Po splatnosti dosud: \(overdue)") }

            let content = UNMutableNotificationContent()
            content.title = "Splatnosti dnes · \(snapshot.companyName)"
            content.body = lines.joined(separator: "\n")
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let request = UNNotificationRequest(
                identifier: Self.identifierPrefix + "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false),
            )
            try? await center.add(request)
        }
    }
}

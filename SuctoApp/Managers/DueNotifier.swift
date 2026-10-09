//
//  DueNotifier.swift
//  SuctoApp
//

import Foundation
import UserNotifications

/// Denní upozornění na splatnosti (v 9:00). Plánuje se z posledního snapshotu při každém obnovení dat v aplikaci,
/// takže se bez otevření aplikace nové faktury neprojeví. V textu nejsou částky ani jména (zobrazí se na zamčené obrazovce).
@MainActor
final class DueNotifier: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = DueNotifier()

    /// Odkaz z klepnutí na upozornění, který ještě nikdo nezpracoval (např. aplikace se právě spouští).
    private var pendingURL: URL?
    static let openLinkNotification = Notification.Name("DueNotifierOpenLink")

    private static let enabledKey = "dueNotificationsEnabled"
    private static let identifierPrefix = "due-"
    private static let daysAhead = 14
    private static let hour = 9

    @Published private(set) var isEnabled: Bool

    override private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        super.init()
    }

    /// Zaregistruje obsluhu klepnutí na upozornění. Musí proběhnout při startu aplikace.
    func activate() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// Vydá a zapomene čekající odkaz (cold start z upozornění).
    func takePendingURL() -> URL? {
        defer { pendingURL = nil }
        return pendingURL
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Upozornění se ukáže i při otevřené aplikaci.
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// Klepnutí na upozornění otevře seznam faktur po splatnosti (stejný odkaz jako z widgetu).
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
    ) async {
        guard let text = response.notification.request.content.userInfo["url"] as? String,
              let url = URL(string: text), DueLink.parse(url) != nil
        else { return }
        await MainActor.run {
            pendingURL = url
            NotificationCenter.default.post(name: Self.openLinkNotification, object: url)
        }
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
            let overdueItems = isFirst ? snapshot.items.filter { calendar.startOfDay(for: $0.dueDate) < day } : []
            let overdue = overdueItems.count
            guard !dueThatDay.isEmpty || overdue > 0 else { continue }
            isFirst = false

            let toPay = dueThatDay.filter(\.isIncoming).count
            let toReceive = dueThatDay.count - toPay
            var lines: [String] = []
            if toPay > 0 { lines.append("K úhradě (přijaté): \(toPay)") }
            if toReceive > 0 { lines.append("Čekáme platbu (vydané): \(toReceive)") }
            if overdue > 0 { lines.append("Po splatnosti dosud: \(overdue)") }

            // Klepnutí míří na stranu, které se upozornění týká víc (při shodě vydané).
            let relevant = dueThatDay + overdueItems
            let incomingCount = relevant.filter(\.isIncoming).count
            let linkIsIncoming = incomingCount > relevant.count - incomingCount

            let content = UNMutableNotificationContent()
            content.title = "Splatnosti dnes · \(snapshot.companyName)"
            content.body = lines.joined(separator: "\n")
            content.sound = .default
            if let url = DueLink.url(companyId: snapshot.companyId, isIncoming: linkIsIncoming) {
                content.userInfo = ["url": url.absoluteString]
            }

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

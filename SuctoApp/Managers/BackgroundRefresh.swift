//
//  BackgroundRefresh.swift
//  SuctoApp
//

import BackgroundTasks
import Foundation

/// Pravidelná obnova dat widgetu a upozornění na splatnost na pozadí, aby byla čerstvá i bez otevření aplikace.
///
/// iOS úlohu spouští podle vlastního uvážení (typicky několikrát denně u často používané aplikace, nikdy přesně
/// na čas a ne při vypnutém „Obnovení na pozadí“ či úsporném režimu), proto je to jen doplněk k obnově
/// při otevření aplikace. Obnovuje se naposledy otevřená firma (ze snapshotu); bez přihlášení se nic neděje.
enum BackgroundRefresh {
    /// Musí odpovídat `BGTaskSchedulerPermittedIdentifiers` v `Config/SuctoApp-Info.plist`.
    static let identifier = "cz.sucto.SuctoApp.refresh"

    /// Nejdřív za tuto dobu od naplánování.
    private static let minimumInterval: TimeInterval = 4 * 3600

    /// Požádá iOS o další spuštění. Volá se při odchodu do pozadí a po dokončení úlohy.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: minimumInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Log.debug("⚠️ Obnovu na pozadí se nepodařilo naplánovat: \(error.localizedDescription)")
        }
    }

    /// Vlastní práce úlohy: načte splatnosti poslední firmy, uloží snapshot, obnoví widget a upozornění.
    /// Používá vlastní `SessionManager` (token z Keychainu); bez tokenu ani snapshotu nic nedělá.
    @MainActor
    static func perform() async {
        defer { schedule() }
        guard let snapshot = DueSnapshotStore.load(), let companyId = snapshot.companyId else { return }
        let session = SessionManager()
        guard session.isLoggedIn else { return }
        await DueSnapshotService(session: session).refresh(companyId: companyId, companyName: snapshot.companyName)
    }
}

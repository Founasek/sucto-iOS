//
//  SettingsView.swift
//  SuctoApp
//

import SwiftUI

/// Nastavení aplikace na jednom místě: zabezpečení, upozornění, uložená data a informace o aplikaci.
struct SettingsView: View {
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var navManager: NavigationManager
    @EnvironmentObject private var appLock: AppLock
    @ObservedObject private var dueNotifier = DueNotifier.shared

    @State private var hasSavedLogin = CredentialStore.hasSavedLogin()
    @State private var showNotificationsDenied = false
    @State private var offlineDataCleared = false

    var body: some View {
        Form {
            securitySection
            notificationsSection
            widgetSection
            dataSection
            aboutSection

            Section {
                Button(role: .destructive) {
                    session.logout()
                    navManager.reset()
                } label: {
                    Label("Odhlásit se", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Nastavení")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { hasSavedLogin = CredentialStore.hasSavedLogin() }
        .alert("Upozornění jsou zakázaná", isPresented: $showNotificationsDenied) {
            Button("Otevřít Nastavení") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button("Zrušit", role: .cancel) {}
        } message: {
            Text("Povolte oznámení pro sÚčto v Nastavení iOS.")
        }
    }

    // MARK: - Sekce

    private var securitySection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { appLock.isEnabled },
                set: { newValue in Task { await appLock.setEnabled(newValue) } },
            )) {
                Label("Zámek aplikace (\(appLock.methodName))", systemImage: "lock")
            }

            if appLock.isEnabled {
                Picker(selection: $appLock.delay) {
                    ForEach(AppLock.Delay.allCases) { delay in
                        Text(delay.title).tag(delay)
                    }
                } label: {
                    Label("Zamknout", systemImage: "timer")
                }
            }

            LabeledContent {
                if hasSavedLogin {
                    Button("Zapomenout", role: .destructive) {
                        CredentialStore.delete()
                        hasSavedLogin = false
                    }
                } else {
                    Text("Nastaví se při přihlášení").foregroundStyle(.secondary)
                }
            } label: {
                Label("Rychlé přihlášení", systemImage: "faceid")
            }
        } header: {
            Text("Zabezpečení")
        } footer: {
            Text("Zámek se zapne po odchodu z aplikace na zvolenou dobu. Po studeném startu je aplikace zamčená vždy. Rychlé přihlášení ukládá údaje jen do zabezpečeného úložiště tohoto zařízení.")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { dueNotifier.isEnabled },
                set: { newValue in
                    Task { if await !dueNotifier.setEnabled(newValue) { showNotificationsDenied = true } }
                },
            )) {
                Label("Upozornění na splatnost", systemImage: "bell")
            }
        } header: {
            Text("Upozornění")
        } footer: {
            Text("Denně v 9:00 vás upozorní na faktury splatné ten den a po splatnosti. V textu nejsou částky ani jména. Plánuje se při otevření aplikace.")
        }
    }

    private var widgetSection: some View {
        Section {
            Label("Podržte prst na ploše, klepněte na + a vyberte „sÚčto – splatnosti“.", systemImage: "square.grid.2x2")
                .font(.subheadline)
        } header: {
            Text("Widget")
        } footer: {
            Text("Widget se obnoví vždy, když v aplikaci otevřete firmu. Částky se na zamčené obrazovce skryjí.")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                ResponseCache.shared.clear()
                offlineDataCleared = true
            } label: {
                Label(offlineDataCleared ? "Offline data smazána" : "Smazat offline data", systemImage: "trash")
            }
            .disabled(offlineDataCleared)
        } header: {
            Text("Data")
        } footer: {
            Text("Offline data jsou uložené kopie naposledy načtených seznamů. Při odhlášení se mažou samy.")
        }
    }

    private var aboutSection: some View {
        Section("O aplikaci") {
            LabeledContent("Verze", value: Self.versionText)
            if let url = URL(string: "https://www.sucto.cz") {
                Link(destination: url) {
                    Label("sucto.cz", systemImage: "safari")
                }
            }
        }
    }

    private static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

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
    @EnvironmentObject private var theme: ThemeManager
    @ObservedObject private var dueNotifier = DueNotifier.shared

    @State private var hasSavedLogin = CredentialStore.hasSavedLogin()
    @State private var showNotificationsDenied = false
    @State private var offlineDataCleared = false
    @AppStorage(ReminderSettings.enabledKey) private var remindersEnabled = false
    @AppStorage(DueNotifier.detailsKey) private var notificationDetails = false

    var body: some View {
        Form {
            appearanceSection
            securitySection
            notificationsSection
            remindersSection
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

    private var appearanceSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.m) {
                    ForEach(AppAccent.allCases) { accent in
                        accentSwatch(accent)
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        } header: {
            Text("Vzhled")
        } footer: {
            Text("Barva aplikace platí pro ovládací prvky, tlačítka a hlavní karty. Zaplacené faktury, výnosy a upozornění zůstávají ve svých barvách.")
        }
    }

    private func accentSwatch(_ accent: AppAccent) -> some View {
        let selected = theme.accent == accent
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { theme.accent = accent }
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(accent.gradient)
                    .frame(width: 44, height: 44)
                    .overlay {
                        if selected {
                            Image(systemName: "checkmark").font(.headline.weight(.bold)).foregroundStyle(.white)
                        }
                    }
                    .overlay(Circle().strokeBorder(Color.primary.opacity(selected ? 0.5 : 0.1), lineWidth: selected ? 2 : 0.5).padding(-3))
                Text(accent.title).font(.caption2).foregroundStyle(selected ? Color.primary : Color.secondary)
            }
            .padding(.horizontal, 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accent.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var securitySection: some View {
        Section {
            LabeledContent {
                Text(appLock.isEnabled ? "Vždy zapnutý" : "Nedostupný").foregroundStyle(.secondary)
            } label: {
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
            Text(appLock.isEnabled
                ? "Zámek nejde vypnout, aplikace ukazuje finanční údaje. Zamkne se po odchodu z aplikace na zvolenou dobu a po studeném startu vždy. Rychlé přihlášení ukládá údaje jen do zabezpečeného úložiště tohoto zařízení."
                : "Na zařízení není nastavený kód ani Face ID / Touch ID, aplikaci proto nelze zamknout. Nastavte kód zařízení v Nastavení iOS.")
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
            if dueNotifier.isEnabled {
                Toggle(isOn: $notificationDetails) {
                    Label("Podrobnosti v upozornění", systemImage: "eye")
                }
                .onChange(of: notificationDetails) {
                    Task { await dueNotifier.rescheduleFromStoredSnapshot() }
                }
            }
        } header: {
            Text("Upozornění")
        } footer: {
            Text("Denně v 9:00 vás upozorní na faktury splatné ten den a po splatnosti. Upozornění se zobrazí i na zamčeném telefonu, proto je ve výchozím stavu bez názvu firmy a počtů. Podrobnosti si zapněte jen tehdy, když vám to nevadí. Plánuje se při otevření aplikace.")
        }
    }

    private var remindersSection: some View {
        Section {
            Toggle(isOn: $remindersEnabled) {
                Label("Upomínky odběratelům", systemImage: "bell.badge")
            }
            if remindersEnabled {
                NavigationLink {
                    ReminderTemplateView()
                } label: {
                    Label("Text upomínky", systemImage: "text.alignleft")
                }
            }
        } header: {
            Text("Upomínky")
        } footer: {
            Text("Ve výchozím stavu vypnuto. Po zapnutí se u vydaných faktur po splatnosti objeví tlačítko „Odeslat upomínku“. Nic se neodesílá automaticky – každou upomínku potvrdíte a text můžete upravit.")
        }
    }

    private var widgetSection: some View {
        Section {
            Label("Podržte prst na ploše, klepněte na + a vyberte „sÚčto – splatnosti“.", systemImage: "square.grid.2x2")
                .font(.subheadline)
            LabeledContent("Data naposledy aktualizována") {
                if let updated = DueSnapshotStore.load()?.updatedAt {
                    Text(updated.formatted(.dateTime.day().month().hour().minute().locale(Locale(identifier: "cs_CZ"))))
                } else {
                    Text("zatím nikdy").foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Widget")
        } footer: {
            Text("Widget a upozornění se obnoví při otevření firmy v aplikaci a také na pozadí, když to iOS dovolí (nárazově, ne na minutu přesně). Částky a jména protistran se na zamčené obrazovce skryjí.")
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

//
//  OverdueReminderCard.swift
//  SuctoApp
//

import SwiftUI

/// Karta u vydané faktury po splatnosti s tlačítkem „Odeslat upomínku“.
/// Ukazuje se jen když je upomínání v Nastavení vědomě zapnuté a faktura je po splatnosti. Nic se neodesílá samo.
struct OverdueReminderCard: View {
    let invoice: Invoice
    let onSend: () -> Void

    private var overdueDays: Int {
        guard let due = invoice.dueDate else { return 0 }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: due), to: calendar.startOfDay(for: Date())).day ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Faktura je \(ReminderSettings.days(max(overdueDays, 0))) po splatnosti")
                        .font(.subheadline.weight(.semibold))
                    if let last = ReminderLog.lastSent(invoiceId: invoice.id) {
                        Text("Upomínka naposledy odeslána \(last.formatted(.dateTime.day().month().year().locale(Locale(identifier: "cs_CZ"))))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Zákazníkovi můžete poslat upomínku. Text před odesláním upravíte.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }

            Button(action: onSend) {
                Label("Odeslat upomínku", systemImage: "paperplane")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .card()
    }
}

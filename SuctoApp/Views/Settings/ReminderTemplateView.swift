//
//  ReminderTemplateView.swift
//  SuctoApp
//

import SwiftUI

/// Úprava výchozího textu upomínky. Zástupné znaky se při odeslání nahradí údaji faktury.
struct ReminderTemplateView: View {
    @State private var text = ReminderSettings.template

    var body: some View {
        Form {
            Section {
                TextEditor(text: $text)
                    .frame(minHeight: 260)
                    .font(.body)
            } header: {
                Text("Text upomínky")
            } footer: {
                Text("Tento text se předvyplní do okna upomínky. Před každým odesláním ho můžete ještě upravit.")
            }

            Section("Zástupné znaky") {
                ForEach(ReminderSettings.placeholders, id: \.token) { placeholder in
                    HStack {
                        Text(placeholder.token)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        Text(placeholder.meaning)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            Section {
                Button("Obnovit výchozí text", role: .destructive) {
                    ReminderSettings.resetTemplate()
                    text = ReminderSettings.defaultTemplate
                }
                .disabled(text == ReminderSettings.defaultTemplate)
            }
        }
        .navigationTitle("Text upomínky")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: text) { ReminderSettings.template = text }
    }
}

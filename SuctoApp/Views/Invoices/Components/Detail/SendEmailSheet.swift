//
//  SendEmailSheet.swift
//  SuctoApp
//

import SwiftUI

/// Formulář pro odeslání faktury e-mailem. `onSend` vrací text chyby, nebo `nil` při úspěchu.
struct SendEmailSheet: View {
    let invoiceNumber: String
    let onSend: (_ email: String, _ comment: String) async -> String?

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var comment = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case email, comment }

    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard let at = trimmed.firstIndex(of: "@") else { return false }
        let domain = trimmed[trimmed.index(after: at)...]
        return trimmed.startIndex < at && domain.contains(".") && !domain.hasSuffix(".") && !trimmed.contains(" ")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("E-mail příjemce", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .comment }
                } header: {
                    Text("Komu")
                } footer: {
                    Text("Faktura \(invoiceNumber) se odešle jako příloha.")
                }

                Section("Zpráva (nepovinná)") {
                    TextField("Doplňující text", text: $comment, axis: .vertical)
                        .lineLimit(2 ... 5)
                        .focused($focusedField, equals: .comment)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Odeslat e-mailem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušit") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        send()
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Odeslat").fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValidEmail || isSending)
                }
            }
            .onAppear { focusedField = .email }
            .sensoryFeedback(.error, trigger: errorMessage) { _, new in new != nil }
        }
        .presentationDetents([.medium, .large])
    }

    private func send() {
        focusedField = nil
        isSending = true
        errorMessage = nil
        Task {
            let error = await onSend(email.trimmingCharacters(in: .whitespaces), comment)
            isSending = false
            if let error {
                errorMessage = error
            } else {
                dismiss()
            }
        }
    }
}

#Preview {
    SendEmailSheet(invoiceNumber: "2025000012") { _, _ in nil }
}

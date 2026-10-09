//
//  SendEmailSheet.swift
//  SuctoApp
//

import SwiftUI

/// Formulář pro odeslání faktury e-mailem. `onSend` vrací text chyby, nebo `nil` při úspěchu.
struct SendEmailSheet: View {
    let invoiceNumber: String
    var title = "Odeslat e-mailem"
    var sendTitle = "Odeslat"
    var commentHeader = "Zpráva (nepovinná)"
    /// Poznámka pod zprávou (např. kdy byla naposledy odeslána upomínka).
    var commentFooter: String?
    var commentLines: ClosedRange<Int> = 2 ... 5
    let onSend: (_ email: String, _ comment: String) async -> String?

    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var comment: String
    @State private var isSending = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case email, comment }

    init(
        invoiceNumber: String,
        title: String = "Odeslat e-mailem",
        sendTitle: String = "Odeslat",
        commentHeader: String = "Zpráva (nepovinná)",
        commentFooter: String? = nil,
        commentLines: ClosedRange<Int> = 2 ... 5,
        initialEmail: String = "",
        initialComment: String = "",
        onSend: @escaping (_ email: String, _ comment: String) async -> String?,
    ) {
        self.invoiceNumber = invoiceNumber
        self.title = title
        self.sendTitle = sendTitle
        self.commentHeader = commentHeader
        self.commentFooter = commentFooter
        self.commentLines = commentLines
        self.onSend = onSend
        _email = State(initialValue: initialEmail)
        _comment = State(initialValue: initialComment)
    }

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

                Section {
                    TextField("Doplňující text", text: $comment, axis: .vertical)
                        .lineLimit(commentLines)
                        .focused($focusedField, equals: .comment)
                } header: {
                    Text(commentHeader)
                } footer: {
                    if let commentFooter { Text(commentFooter) }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
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
                            Text(sendTitle).fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValidEmail || isSending)
                }
            }
            .onAppear { focusedField = email.isEmpty ? .email : nil }
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

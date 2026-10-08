//
//  InvoiceLineEditSheet.swift
//  SuctoApp
//

import SwiftUI

/// Přidání nebo úprava jedné položky existující faktury. `onSave`/`onDelete` vrací text chyby, nebo `nil` při úspěchu.
struct InvoiceLineEditSheet: View {
    let isEditing: Bool
    let currency: String?
    let session: SessionManager
    let onSave: (InvoiceLineRequest) async -> String?
    let onDelete: (() async -> String?)?

    @Environment(\.dismiss) private var dismiss
    @State private var draft: InvoiceLineDraft
    @State private var vats: [Vat] = []
    @State private var isLoadingVats = true
    @State private var vatsFailed = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var confirmDelete = false

    init(
        item: InvoiceItem?,
        currency: String?,
        session: SessionManager,
        onSave: @escaping (InvoiceLineRequest) async -> String?,
        onDelete: (() async -> String?)? = nil,
    ) {
        isEditing = item != nil
        self.currency = currency
        self.session = session
        self.onSave = onSave
        self.onDelete = onDelete
        _draft = State(initialValue: item.map(InvoiceLineDraft.init) ?? InvoiceLineDraft())
    }

    private var vatRate: Double {
        vats.first { $0.id == draft.vatId }.flatMap { Double($0.value.replacingOccurrences(of: ",", with: ".")) } ?? 0
    }

    private var amounts: LineAmounts { draft.amounts(vatRate: vatRate) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Položka") {
                    TextField("Název *", text: $draft.name)
                    LabeledContent("Množství *") {
                        TextField("0", value: $draft.quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Jednotka") {
                        TextField("ks / h / MD", text: $draft.unitName)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Cena za jednotku *") {
                        TextField("0", value: $draft.unitPrice, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Sleva (%)") {
                        TextField("0", value: $draft.discountPercentage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Sazba DPH *", selection: $draft.vatId) {
                        Text("Vyberte…").tag(Int?.none)
                        ForEach(vats) { vat in
                            Text("\(vat.value) %").tag(Int?.some(vat.id))
                        }
                    }
                }

                Section("Souhrn řádku") {
                    LabeledContent("Základ") { Text(FormatterHelper.formatPrice(String(amounts.base), currency: currency)).monospacedDigit() }
                    LabeledContent("DPH") { Text(FormatterHelper.formatPrice(String(amounts.tax), currency: currency)).monospacedDigit() }
                    LabeledContent("Celkem") {
                        Text(FormatterHelper.formatPrice(String(amounts.total), currency: currency)).moneyStyle(.subheadline)
                    }
                }

                if vatsFailed {
                    Section {
                        Label("Sazby DPH se nepodařilo načíst.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Button("Zkusit znovu") { Task { await loadVats() } }
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }

                if isEditing, onDelete != nil {
                    Section {
                        Button("Smazat položku", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(isEditing ? "Upravit položku" : "Nová položka")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zrušit") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if isSaving { ProgressView() } else { Text("Uložit").fontWeight(.semibold) }
                    }
                    .disabled(!draft.isValid || isSaving || isLoadingVats)
                }
            }
            .confirmationDialog("Smazat položku?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Smazat", role: .destructive) { delete() }
                Button("Zrušit", role: .cancel) {}
            }
            .task { await loadVats() }
            .sensoryFeedback(.error, trigger: errorMessage) { _, new in new != nil }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private func loadVats() async {
        isLoadingVats = true
        vatsFailed = false
        defer { isLoadingVats = false }
        let countryId = session.selectedCompany?.countryId ?? 1
        do {
            let loaded: [Vat] = try await session.send(APIConstants.vats(countryId: countryId))
            // Nabízí se jen platné sazby, ale sazba už použitá na řádku zůstane vybratelná.
            vats = loaded.filter { $0.validTo == nil || $0.id == draft.vatId }
        } catch is CancellationError {
            return
        } catch {
            vatsFailed = true
        }
    }

    private func save() {
        guard let request = InvoiceLineRequest(draft, vatRate: vatRate) else { return }
        isSaving = true
        errorMessage = nil
        Task {
            let error = await onSave(request)
            isSaving = false
            if let error { errorMessage = error } else { dismiss() }
        }
    }

    private func delete() {
        guard let onDelete else { return }
        isSaving = true
        errorMessage = nil
        Task {
            let error = await onDelete()
            isSaving = false
            if let error { errorMessage = error } else { dismiss() }
        }
    }
}

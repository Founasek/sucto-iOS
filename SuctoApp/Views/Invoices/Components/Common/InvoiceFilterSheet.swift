//
//  InvoiceFilterSheet.swift
//  SuctoApp
//

import SwiftUI

/// Podrobné filtry seznamu faktur. Změny se použijí až tlačítkem „Použít“.
struct InvoiceFilterSheet: View {
    @Binding var filter: InvoiceAdvancedFilter
    @Environment(\.dismiss) private var dismiss
    @State private var draft: InvoiceAdvancedFilter

    init(filter: Binding<InvoiceAdvancedFilter>) {
        _filter = filter
        _draft = State(initialValue: filter.wrappedValue)
    }

    private var isPriceRangeValid: Bool {
        guard let min = draft.minPrice, let max = draft.maxPrice else { return true }
        return min <= max
    }

    private var areDatesValid: Bool {
        func valid(_ from: Date?, _ to: Date?) -> Bool {
            guard let from, let to else { return true }
            return from <= to
        }
        return valid(draft.issueFrom, draft.issueTo) && valid(draft.dueFrom, draft.dueTo)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Stav") {
                    Picker("Stav", selection: $draft.status) {
                        Text("Všechny").tag(Invoice.Status?.none)
                        ForEach(Invoice.Status.allCases, id: \.self) { status in
                            Text(status.title).tag(Invoice.Status?.some(status))
                        }
                    }
                }

                Section("Datum vystavení") {
                    OptionalDateRow(title: "Od", date: $draft.issueFrom)
                    OptionalDateRow(title: "Do", date: $draft.issueTo)
                }

                Section("Splatnost") {
                    OptionalDateRow(title: "Od", date: $draft.dueFrom)
                    OptionalDateRow(title: "Do", date: $draft.dueTo)
                }

                Section {
                    TextField("Od", value: $draft.minPrice, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Do", value: $draft.maxPrice, format: .number)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Částka s DPH")
                } footer: {
                    if !isPriceRangeValid {
                        Text("Dolní hranice je vyšší než horní.").foregroundStyle(.red)
                    } else if !areDatesValid {
                        Text("Datum „Od“ je pozdější než „Do“.").foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Filtry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušit") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Vynulovat") { draft = InvoiceAdvancedFilter() }
                        .disabled(!draft.isActive)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Použít") {
                        filter = draft
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isPriceRangeValid || !areDatesValid)
                }
            }
        }
        .presentationDetents([.large])
    }
}

/// Řádek s volitelným datem: přepínač zapíná výběr data.
private struct OptionalDateRow: View {
    let title: String
    @Binding var date: Date?

    var body: some View {
        Toggle(title, isOn: Binding(
            get: { date != nil },
            set: { date = $0 ? (date ?? Date()) : nil },
        ))
        if let current = date {
            DatePicker(
                title,
                selection: Binding(get: { current }, set: { date = $0 }),
                displayedComponents: .date,
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

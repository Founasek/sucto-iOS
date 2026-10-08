//
//  PartnerFormView.swift
//  SuctoApp
//

import SwiftUI

/// Formulář partnera (nový i úprava). `onSaved` dostane uloženého partnera ze serveru.
struct PartnerFormView: View {
    @StateObject private var viewModel: PartnerFormViewModel
    let onSaved: (PartnerRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Field?

    private enum Field { case name, ic, dic, street, city, zip, email, phone, web, due }

    init(companyId: Int, mode: PartnerFormViewModel.Mode, session: SessionManager, onSaved: @escaping (PartnerRecord) -> Void) {
        _viewModel = StateObject(wrappedValue: PartnerFormViewModel(companyId: companyId, mode: mode, session: session))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.referenceDataFailed {
                    ErrorStateView(message: viewModel.errorMessage ?? "Nepodařilo se načíst číselníky.") {
                        Task { await viewModel.loadReferenceData() }
                    }
                } else {
                    form
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušit") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Uložit").fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .task { await viewModel.loadReferenceData() }
            .sensoryFeedback(.error, trigger: viewModel.errorMessage) { _, new in new != nil }
        }
        .interactiveDismissDisabled(viewModel.isSaving)
    }

    private var form: some View {
        Form {
            Section("Základní údaje") {
                TextField("Název *", text: $viewModel.name)
                    .focused($focused, equals: .name)
                    .textContentType(.organizationName)
                TextField("IČ", text: $viewModel.ic)
                    .focused($focused, equals: .ic)
                    .keyboardType(.numbersAndPunctuation)
                TextField("DIČ", text: $viewModel.dic)
                    .focused($focused, equals: .dic)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Toggle("Plátce DPH", isOn: $viewModel.isTaxable)
            }

            Section("Role") {
                Toggle("Odběratel", isOn: $viewModel.isCustomer)
                Toggle("Dodavatel", isOn: $viewModel.isSupplier)
            }

            Section("Adresa") {
                TextField("Ulice a číslo", text: $viewModel.street)
                    .focused($focused, equals: .street)
                    .textContentType(.streetAddressLine1)
                TextField("Město *", text: $viewModel.city)
                    .focused($focused, equals: .city)
                    .textContentType(.addressCity)
                TextField("PSČ *", text: $viewModel.zip)
                    .focused($focused, equals: .zip)
                    .textContentType(.postalCode)
                    .keyboardType(.numbersAndPunctuation)
                Picker("Země *", selection: $viewModel.countryId) {
                    Text("Vyberte…").tag(Int?.none)
                    ForEach(viewModel.countries) { country in
                        Text(country.name).tag(Int?.some(country.id))
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                TextField("E-mail", text: $viewModel.email)
                    .focused($focused, equals: .email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                TextField("Telefon", text: $viewModel.phone)
                    .focused($focused, equals: .phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                TextField("Web", text: $viewModel.web)
                    .focused($focused, equals: .web)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Kontakt")
            } footer: {
                if !viewModel.isEmailValid {
                    Text("E-mail nemá správný tvar.").foregroundStyle(.red)
                }
            }

            Section {
                Picker("Měna *", selection: $viewModel.currencyId) {
                    Text("Vyberte…").tag(Int?.none)
                    ForEach(viewModel.currencies) { currency in
                        Text(currency.isoCode ?? "—").tag(currency.id)
                    }
                }
                Picker("Jazyk faktur", selection: $viewModel.language) {
                    ForEach(PartnerFormViewModel.languages, id: \.code) { language in
                        Text(language.title).tag(language.code)
                    }
                }
                TextField("Splatnost (dny)", text: $viewModel.invoiceDue)
                    .focused($focused, equals: .due)
                    .keyboardType(.numberPad)
            } header: {
                Text("Fakturace")
            } footer: {
                if !viewModel.isDueValid {
                    Text("Splatnost zadejte jako celé číslo dnů.").foregroundStyle(.red)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if viewModel.isLoadingReferenceData, viewModel.countries.isEmpty {
                ProgressView()
            }
        }
    }

    private func save() {
        focused = nil
        Task {
            if let partner = await viewModel.save() {
                onSaved(partner)
                dismiss()
            }
        }
    }
}

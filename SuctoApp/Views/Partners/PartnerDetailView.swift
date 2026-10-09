//
//  PartnerDetailView.swift
//  SuctoApp
//

import Charts
import SwiftUI

/// Detail partnera: údaje, kontakty (klepnutím volat / psát), obrat po měsících, úprava a smazání.
struct PartnerDetailView: View {
    @StateObject private var viewModel: PartnerDetailViewModel
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var permissions: PermissionsStore
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var confirmDelete = false

    init(companyId: Int, partnerId: Int, session: SessionManager) {
        _viewModel = StateObject(wrappedValue: PartnerDetailViewModel(companyId: companyId, partnerId: partnerId, session: session))
    }

    var body: some View {
        Group {
            if let partner = viewModel.partner {
                content(partner)
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) { Task { await viewModel.load() } }
            } else {
                LoadingStateView(message: "Načítám partnera…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle("Partner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.partner != nil, canEdit || canDelete {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if canEdit {
                            Button { showEdit = true } label: { Label("Upravit", systemImage: "pencil") }
                        }
                        if canDelete {
                            Button(role: .destructive) { confirmDelete = true } label: { Label("Smazat", systemImage: "trash") }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Akce partnera")
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $showEdit) {
            if let partner = viewModel.partner {
                PartnerFormView(companyId: viewModel.companyId, mode: .edit(partner), session: session) { updated in
                    viewModel.didSave(updated)
                }
            }
        }
        .confirmationDialog("Smazat partnera?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Smazat", role: .destructive) {
                Task { if await viewModel.delete() { dismiss() } }
            }
            Button("Zrušit", role: .cancel) {}
        } message: {
            Text("Partnera nelze po smazání obnovit. Pokud má doklady, server smazání může odmítnout.")
        }
        .alert("Akce se nezdařila", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } },
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .disabled(viewModel.isDeleting)
    }

    private var canEdit: Bool { permissions.can(.update, .partner, companyId: viewModel.companyId) }
    private var canDelete: Bool { permissions.can(.destroy, .partner, companyId: viewModel.companyId) }

    private func content(_ partner: PartnerRecord) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                hero(partner).appear(delay: 0.02)

                DetailCard(title: "Údaje", systemImage: "building.2") {
                    DetailRow(label: "IČ", value: partner.ic, hideWhenEmpty: true)
                    DetailRow(label: "DIČ", value: partner.dic, hideWhenEmpty: true)
                    DetailRow(label: "Plátce DPH", value: partner.isTaxable ? "Ano" : "Ne")
                    if let address = partner.address?.oneLine {
                        DetailRow(label: "Adresa", value: address)
                    }
                    DetailRow(label: "Země", value: partner.address?.countryName, hideWhenEmpty: true)
                }
                .appear(delay: 0.08)

                if partner.email != nil || partner.phone != nil || partner.web != nil {
                    DetailCard(title: "Kontakt", systemImage: "person.crop.circle") {
                        ContactRow(label: "E-mail", value: partner.email, scheme: "mailto:", systemImage: "envelope")
                        ContactRow(label: "Telefon", value: partner.phone, scheme: "tel:", systemImage: "phone")
                        ContactRow(label: "Web", value: partner.web, scheme: nil, systemImage: "safari")
                    }
                    .appear(delay: 0.12)
                }

                DetailCard(title: "Fakturace", systemImage: "doc.text") {
                    DetailRow(label: "Měna", value: partner.currency?.isoCode, hideWhenEmpty: true)
                    DetailRow(label: "Jazyk faktur", value: language(partner.invoicingLanguage), hideWhenEmpty: true)
                    DetailRow(label: "Splatnost", value: partner.invoiceDueDays.map { "\($0) dní" }, hideWhenEmpty: true)
                }
                .appear(delay: 0.16)

                if !viewModel.years.isEmpty {
                    PartnerTurnoverCard(viewModel: viewModel)
                        .appear(delay: 0.2)
                }
            }
            .padding(Theme.Spacing.l)
            .fitsScreenWidth()
        }
        .refreshable { await viewModel.load() }
    }

    private func hero(_ partner: PartnerRecord) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(partner.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            if partner.isCustomer || partner.isSupplier {
                Text([partner.isCustomer ? "Odběratel" : nil, partner.isSupplier ? "Dodavatel" : nil].compactMap(\.self).joined(separator: " · "))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            if let ic = partner.ic, !ic.isEmpty {
                Text("IČ \(ic)")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.brand.opacity(0.3), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
    }

    private func language(_ code: String?) -> String? {
        guard let code else { return nil }
        return PartnerFormViewModel.languages.first { $0.code == code }?.title ?? code
    }
}

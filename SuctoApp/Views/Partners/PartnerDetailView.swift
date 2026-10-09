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

/// Řádek kontaktu; klepnutím otevře poštu / telefon / prohlížeč.
private struct ContactRow: View {
    let label: String
    let value: String?
    /// `nil` = web (adresa se doplní o `https://`, pokud chybí).
    let scheme: String?
    let systemImage: String

    var body: some View {
        if let value, !value.isEmpty, let url = url(for: value) {
            Link(destination: url) {
                HStack {
                    Label(label, systemImage: systemImage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                        .multilineTextAlignment(.trailing)
                }
                .contentShape(Rectangle())
            }
            .accessibilityHint("Otevře \(label.lowercased())")
        }
    }

    private func url(for value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if let scheme {
            return URL(string: scheme + trimmed.replacingOccurrences(of: " ", with: ""))
        }
        return URL(string: trimmed.contains("://") ? trimmed : "https://\(trimmed)")
    }
}

/// Obrat s partnerem po měsících, výběr roku. Faktury se v grafu porovnávají vedle sebe (vydané × přijaté);
/// pokladní doklady jsou hotovostní platby, proto se do sloupců nesčítají a jsou jen v součtech pod grafem.
private struct PartnerTurnoverCard: View {
    @ObservedObject var viewModel: PartnerDetailViewModel

    private static let months = ["led", "úno", "bře", "dub", "kvě", "čvn", "čvc", "srp", "zář", "říj", "lis", "pro"]
    private let issuedColor = Color(hex: "#2FAE5D")
    private let receivedColor = Color(hex: "#F28C28")

    private var visibleSeries: [PartnerSeries] { viewModel.series.filter { $0.total != 0 } }

    private func isInvoice(_ series: PartnerSeries) -> Bool {
        series.name.range(of: "faktur", options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    /// Do grafu jen faktury; když žádné nejsou, aspoň to, co v roce je.
    private var chartSeries: [PartnerSeries] {
        let invoices = visibleSeries.filter(isInvoice)
        return invoices.isEmpty ? visibleSeries : invoices
    }

    /// Vydané / příjmové = zelená, přijaté / výdajové = oranžová.
    private func color(for name: String) -> Color {
        let folded = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return folded.contains("vydane") || folded.contains("prijmove") ? issuedColor : receivedColor
    }

    var body: some View {
        DetailCard(title: "Obrat po měsících", systemImage: "chart.bar.xaxis") {
            yearPicker

            if visibleSeries.isEmpty {
                Text("V roce \(String(viewModel.year ?? 0)) zatím nejsou žádné faktury ani doklady.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(chartSeries) { series in
                        ForEach(Array(series.data.prefix(12).enumerated()), id: \.offset) { index, value in
                            BarMark(x: .value("Měsíc", Self.months[index]), y: .value("Částka", value))
                                .foregroundStyle(by: .value("Typ", series.name))
                                .position(by: .value("Typ", series.name))
                                .cornerRadius(3)
                        }
                    }
                }
                .chartForegroundStyleScale(domain: chartSeries.map(\.name), range: chartSeries.map { color(for: $0.name) })
                .chartLegend(position: .bottom, alignment: .leading)
                .frame(height: 200)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Graf obratu po měsících")
                .accessibilityValue(summary)

                ForEach(visibleSeries) { series in
                    HStack {
                        Circle().fill(color(for: series.name)).frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text(series.name).font(.subheadline)
                        Spacer()
                        Text(FormatterHelper.formatWhole(series.total, currency: nil))
                            .moneyStyle(.subheadline)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private var yearPicker: some View {
        let selection = Binding(
            get: { viewModel.year ?? viewModel.years.last ?? 0 },
            set: { year in Task { await viewModel.select(year: year) } },
        )
        if viewModel.years.count > 4 {
            Picker("Rok", selection: selection) { yearOptions }
                .pickerStyle(.menu)
        } else if viewModel.years.count > 1 {
            Picker("Rok", selection: selection) { yearOptions }
                .pickerStyle(.segmented)
        }
    }

    private var yearOptions: some View {
        ForEach(viewModel.years, id: \.self) { year in
            Text(String(year)).tag(year)
        }
    }

    private var summary: String {
        visibleSeries
            .map { "\($0.name): \(FormatterHelper.formatWhole($0.total, currency: nil))" }
            .joined(separator: ", ")
    }
}

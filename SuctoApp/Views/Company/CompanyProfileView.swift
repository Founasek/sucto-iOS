//
//  CompanyProfileView.swift
//  SuctoApp
//

import SwiftUI

/// Záložka Firma: údaje o vybrané firmě, její bankovní účty a přepnutí na jinou firmu.
struct CompanyProfileView: View {
    @StateObject private var viewModel: CompanyProfileViewModel
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var accountsVM: AccountsViewModel
    let onSwitchCompany: () -> Void

    init(companyId: Int, session: SessionManager, onSwitchCompany: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: CompanyProfileViewModel(companyId: companyId, session: session))
        self.onSwitchCompany = onSwitchCompany
    }

    private var company: Company? { session.selectedCompany }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                header
                if let error = viewModel.errorMessage, viewModel.detail == nil {
                    ErrorStateView(message: error) { Task { await viewModel.load() } }
                } else {
                    detailsSection
                    accountsSection
                    partnersLink
                }
                Button(action: onSwitchCompany) {
                    Label("Přepnout firmu", systemImage: "arrow.left.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Text("Firmu přepnete také dvojitým klepnutím na záložku Firma.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.l)
            .fitsScreenWidth()
        }
        .background(Theme.background)
        .refreshable {
            async let accounts: Void = accountsVM.fetchAccounts()
            await viewModel.load()
            await accounts
        }
        .task { await viewModel.load() }
        .task { await accountsVM.fetchAccounts() }
    }

    // MARK: - Hlavička

    private var header: some View {
        VStack(spacing: Theme.Spacing.m) {
            CompanyLogo(company: company, size: 84)
            Text(viewModel.detail?.name ?? company?.name ?? "")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            if company?.isTaxable == true {
                Text("Plátce DPH")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.brand.opacity(0.18), in: Capsule())
                    .foregroundStyle(Theme.tint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.s)
    }

    // MARK: - Karty

    /// Nadpis sekce nad kartou – stejný pro všechny sekce stránky.
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .tracking(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.xs)
            .accessibilityAddTraits(.isHeader)
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            sectionHeader("Údaje o firmě")
            detailsCard
        }
    }

    private var detailsCard: some View {
        DetailCard(title: nil) {
            CopyableRow(label: "IČO", value: viewModel.detail?.ic ?? company?.ic)
            CopyableRow(label: "E-mail", value: viewModel.detail?.email ?? company?.email)
            let lines = viewModel.detail?.addressLines ?? []
            if !lines.isEmpty {
                DetailRow(label: "Adresa", value: lines.joined(separator: "\n"))
            }
            DetailRow(label: "Plátce DPH", value: (viewModel.detail?.isTaxable ?? company?.isTaxable) == true ? "Ano" : "Ne")
        }
    }

    /// Odkaz na seznam partnerů (odběratelé a dodavatelé).
    private var partnersLink: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            sectionHeader("Partneři")
            partnersCard
        }
    }

    private var partnersCard: some View {
        NavigationLink(value: AppRoute.partners(companyId: viewModel.companyId)) {
            HStack(spacing: Theme.Spacing.l) {
                Image(systemName: "person.2")
                    .font(.title3)
                    .foregroundStyle(Theme.tint)
                    .frame(width: 48, height: 48)
                    .background(Theme.brand.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Odběratelé a dodavatelé").font(.headline)
                    Text("Seznam, vyhledávání a přidání partnera")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .card()
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(PressableCardStyle())
    }

    /// Bankovní a pokladní účty firmy; klepnutí otevře detail účtu.
    @ViewBuilder
    private var accountsSection: some View {
        if !accountsVM.accounts.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                sectionHeader("Účty")
                ForEach(Array(accountsVM.accounts.enumerated()), id: \.offset) { _, account in
                    NavigationLink(value: account) {
                        AccountRow(account: account)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }
}

/// Logo firmy, nebo ikona budovy na značkovém pozadí.
struct CompanyLogo: View {
    let company: Company?
    var size: CGFloat = 52

    var body: some View {
        Group {
            if let logo = company?.logo, let url = URL(string: logo) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit().padding(size * 0.12)
                } placeholder: {
                    placeholder
                }
                .background(Color.white)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.27, style: .continuous).strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Theme.brandGradient
            Image(systemName: "building.2.fill")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.white)
        }
    }
}

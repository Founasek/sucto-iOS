//
//  CompanyProfileView.swift
//  SuctoApp
//

import SwiftUI

/// Záložka Firma: údaje o vybrané firmě, její bankovní účty a přepnutí na jinou firmu.
struct CompanyProfileView: View {
    @StateObject private var viewModel: CompanyProfileViewModel
    @EnvironmentObject private var session: SessionManager
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
                    detailsCard
                    if !viewModel.bankAccounts.isEmpty { bankAccountsCard }
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
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
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
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.s)
    }

    // MARK: - Karty

    private var detailsCard: some View {
        DetailCard(title: "Údaje o firmě", systemImage: "building.2") {
            CopyableRow(label: "IČO", value: viewModel.detail?.ic ?? company?.ic)
            CopyableRow(label: "E-mail", value: viewModel.detail?.email ?? company?.email)
            let lines = viewModel.detail?.addressLines ?? []
            if !lines.isEmpty {
                DetailRow(label: "Adresa", value: lines.joined(separator: "\n"))
            }
            DetailRow(label: "Plátce DPH", value: (viewModel.detail?.isTaxable ?? company?.isTaxable) == true ? "Ano" : "Ne")
        }
    }

    private var bankAccountsCard: some View {
        DetailCard(title: "Bankovní účty", systemImage: "building.columns") {
            ForEach(Array(viewModel.bankAccounts.enumerated()), id: \.offset) { index, account in
                if index > 0 { Divider() }
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(account.name).font(.subheadline.weight(.semibold))
                    if let bank = account.bankAccount {
                        if let number = bank.account {
                            CopyableRow(label: "Číslo účtu", value: "\(number)\(bank.bankCode.map { "/\($0)" } ?? "")")
                        }
                        CopyableRow(label: "IBAN", value: bank.iban)
                        CopyableRow(label: "SWIFT", value: bank.swift)
                    }
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

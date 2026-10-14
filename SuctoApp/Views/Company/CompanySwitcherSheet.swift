//
//  CompanySwitcherSheet.swift
//  SuctoApp
//

import SwiftUI

/// Rychlé přepnutí firmy: seznam firem účtu, aktuální je označená.
struct CompanySwitcherSheet: View {
    @StateObject private var viewModel: CompaniesViewModel
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var navManager: NavigationManager
    @Environment(\.dismiss) private var dismiss

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: CompaniesViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.companies) { company in
                    Button {
                        switchTo(company)
                    } label: {
                        row(company)
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage, viewModel.companies.isEmpty {
                    ErrorStateView(message: error) { Task { await viewModel.fetchCompanies() } }
                }
            }
            .navigationTitle("Přepnout firmu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zavřít") { dismiss() }
                }
            }
            .task { await viewModel.fetchCompanies() }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ company: Company) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            CompanyLogo(company: company, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(company.name).font(.headline)
                Text("IČ \(company.ic)").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if company.id == session.selectedCompany?.id {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(company.id == session.selectedCompany?.id ? .isSelected : [])
    }

    private func switchTo(_ company: Company) {
        if company.id != session.selectedCompany?.id {
            viewModel.selectCompany(company)
            navManager.switchCompany(to: company.id)
        }
        dismiss()
    }
}

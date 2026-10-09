//
//  CompaniesView.swift
//  SuctoApp
//
//  Created by Jan Founě on 14.09.2025.
//

import SwiftUI

struct CompaniesView: View {
    @StateObject var viewModel: CompaniesViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingStateView(message: "Načítám firmy…")
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) {
                    Task { await viewModel.fetchCompanies() }
                }
            } else if viewModel.companies.isEmpty {
                ScrollView {
                    EmptyStateView(
                        systemImage: "building.2",
                        message: "K tomuto účtu nejsou přiřazené žádné firmy.",
                    )
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.m) {
                        ForEach(Array(viewModel.companies.enumerated()), id: \.element.id) { index, company in
                            Button {
                                viewModel.selectCompany(company)
                                navManager.goToDashboard(companyId: company.id)
                            } label: {
                                CompanyCard(company: company)
                            }
                            .buttonStyle(PressableCardStyle())
                            .staggeredAppear(index: index)
                        }
                    }
                    .padding(Theme.Spacing.l)
                    .fitsScreenWidth()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offlineBanner()
        .background(Theme.background)
        .navigationTitle("Vaše firmy")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        navManager.showSettings()
                    } label: {
                        Label("Nastavení", systemImage: "gearshape")
                    }

                    Button(role: .destructive) {
                        session.logout()
                        navManager.reset()
                    } label: {
                        Label("Odhlásit se", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Nastavení")
            }
        }
        .task {
            await viewModel.fetchCompanies()
        }
        .refreshable {
            await viewModel.fetchCompanies()
        }
    }
}

/// Karta firmy s logem (nebo iniciálami) a IČ.
private struct CompanyCard: View {
    let company: Company

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            avatar

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(company.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                HStack(spacing: Theme.Spacing.s) {
                    Text("IČ \(company.ic)")
                    if company.isTaxable {
                        Text("Plátce DPH")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Theme.brand.opacity(0.18), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
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

    private var avatar: some View {
        Group {
            if let logoURL = company.logo, let url = URL(string: logoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit().padding(6)
                } placeholder: {
                    placeholder
                }
                .background(Color.white)
            } else {
                placeholder
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
    }

    private var placeholder: some View {
        ZStack {
            Theme.brandGradient
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    let mockCompanies: [Company] = [
        Company(
            id: 1,
            name: "UFOSOFT s.r.o.",
            ic: "12345678",
            isTaxable: true,
            countryId: 1,
            email: "info@ufosoft.cz",
            logo: "logo-sucto.png",
        ),
        Company(
            id: 2,
            name: "Testovací firma a.s.",
            ic: "87654321",
            isTaxable: false,
            countryId: 1,
            email: "kontakt@test.cz",
            logo: nil,
        ),
    ]

    let session = SessionManager()
    let viewModel = CompaniesViewModel(session: session)
    viewModel.companies = mockCompanies

    return CompaniesView(viewModel: viewModel)
        .environmentObject(session)
        .environmentObject(NavigationManager())
}

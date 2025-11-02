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
        VStack(spacing: 0) {
            if viewModel.isLoading {
                LoadingStateView(message: "Načítám firmy…") // 🆕
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ErrorStateView(
                    message: error,
                    retryAction: {
                        Task {
                            await viewModel.fetchCompanies()
                        }
                    }
                )
            } else if viewModel.companies.isEmpty {
                ScrollView {
                    EmptyStateView(
                        systemImage: "building.2.crop.circle",
                        message: "Žádné firmy k dispozici."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .refreshable {
                    Task {
                        await viewModel.fetchCompanies()
                    }
                }

            } else {
                List {
                    ForEach(viewModel.companies) { company in
                        Button {
                            viewModel.selectCompany(company)
                            navManager.goToDashboard(companyId: company.id)
                        } label: {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(company.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("IČ: \(company.ic)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if let logoURL = company.logo, let url = URL(string: logoURL) {
                                    AsyncImage(url: url) { img in
                                        img.resizable()
                                            .scaledToFit()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                    }
                                } else {
                                    Image(systemName: "building.2.crop.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .listStyle(.insetGrouped)
            }

            Button(action: {
                session.logout()
                navManager.reset()
            }) {
                Text("Odhlásit se")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .navigationTitle("Vaše firmy")
        .task {
            await viewModel.fetchCompanies()
        }

        .refreshable {
            await viewModel.fetchCompanies()
        }
    }
}

#Preview {
    let mockCompanies: [Company] = [
        Company(
            id: 1,
            name: "UFOSOFT s.r.o.",
            ic: "12345678",
            is_taxable: true,
            country_id: 1,
            email: "info@ufosoft.cz",
            logo: "logo-sucto.png"
        ),
        Company(
            id: 2,
            name: "Testovací firma a.s.",
            ic: "87654321",
            is_taxable: false,
            country_id: 1,
            email: "kontakt@test.cz",
            logo: nil
        ),
    ]

    let session = SessionManager()
    let viewModel = CompaniesViewModel(session: session)
    viewModel.companies = mockCompanies

    return CompaniesView(viewModel: viewModel)
        .environmentObject(session)
        .environmentObject(NavigationManager())
}

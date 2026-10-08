//
//  PartnersView.swift
//  SuctoApp
//

import SwiftUI

/// Seznam partnerů firmy: hledání na serveru, stránkování, nový partner ručně nebo z ARES.
struct PartnersView: View {
    let companyId: Int
    @StateObject private var viewModel: PartnersViewModel
    @EnvironmentObject private var session: SessionManager
    @State private var showCreate = false
    @State private var showAresPrompt = false
    @State private var aresIC = ""

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        _viewModel = StateObject(wrappedValue: PartnersViewModel(companyId: companyId, session: session))
    }

    var body: some View {
        ScrollView {
            if viewModel.partners.isEmpty {
                emptyOrLoading
            } else {
                LazyVStack(spacing: Theme.Spacing.m) {
                    ForEach(Array(viewModel.partners.enumerated()), id: \.element.id) { index, partner in
                        NavigationLink(value: AppRoute.partnerDetail(companyId: companyId, partnerId: partner.id)) {
                            PartnerRow(partner: partner)
                        }
                        .buttonStyle(PressableCardStyle())
                        .staggeredAppear(index: index)
                        .onAppear {
                            if partner.id == viewModel.partners.last?.id {
                                Task { await viewModel.fetchNextPage() }
                            }
                        }
                    }
                    if viewModel.isLoading {
                        ProgressView().padding(.vertical, Theme.Spacing.l)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.s)
            }
        }
        .contentMargins(.bottom, 24, for: .scrollContent)
        .background(Theme.background)
        .navigationTitle("Partneři")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Název, IČ, DIČ nebo adresa")
        .onChange(of: viewModel.searchText) { viewModel.searchTextChanged() }
        .refreshable { await viewModel.refresh() }
        .task { if viewModel.partners.isEmpty { await viewModel.refresh() } }
        .onReceive(NotificationCenter.default.publisher(for: PartnerEvent.notification)) { note in
            if let event = note.object as? PartnerEvent { viewModel.apply(event) }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showCreate = true } label: { Label("Nový partner", systemImage: "person.badge.plus") }
                    Button { showAresPrompt = true } label: { Label("Přidat podle IČO (ARES)", systemImage: "magnifyingglass") }
                } label: {
                    if viewModel.isCreatingFromAres {
                        ProgressView()
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .accessibilityLabel("Přidat partnera")
            }
        }
        .sheet(isPresented: $showCreate) {
            PartnerFormView(companyId: companyId, mode: .create, session: session) { partner in
                viewModel.apply(.saved(partner))
            }
        }
        .alert("Přidat podle IČO", isPresented: $showAresPrompt) {
            TextField("IČO (8 číslic)", text: $aresIC)
                .keyboardType(.numberPad)
            Button("Zrušit", role: .cancel) { aresIC = "" }
            Button("Přidat") {
                let ic = aresIC
                aresIC = ""
                Task { await viewModel.createFromAres(ic: ic) }
            }
        } message: {
            Text("Údaje o firmě se načtou z ARES.")
        }
        .alert("Partnera se nepodařilo přidat", isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } },
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .sensoryFeedback(.error, trigger: viewModel.alertMessage) { _, new in new != nil }
    }

    @ViewBuilder
    private var emptyOrLoading: some View {
        if viewModel.isLoading {
            LoadingStateView(message: "Načítám partnery…")
                .padding(.top, Theme.Spacing.xxl)
        } else if let error = viewModel.errorMessage {
            ErrorStateView(message: error) { Task { await viewModel.refresh() } }
        } else if viewModel.isSearching {
            EmptyStateView(systemImage: "magnifyingglass", message: "Žádný partner neodpovídá hledání.")
        } else {
            EmptyStateView(
                systemImage: "person.2",
                message: "Zatím tu nejsou žádní partneři.",
                actionTitle: "Přidat partnera",
                action: { showCreate = true },
            )
        }
    }
}

/// Karta partnera: iniciála, název, IČ a město, štítky Odběratel / Dodavatel.
private struct PartnerRow: View {
    let partner: PartnerRecord

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            ZStack {
                Theme.brandGradient
                Text(partner.initial)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(partner.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if partner.isCustomer || partner.isSupplier {
                    HStack(spacing: Theme.Spacing.xs) {
                        if partner.isCustomer { RoleTag(title: "Odběratel") }
                        if partner.isSupplier { RoleTag(title: "Dodavatel") }
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String? {
        let parts = [partner.ic.flatMap { $0.isEmpty ? nil : "IČ \($0)" }, partner.address?.city]
            .compactMap(\.self)
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

private struct RoleTag: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Theme.brand.opacity(0.18), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}

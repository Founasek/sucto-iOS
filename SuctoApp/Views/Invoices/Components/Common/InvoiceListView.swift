//
//  InvoiceListView.swift
//  SuctoApp
//

import SwiftUI

/// Společný seznam faktur (vydané i přijaté): karty, skeleton, prázdný a chybový stav, stránkování.
struct InvoiceListView: View {
    let invoices: [Invoice]
    let isLoading: Bool
    let errorMessage: String?
    let emptyMessage: String
    @Binding var filter: InvoiceFilter
    let isFiltering: Bool
    let clearFilters: () -> Void
    let counterparty: (Invoice) -> String?
    let refresh: () async -> Void
    let loadMore: () async -> Void
    /// Jmenný prostor pro zoom přechod do detailu (zdroj = karta faktury).
    let namespace: Namespace.ID

    var body: some View {
        ScrollView {
            if invoices.isEmpty {
                emptyOrLoading
            } else {
                LazyVStack(spacing: Theme.Spacing.m) {
                    summary

                    ForEach(Array(invoices.enumerated()), id: \.element.id) { index, invoice in
                        NavigationLink(value: invoice) {
                            InvoiceRow(invoice: invoice, counterparty: counterparty(invoice))
                        }
                        .buttonStyle(PressableCardStyle())
                        .matchedTransitionSource(id: invoice.id, in: namespace)
                        .staggeredAppear(index: index)
                        .scrollTransition(.animated(.snappy)) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.4)
                                .scaleEffect(phase.isIdentity ? 1 : 0.97)
                        }
                        .onAppear {
                            if invoice.id == invoices.last?.id {
                                Task { await loadMore() }
                            }
                        }
                    }

                    if isLoading {
                        ProgressView()
                            .padding(.vertical, Theme.Spacing.l)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.s)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { filterBar }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .background(Theme.background)
        .refreshable { await refresh() }
    }

    @ViewBuilder
    private var emptyOrLoading: some View {
        if isLoading {
            InvoiceListSkeleton()
                .padding(.top, Theme.Spacing.s)
        } else if let errorMessage {
            ErrorStateView(message: errorMessage) {
                Task { await refresh() }
            }
        } else if isFiltering {
            EmptyStateView(
                systemImage: "magnifyingglass",
                message: "Žádné faktury neodpovídají hledání nebo filtru.",
                actionTitle: "Zrušit filtry",
                action: clearFilters,
            )
        } else {
            EmptyStateView(systemImage: "doc.text.magnifyingglass", message: emptyMessage)
        }
    }

    /// Rychlé filtry – zůstávají nahoře i při rolování.
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                ForEach(InvoiceFilter.allCases) { option in
                    let isSelected = filter == option
                    Button {
                        withAnimation(Motion.standard) { filter = option }
                    } label: {
                        Label(option.title, systemImage: option.systemImage)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .background(
                                isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.surface),
                                in: Capsule(),
                            )
                            .overlay(Capsule().strokeBorder(Color.primary.opacity(isSelected ? 0 : 0.08), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)
        }
        .background(Theme.background)
        .sensoryFeedback(.selection, trigger: filter)
    }

    /// Rychlý přehled nad seznamem – ukáže se jen když je co zdůraznit.
    @ViewBuilder
    private var summary: some View {
        let overdue = invoices.filter(\.isOverdue).count
        if overdue > 0 {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(overdue == 1 ? "1 faktura po splatnosti" : "\(overdue) faktur po splatnosti")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.red)
            .padding(Theme.Spacing.m)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }
}

/// Jemné zmáčknutí karty při klepnutí, bez výchozí modré barvy odkazu.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.primary)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

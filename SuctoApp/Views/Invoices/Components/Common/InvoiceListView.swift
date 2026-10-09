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
    @Binding var advanced: InvoiceAdvancedFilter
    let isFiltering: Bool
    let clearFilters: () -> Void
    let counterparty: (Invoice) -> String?
    let refresh: () async -> Void
    let loadMore: () async -> Void
    /// Jmenný prostor pro zoom přechod do detailu (zdroj = karta faktury).
    let namespace: Namespace.ID

    @State private var showFilterSheet = false

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            list
        }
        .background(Theme.background)
        .sheet(isPresented: $showFilterSheet) {
            InvoiceFilterSheet(filter: $advanced)
        }
    }

    private var list: some View {
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
                .fitsScreenWidth()
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .refreshable { await refresh() }
    }

    @ViewBuilder
    private var emptyOrLoading: some View {
        if isLoading {
            InvoiceListSkeleton()
                .padding(.top, Theme.Spacing.xs)
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

    /// Rychlé filtry – leží mimo rolovaný seznam, takže zůstávají nahoře a nereagují na tažení ani pull-to-refresh.
    /// Když se chipy vejdou na šířku, lišta se nehýbe vůbec; na úzkém displeji se posouvá jen vodorovně.
    private var filterBar: some View {
        ViewThatFits(in: .horizontal) {
            filterChips
            ScrollView(.horizontal, showsIndicators: false) { filterChips }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .padding(.top, Theme.Spacing.xs)
        .padding(.bottom, Theme.Spacing.xs)
        .background(Theme.background)
        .sensoryFeedback(.selection, trigger: filter)
    }

    private var filterChips: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(InvoiceFilter.allCases) { option in
                let isSelected = filter == option
                Button {
                    withAnimation(Motion.standard) { filter = option }
                } label: {
                    Label(option.title, systemImage: option.systemImage)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
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

            advancedButton
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    /// Otevře podrobné filtry (stav, data, částka); odznak ukazuje, kolik jich je zapnutých.
    private var advancedButton: some View {
        let count = advanced.activeCount
        return Button {
            showFilterSheet = true
        } label: {
            Label(count > 0 ? "Filtry (\(count))" : "Filtry", systemImage: "line.3.horizontal.decrease.circle")
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(count > 0 ? Color.white : Color.primary)
                .background(
                    count > 0 ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.surface),
                    in: Capsule(),
                )
                .overlay(Capsule().strokeBorder(Color.primary.opacity(count > 0 ? 0 : 0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Otevře podrobné filtry")
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

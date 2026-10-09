//
//  OverviewView.swift
//  SuctoApp
//

import Charts
import SwiftUI

/// Přehled hospodaření: výnosy, náklady a výsledek za rok, graf po měsících.
struct OverviewView: View {
    @EnvironmentObject var viewModel: OverviewViewModel
    @EnvironmentObject var session: SessionManager
    @State private var showNotice = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l) {
                yearPicker

                if let error = viewModel.errorMessage, viewModel.sections.isEmpty {
                    ErrorStateView(message: error) {
                        Task { await viewModel.load() }
                    }
                } else if viewModel.isLoading, viewModel.sections.isEmpty {
                    OverviewLoadingView(
                        progress: viewModel.progress,
                        companyName: session.selectedCompany?.name ?? "",
                        year: viewModel.year,
                    )
                } else if viewModel.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar.xaxis",
                        message: viewModel.source == .accounting
                            ? "Za rok \(viewModel.year) nejsou v účetním deníku žádné údaje."
                            : "Za rok \(viewModel.year) nejsou vystavené ani přijaté faktury.",
                    )
                } else {
                    OverviewResultCard(
                        sections: viewModel.sections,
                        year: viewModel.year,
                        labels: labels,
                        info: viewModel.source == .invoices ? AnyView(sourceInfo) : nil,
                    )
                    if viewModel.sections.count == 1, let section = viewModel.sections.first {
                        HStack(spacing: Theme.Spacing.m) {
                            figureCard(title: labels.revenue, value: section.revenue, currency: section.currency, icon: "arrow.down.left", color: OverviewStyle.revenueColor)
                            figureCard(title: labels.cost, value: section.cost, currency: section.currency, icon: "arrow.up.right", color: OverviewStyle.costColor)
                        }
                    }
                    OverviewChartCarousel(sections: viewModel.sections, labels: labels)
                }

                if !viewModel.forecast.isEmpty {
                    OverviewForecastCard(forecast: viewModel.forecast)
                }

                if !viewModel.aging.isEmpty {
                    OverviewAgingCard(aging: viewModel.aging)
                }

                // Největší odběratelé a dodavatelé jsou doplněk – patří úplně na konec stránky.
                if !viewModel.sections.isEmpty, !viewModel.isEmpty {
                    OverviewTopPartiesCard(sections: viewModel.sections, labels: labels)
                }
            }
            .padding(Theme.Spacing.l)
            // Obsah je vždy přesně tak široký jako obrazovka – nic (dlouhý text, tabulka) ho nemůže roztáhnout do šířky.
            .containerRelativeFrame(.horizontal)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .background(Theme.background)
        .refreshable {
            async let aging: Void = viewModel.loadDueItems()
            await viewModel.load(retryAccounting: true)
            await aging
        }
        .task {
            if viewModel.sections.isEmpty { await viewModel.load() }
        }
        .task { await viewModel.loadNotice() }
        .task { await viewModel.loadDueItems() }
        .sheet(isPresented: $showNotice) {
            if let notice = viewModel.notice {
                NoticeSheet(notice: notice)
                    .onAppear { viewModel.markNoticeRead() }
            }
        }
    }

    private var labels: OverviewLabels { OverviewLabels(isAccounting: viewModel.source == .accounting) }

    /// Vysvětlení v bublině u nadpisu: přehled nevychází z účetního deníku (a případně je ve více měnách).
    private var sourceInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Přehled z faktur")
                .font(.subheadline.weight(.semibold))
            Text("Server pro váš účet nepouští účetní deník (403), proto jsou součty z vystavených a přijatých faktur bez DPH – nejde o účetní výnosy a náklady.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if viewModel.sections.count > 1 {
                Text("Faktury jsou ve více měnách (\(viewModel.sections.map(\.currency).joined(separator: ", "))). Měny se nepřepočítávají, proto má každá vlastní součty a graf.")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(Theme.Spacing.l)
        .frame(width: 300, alignment: .leading)
        .presentationCompactAdaptation(.popover)
    }

    private var yearPicker: some View {
        HStack {
            Text(labels.isAccounting ? "Hospodaření" : "Fakturace")
                .font(.title2.weight(.bold))
            Spacer()
            if viewModel.notice != nil {
                noticeButton
            }
            Menu {
                Picker("Rok", selection: $viewModel.year) {
                    ForEach(viewModel.availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            } label: {
                Label(String(viewModel.year), systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.surface, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
            }
            .accessibilityLabel("Rok \(viewModel.year)")
        }
    }

    private func figureCard(title: String, value: Double, currency: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Image(systemName: icon)
                .font(.footnote.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.15), in: Circle())
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(FormatterHelper.formatWhole(value, currency: currency))
                .moneyStyle(.headline)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText(value: value))
                .animation(Motion.gentle, value: value)
        }
        .card()
        .appear(delay: 0.08)
        .accessibilityElement(children: .combine)
    }
}

private extension OverviewView {}

private extension OverviewView {
    /// Tlačítko se zprávou ze sÚčta; červená tečka značí nepřečtenou.
    var noticeButton: some View {
        Button {
            showNotice = true
        } label: {
            Image(systemName: "megaphone")
                .font(.subheadline.weight(.semibold))
                .padding(9)
                .background(Theme.surface, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
                .overlay(alignment: .topTrailing) {
                    if viewModel.isNoticeUnread {
                        Circle().fill(.red).frame(width: 9, height: 9)
                    }
                }
        }
        .accessibilityLabel(viewModel.isNoticeUnread ? "Zpráva ze sÚčta, nepřečtená" : "Zpráva ze sÚčta")
    }
}

/// Zpráva ze sÚčta zobrazená na vyžádání.
private struct NoticeSheet: View {
    let notice: SystemNotice
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    Text(notice.title).font(.title3.weight(.semibold))
                    if let date = notice.createdAt {
                        Text(date).font(.footnote).foregroundStyle(.secondary)
                    }
                    if let description = notice.description, !description.isEmpty {
                        Text(description).font(.body)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.l)
            }
            .navigationTitle("Zpráva ze sÚčta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Zavřít") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

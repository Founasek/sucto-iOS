//
//  OverviewLoadingView.swift
//  SuctoApp
//

import SwiftUI

/// Úvodní načítací stránka přehledu: logo s točícím se obloukem, ukazatel průběhu a kroky načítání
/// s počty už načtených faktur. Ukazuje se, dokud nejsou k dispozici první údaje.
struct OverviewLoadingView: View {
    let progress: OverviewLoadProgress
    let companyName: String
    let year: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSlowHint = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            hero
            titleBlock
            progressBar
            stepsCard
            if showSlowHint {
                Text("U větších firem může načtení chvíli trvat – načítám všechny faktury za rok.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.l)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 56)
        .task {
            try? await Task.sleep(for: .seconds(6))
            withAnimation(.easeOut(duration: 0.4)) { showSlowHint = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Načítám přehled za rok \(year)")
        .accessibilityValue("\(Int(progress.fraction * 100)) procent")
    }

    // MARK: - Logo s obloukem

    private var hero: some View {
        ZStack {
            Circle()
                .fill(Theme.brand.opacity(0.22))
                .frame(width: 190, height: 190)
                .blur(radius: 36)

            Circle()
                .fill(Theme.surface)
                .frame(width: 132, height: 132)
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

            spinnerArc

            Image("logo-sucto")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Theme.brand.opacity(0.35), radius: 12, y: 6)
        }
        .frame(height: 180)
        .accessibilityHidden(true)
    }

    /// Světelný oblouk obíhající kolem loga; při „Omezit pohyb“ stojí.
    private var spinnerArc: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
            let angle = reduceMotion ? 0 : (timeline.date.timeIntervalSinceReferenceDate * 240).truncatingRemainder(dividingBy: 360)
            Circle()
                .trim(from: 0, to: 0.28)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Theme.brand.opacity(0), Theme.brand]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(100),
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round),
                )
                .frame(width: 148, height: 148)
                .rotationEffect(.degrees(angle))
                .shadow(color: Theme.brand.opacity(0.55), radius: 6)
        }
    }

    // MARK: - Nadpis a ukazatel

    private var titleBlock: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Připravuji přehled")
                .font(.title2.weight(.bold))
                .fontDesign(.rounded)
            Text("\(companyName) · \(String(year))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(Theme.brandGradient)
                    .frame(width: max(10, proxy.size.width * progress.fraction))
                    .animation(.smooth(duration: 0.6), value: progress.fraction)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, Theme.Spacing.xxl)
    }

    // MARK: - Kroky

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            step("Připojení k sÚčtu", state: progress.connecting)
            step("Vydané faktury", state: progress.issued, count: progress.issuedCount)
            step("Přijaté faktury", state: progress.received, count: progress.receivedCount)
            step("Příprava přehledu", state: progress.preparing)
        }
        .card()
        .padding(.horizontal, Theme.Spacing.l)
    }

    private func step(_ title: String, state: OverviewLoadProgress.StepState, count: Int? = nil) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            indicator(for: state)
                .frame(width: 24, height: 24)
            Text(title)
                .font(.subheadline.weight(state == .active ? .semibold : .regular))
                .foregroundStyle(state == .pending ? .secondary : .primary)
            Spacer(minLength: Theme.Spacing.s)
            if let count, state != .pending, count > 0 {
                Text("\(count)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.numericText(value: Double(count)))
                    .animation(.snappy, value: count)
            }
        }
        .animation(.snappy, value: state)
    }

    @ViewBuilder
    private func indicator(for state: OverviewLoadProgress.StepState) -> some View {
        switch state {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce, value: state)
                .transition(.scale.combined(with: .opacity))
        case .active:
            ProgressView()
                .controlSize(.small)
                .tint(Color.accentColor)
        case .pending:
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(.tertiary)
        }
    }
}

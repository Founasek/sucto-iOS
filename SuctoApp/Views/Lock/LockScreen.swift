//
//  LockScreen.swift
//  SuctoApp
//

import SwiftUI

/// Zamčená obrazovka: tmavé značkové pozadí jako na přihlášení, obří zámek v pozadí a obsah u horního okraje,
/// aby ho systémové okno Face ID (uprostřed obrazovky) nezakrývalo. V přepínači aplikací je jen logo.
struct LockScreen: View {
    @ObservedObject var lock: AppLock
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Zámek je jen dekorace v překryvu pozadí – nesmí ovlivnit velikost obsahu (jinak by ho roztáhl na 560 pt).
            AnimatedMeshBackground()
                .overlay { giantLock }
                .clipped()
            if lock.isLocked {
                lockedContent
            } else {
                logo.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    // MARK: - Pozadí

    /// Obří zámek přetékající přes spodní okraj – působí jako „stránka“, ale nepřebíjí obsah.
    private var giantLock: some View {
        Image(systemName: "lock.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 560)
            .foregroundStyle(LinearGradient(colors: [.white.opacity(0.11), .white.opacity(0.02)], startPoint: .top, endPoint: .bottom))
            .rotationEffect(.degrees(-9))
            .offset(x: 90, y: 250)
            .blur(radius: 1.5)
            .accessibilityHidden(true)
    }

    // MARK: - Obsah

    private var lockedContent: some View {
        VStack(spacing: Theme.Spacing.l) {
            logo
                .padding(.top, 96)

            Text("sÚčto je zamčené")
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(.white)
                .padding(.top, Theme.Spacing.s)

            // Střed obrazovky zůstává volný pro systémové okno Face ID; akce je dole u palce.
            Spacer(minLength: 0)

            VStack(spacing: Theme.Spacing.m) {
                if let message = lock.errorMessage {
                    Label(message, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(Color.red.opacity(0.5), in: Capsule())
                }

                // Tlačítko se během ověření skryje; po zrušení nebo neúspěchu se vrátí.
                Group {
                    if lock.isAuthenticating {
                        // Místo tlačítka zůstane prázdno (rozložení neskáče); průběh ukazuje točící se oblouk kolem loga.
                        Color.clear
                            .frame(height: 52)
                            .accessibilityElement()
                            .accessibilityLabel("Ověřuji")
                    } else {
                        Button {
                            Task { await lock.unlock() }
                        } label: {
                            Label("Odemknout", systemImage: lock.symbolName)
                        }
                        .buttonStyle(UnlockButtonStyle())
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: lock.isAuthenticating)

                Label("Data jsou chráněna zámkem aplikace", systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Logo ve skleněném kruhu s pulzujícím prstencem a odznakem zámku.
    private var logo: some View {
        ZStack {
            Circle()
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                .frame(width: 148, height: 148)
                .scaleEffect(pulse ? 1.12 : 0.96)
                .opacity(lock.isAuthenticating ? 0 : (pulse ? 0.25 : 0.9))
                .animation(.easeInOut(duration: 0.3), value: lock.isAuthenticating)
            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 128, height: 128)
                .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 0.5))

            spinnerArc

            Image("logo-sucto")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                .shadow(color: .black.opacity(0.4), radius: 16, y: 8)

            if lock.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 34, height: 34)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                    .offset(x: 44, y: 44)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Točící se světelný oblouk v „skleněném“ kruhu kolem loga – ukazuje, že běží ověření.
/// Při „Omezit pohyb“ se netočí, jen svítí.
extension LockScreen {
    var spinnerArc: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion || !lock.isAuthenticating)) { timeline in
            let angle = reduceMotion ? 0 : (timeline.date.timeIntervalSinceReferenceDate * 330).truncatingRemainder(dividingBy: 360)
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.white.opacity(0), .white]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(108),
                    ),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round),
                )
                .frame(width: 128, height: 128)
                .rotationEffect(.degrees(angle))
                .shadow(color: Color(hex: "#7DFFB0").opacity(0.7), radius: 6)
        }
        .opacity(lock.isAuthenticating ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: lock.isAuthenticating)
        .accessibilityHidden(true)
    }
}

/// Bílé tlačítko s jemnou zelenou září – na tmavém pozadí je hlavní akcí obrazovky.
struct UnlockButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white, in: Capsule())
            .shadow(color: Color(hex: "#4CD48A").opacity(0.45), radius: 18, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

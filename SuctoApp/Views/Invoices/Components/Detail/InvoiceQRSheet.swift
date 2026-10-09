//
//  InvoiceQRSheet.swift
//  SuctoApp
//

import SwiftUI

/// QR platba k faktuře: bankovní aplikace ho naskenuje a předvyplní platbu (účet, částku, VS, zprávu, splatnost).
struct InvoiceQRSheet: View {
    let invoice: Invoice
    let input: PaymentQR.Input

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var originalBrightness: CGFloat?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    qrCard

                    VStack(spacing: Theme.Spacing.xs) {
                        Text(FormatterHelper.formatPrice(String(input.amount), currency: invoice.currency?.symbol))
                            .font(.largeTitle.weight(.bold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                        Text("Faktura \(invoice.actuarialNumber)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    DetailCard(title: "Platba", systemImage: "creditcard") {
                        CopyableRow(label: "IBAN", value: input.iban)
                        CopyableRow(label: "Variabilní symbol", value: input.variableSymbol?.filter(\.isNumber))
                        DetailRow(label: "Splatnost", value: invoice.dueDateAt, hideWhenEmpty: true)
                    }

                    Text("Otevřete bankovní aplikaci a naskenujte kód – částka, účet i symbol se předvyplní.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let image {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview("QR platba – \(invoice.actuarialNumber)", image: Image(uiImage: image)),
                        ) {
                            Label("Sdílet QR kód", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(Theme.Spacing.l)
                .fitsScreenWidth()
            }
            .background(Theme.background)
            .navigationTitle("QR platba")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Hotovo") { dismiss() } }
            }
            .task {
                if let text = PaymentQR.spayd(input) { image = PaymentQR.image(for: text) }
            }
            // Jas na maximum, ať se kód dobře čte; po zavření se vrátí.
            .onAppear {
                originalBrightness = UIScreen.main.brightness
                UIScreen.main.brightness = 1
            }
            .onDisappear {
                if let originalBrightness { UIScreen.main.brightness = originalBrightness }
            }
        }
    }

    /// Kód je vždy na bílém podkladu s okrajem (tmavý režim čtení kazí).
    private var qrCard: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("QR kód platby")
            } else {
                ProgressView().frame(height: 240)
            }
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: 320)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }
}

import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCurrencyId: Int?
    let currencies: [Currency]
    
    @State private var isPresented = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Nadpis nahoře
            Text("Měna")
                .foregroundColor(.primary)
            
            // Řádek s vybranou měnou a šipkou
            Button {
                isPresented = true
            } label: {
                HStack {
                    if let selected = currencies.first(where: { $0.id == selectedCurrencyId }) {
                        Text(selected.isoCode ?? "???")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.primary)
                    } else {
                        Text("Vyberte měnu")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                List(currencies) { currency in
                    Button {
                        selectedCurrencyId = currency.id
                        isPresented = false
                    } label: {
                        Text(currency.isoCode ?? "???")
                            .font(.body)
                    }
                }
                .navigationTitle("Vyberte měnu")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Zavřít") {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}

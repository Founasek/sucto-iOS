import SwiftUI

struct PartnerPickerView: View {
    @Binding var selectedPartnerId: Int?
    let partners: [Partner]
    
    @State private var searchText = ""
    @State private var isPresented = false
    
    private var filteredPartners: [Partner] {
        if searchText.isEmpty {
            return partners
        } else {
            return partners.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                ($0.ic ?? "").contains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Button {
                isPresented = true
            } label: {
                HStack {
                    if let selected = partners.first(where: { $0.id == selectedPartnerId }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selected.name)
                                .font(.body)
                            if let ic = selected.ic {
                                Text("IČ: \(ic)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text("Vyberte odběratele")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    List(filteredPartners) { partner in
                        Button {
                            selectedPartnerId = partner.id
                            isPresented = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(partner.name)
                                    .font(.body)
                                if let ic = partner.ic {
                                    Text("IČ: \(ic)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Hledat podle názvu nebo IČ")
                    .navigationTitle("Vyberte odběratele")
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
}

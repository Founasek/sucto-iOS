import SwiftUI

struct AccountPickerView: View {
    @Binding var selectedAccountId: Int?
    let accounts: [Account]
    
    @State private var searchText = ""
    @State private var isPresented = false
    
    private var filteredAccounts: [Account] {
        if searchText.isEmpty {
            return accounts
        } else {
            return accounts.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                if let selected = accounts.first(where: { $0.id == selectedAccountId }) {
                    Text(selected.name)
                        .font(.body)
                } else {
                    Text("Vyberte bankovní účet")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                List(filteredAccounts) { account in
                    Button {
                        selectedAccountId = account.id
                        isPresented = false
                    } label: {
                        Text(account.name)
                            .font(.body)
                    }
                }
                .searchable(text: $searchText, prompt: "Hledat účet podle názvu")
                .navigationTitle("Vyberte bankovní účet")
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

//
//  PartnerPickerView.swift
//  SuctoApp
//
//  Created by Jan Founě on 28.10.2025.
//

import SwiftUI

struct PartnerPickerView: View {
    @Binding var selectedPartner: Partner?
    let partners: [Partner]

    @State private var searchText = ""
    @State private var isPresented = false

    private var filteredPartners: [Partner] {
        let result: [Partner]
        if searchText.isEmpty {
            result = partners
        } else {
            result = partners.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                ($0.ic ?? "").contains(searchText)
            }
        }
        return result.sorted { $0.name.lowercased() < $1.name.lowercased() } // řazení podle názvu
    }


    var body: some View {
        Button {
            isPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Odběratel")
                    .foregroundColor(.primary)

                HStack {
                    if let selected = selectedPartner {
                        Text(selected.name)
                            .font(.body)
                            .foregroundStyle(.accent)
                    } else {
                        Text("Vyberte odběratele")
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                List(filteredPartners) { partner in
                    Button {
                        selectedPartner = partner
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

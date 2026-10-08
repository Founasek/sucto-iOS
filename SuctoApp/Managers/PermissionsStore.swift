//
//  PermissionsStore.swift
//  SuctoApp
//

import SwiftUI

/// Oprávnění uživatele ve firmě (`GET companies/{id}/api_permissions?resource=…`).
/// Slouží jen k tomu, aby aplikace nenabízela akce, které server stejně odmítne. Server rozhoduje vždy:
/// při chybě nebo neznámém zdroji se akce nabízí dál („fail open“) a případný 403 se ukáže jako chyba.
@MainActor
final class PermissionsStore: ObservableObject {
    enum Action { case create, read, update, destroy }

    /// Názvy zdrojů z API dokumentace.
    enum Resource: String, CaseIterable {
        case actuarialsIn = "ActuarialsIn"
        case actuarialsOut = "ActuarialsOut"
        case partner = "Partner"
    }

    private struct Abilities: Decodable {
        let create: Bool
        let read: Bool
        let update: Bool
        let destroy: Bool
    }

    @Published private var abilities: [String: Abilities] = [:]
    private var loading: Set<String> = []

    private static func key(_ companyId: Int, _ resource: Resource) -> String { "\(companyId)/\(resource.rawValue)" }

    /// Načte oprávnění ke všem známým zdrojům firmy (neúspěch se ignoruje).
    func load(companyId: Int, session: SessionManager) async {
        await withTaskGroup(of: Void.self) { group in
            for resource in Resource.allCases {
                let key = Self.key(companyId, resource)
                guard abilities[key] == nil, !loading.contains(key) else { continue }
                loading.insert(key)
                group.addTask { @MainActor in
                    let endpoint = "companies/\(companyId)/api_permissions?resource=\(resource.rawValue)"
                    if let loaded: Abilities = try? await session.send(endpoint) {
                        self.abilities[key] = loaded
                    }
                    self.loading.remove(key)
                }
            }
        }
    }

    /// `true`, pokud akci smí; bez načtených údajů `true` (rozhodne server).
    func can(_ action: Action, _ resource: Resource, companyId: Int) -> Bool {
        guard let abilities = abilities[Self.key(companyId, resource)] else { return true }
        switch action {
        case .create: return abilities.create
        case .read: return abilities.read
        case .update: return abilities.update
        case .destroy: return abilities.destroy
        }
    }

    func reset() {
        abilities = [:]
    }
}

extension InvoiceDirection {
    var permissionResource: PermissionsStore.Resource {
        self == .outgoing ? .actuarialsOut : .actuarialsIn
    }
}

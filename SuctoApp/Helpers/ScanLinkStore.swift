//
//  ScanLinkStore.swift
//  SuctoApp
//

import Foundation

/// API nepropojuje vytvořenou fakturu se skenem, proto si aplikace lokálně pamatuje, ze kterých skenů
/// už faktura vznikla – aby se z jednoho dokladu omylem nevytvořila dvakrát.
enum ScanLinkStore {
    private static let key = "usedScanIds"

    static func usedIds() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    static func markUsed(_ scanId: String) {
        var ids = usedIds()
        ids.insert(scanId)
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}

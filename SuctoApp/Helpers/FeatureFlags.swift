//
//  FeatureFlags.swift
//  SuctoApp
//

/// Pevně zapisované přepínače funkcí. Změna = přepsat hodnotu a znovu sestavit aplikaci.
enum FeatureFlags {
    /// Skenování / nahrávání dokladů ke zpracování serverem. Vypnuto: u účtu bez zapnuté služby zpracování
    /// zůstávají nahrané doklady ve stavu „Nahraná“ (seznam oprávnění neobsahuje zdroj pro skeny).
    /// Kód funkce zůstává v projektu; po zapnutí se zase zobrazí tlačítko nahrání i seznam skenů.
    static let scans = false
}

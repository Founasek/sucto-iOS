# Architektura sÚčto iOS

SwiftUI aplikace (iOS 18.5+, Swift 6.2 formátování) nad REST API sÚčta (`https://www.sucto.cz/api`).
Backend nevlastníme – chování se opírá výhradně o API dokumentaci (`https://www.sucto.cz/api/docs`).

## Vrstvy

| Složka | Odpovědnost |
| --- | --- |
| `SuctoApp/App` | vstupní bod, kořenová navigace, prostředí (`SessionManager`, `AppLock`, `PermissionsStore`…) |
| `SuctoApp/Networking` | `APIService` (bezstavový HTTP klient), `APIConstants` (endpointy), `APIError` |
| `SuctoApp/Managers` | stav a služby mimo obrazovky: session/Keychain, zámek aplikace, cache odpovědí, oprávnění, upozornění |
| `SuctoApp/Models` | datové typy API + čistá logika (souhrny, výpočty, dotazy) – bez závislosti na SwiftUI, snadno testovatelné |
| `SuctoApp/ViewModels` | stav obrazovek (`@MainActor ObservableObject`), volání API přes `SessionManager` |
| `SuctoApp/Views` | SwiftUI obrazovky a komponenty, po funkcích (Dashboard, Overview, Invoices, Partners, …) |
| `SuctoApp/Export` | Pohoda XML a CSV (čisté funkce nad modely) |
| `SuctoApp/Theme`, `Helpers` | design systém, formátování, pomocné nástroje |
| `Shared` | kód sdílený aplikací a widgetem (snapshot splatností, odkazy) – jen Foundation |
| `SuctoWidget` | widget „Splatnosti“ (čte snapshot z App Group, nemá síť ani token) |
| `Config` | entitlements a Info.plist doplňky |

## Konvence

- **Velikost souborů:** jeden soubor = jedna odpovědnost, cíl do ~200 řádků. Delší typy se dělí na `Typ+Téma.swift`
  (rozšíření) – členy sdílené mezi soubory jsou `internal`, ostatní `private`.
- **Čistá logika patří do `Models`/`Export`/`Shared`** (např. `InvoiceQuery`, `InvoiceLineMath`, `AgingSummary`,
  `ForecastSummary`, `PaymentQR`, `ReminderSettings`) – žádný `SwiftUI`, žádná síť, žádný čas „zadrátovaný“
  (funkce berou `now:`), takže jdou testovat bez simulátoru.
- **Síť:** jen přes `SessionManager.send/upload/download` (doplní token, odhlásí při 401, GET odpovědi cachuje
  pro offline režim). Tolerantní dekódování (`lossyString`, `LossyText`) všude, kde dokumentace tvar nezaručuje.
- **Bezpečnost:** token v Keychainu, uložené heslo (Face ID přihlášení) v Keychainu jen na zařízení, logování
  jen v DEBUG a nikdy ne tokeny, hesla ani těla požadavků. Přihlašovací údaje pro vývoj jdou ze schématu
  (`SUCTO_EMAIL`, `SUCTO_PASSWORD`), schémata se nesdílejí.
- **Feature flagy:** `FeatureFlags` (skenování je vypnuté, dokud sÚčto nepotvrdí zpracování skenů).
- **Oprávnění:** `PermissionsStore` jen skrývá akce, které by server odmítl; rozhoduje vždy server (fail open).

## Testování

Zatím bez testovacího targetu. Čistá logika výše je k tomu připravená; doporučené první testy: `InvoiceQuery`,
`InvoiceLineMath`, `PaymentQR` (SPAYD, IBAN), `AgingSummary`, `ForecastSummary`, `DueSummary`,
`InvoiceCSVExporter`, `PohodaExporter` (proti XSD), `ReminderSettings.render`, `PartnerRequest`.

## Známé kompromisy a další kroky

- Stránkování je ve více view modelech podobné (`PagedInvoicesViewModel`, `CashVouchersViewModel`, `ScansViewModel`) –
  kandidát na obecný `Paginator`.
- Singletony `APIService.shared`, `ResponseCache.shared`, `DueNotifier.shared` ztěžují izolované testy –
  při přidání testů zavést protokoly a vstřikování.
- `UserDefaults` se používá napřímo v 8 souborech (klíče jsou lokální konstanty); při růstu sjednotit do typované vrstvy.

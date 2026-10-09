//
//  PagedInvoicesViewModel+Lines.swift
//  SuctoApp
//

import Foundation

/// Přidání, úprava a smazání řádků (položek) existující faktury.
extension PagedInvoicesViewModel {
    /// Endpoint řádků faktury (`.../lines`).
    func linesEndpoint(invoiceId: Int) -> String {
        "\(resourcePath)/\(invoiceId)/lines"
    }

    /// Přidá (`lineId == nil`) nebo upraví řádek faktury. Vrací text chyby, nebo `nil` při úspěchu.
    func saveLine(invoiceId: Int, lineId: Int?, request: InvoiceLineRequest) async -> String? {
        do {
            let body = try JSONEncoder().encode(request)
            let base = linesEndpoint(invoiceId: invoiceId)
            let _: InvoiceItem = try await session.send(
                lineId.map { "\(base)/\($0)" } ?? base,
                method: lineId == nil ? .POST : .PATCH,
                body: body,
            )
            return nil
        } catch is CancellationError {
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func deleteLine(invoiceId: Int, lineId: Int) async -> String? {
        do {
            let _: EmptyResponse = try await session.send(
                "\(linesEndpoint(invoiceId: invoiceId))/\(lineId)",
                method: .DELETE,
            )
            return nil
        } catch is CancellationError {
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

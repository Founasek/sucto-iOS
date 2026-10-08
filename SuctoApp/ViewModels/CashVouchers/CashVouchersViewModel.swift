//
//  CashVouchersViewModel.swift
//  SuctoApp
//

import SwiftUI

@MainActor
final class CashVouchersViewModel: ObservableObject {
    @Published private(set) var vouchers: [CashVoucher] = []
    @Published var direction: CashDirection = .income {
        didSet { if direction != oldValue { vouchers = []; Task { await refresh() } } }
    }

    @Published var searchText = ""
    @Published private(set) var isLoading = false
    @Published private(set) var hasMorePages = true
    @Published private(set) var errorMessage: String?

    let companyId: Int
    private let session: SessionManager
    private var currentPage = 1
    private var generation = 0
    private var searchTask: Task<Void, Never>?

    init(companyId: Int, session: SessionManager) {
        self.companyId = companyId
        self.session = session
    }

    var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    func searchTextChanged() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    func refresh() async {
        generation += 1
        currentPage = 1
        hasMorePages = true
        isLoading = false
        await fetchNextPage()
    }

    func fetchNextPage() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        let myGeneration = generation
        defer { if myGeneration == generation { isLoading = false } }

        let page = currentPage
        do {
            let result: [CashVoucher] = try await session.send(
                direction.list(companyId: companyId, query: searchText, page: page),
            )
            guard myGeneration == generation else { return }
            currentPage = page + 1
            hasMorePages = !result.isEmpty
            if page == 1 {
                vouchers = result
            } else {
                let known = Set(vouchers.map(\.id))
                vouchers += result.filter { !known.contains($0.id) }
            }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard myGeneration == generation else { return }
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class CashVoucherDetailViewModel: ObservableObject {
    @Published private(set) var voucher: CashVoucher?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false
    @Published var confirmation: String?
    @Published var alertMessage: String?

    let companyId: Int
    let direction: CashDirection
    let voucherId: Int
    private let session: SessionManager

    init(companyId: Int, direction: CashDirection, voucherId: Int, session: SessionManager) {
        self.companyId = companyId
        self.direction = direction
        self.voucherId = voucherId
        self.session = session
    }

    func load() async {
        isLoading = voucher == nil
        defer { isLoading = false }
        do {
            voucher = try await session.send(direction.detail(companyId: companyId, voucherId: voucherId))
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Pošle doklad na zadaný e-mail. Vrací text chyby, nebo `nil` při úspěchu.
    func sendToEmail(_ email: String, comment: String) async -> String? {
        struct Body: Encodable {
            let email: String
            let comment: String?
        }
        do {
            let body = try JSONEncoder().encode(Body(email: email, comment: comment.isEmpty ? nil : comment))
            let _: EmptyResponse = try await session.send(
                direction.sendToEmail(companyId: companyId, voucherId: voucherId),
                method: .PATCH,
                body: body,
            )
            confirmation = "Doklad odeslán na \(email)."
            return nil
        } catch is CancellationError {
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    /// Pošle doklad partnerovi (na jeho e-mail v adresáři).
    func sendToPartner() async {
        struct Body: Encodable { let comment: String? }
        do {
            let body = try JSONEncoder().encode(Body(comment: nil))
            let _: EmptyResponse = try await session.send(
                direction.sendToPartner(companyId: companyId, voucherId: voucherId),
                method: .PATCH,
                body: body,
            )
            confirmation = "Doklad odeslán partnerovi."
        } catch is CancellationError {
            return
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

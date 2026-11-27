//
//  TipJar.swift
//  Sinced2
//
//  Voluntary tips through In-App Purchase. Each tier is a consumable, so
//  people can tip more than once. Apple shows each price in the buyer's
//  local currency and handles payment, tax and refunds.
//
//  Product IDs must match the consumables created in App Store Connect
//  (and Sinced.storekit for local testing).
//

import Combine
import StoreKit
import SwiftUI

@MainActor
final class TipJar: ObservableObject {
    static let shared = TipJar()

    struct Tier: Identifiable {
        let id: String
        let name: String
        let symbol: String
        let tint: Color
    }

    /// Smallest to largest; the order they're shown in
    static let tiers: [Tier] = [
        Tier(id: "com.kolteaditya.Sinced2.tip.small", name: "Coffee", symbol: "cup.and.saucer.fill", tint: Color(hex: "C47F4A")),
        Tier(id: "com.kolteaditya.Sinced2.tip.medium", name: "Lunch", symbol: "takeoutbag.and.cup.and.straw.fill", tint: Color(hex: "D9A23B")),
        Tier(id: "com.kolteaditya.Sinced2.tip.large", name: "Dinner", symbol: "fork.knife", tint: Color.primaryGreen)
    ]

    enum LoadState { case loading, loaded, unavailable }

    @Published private(set) var products: [String: Product] = [:]
    @Published private(set) var loadState: LoadState = .loading
    /// The tier being paid for right now, if any
    @Published private(set) var purchasing: String?
    @Published private(set) var tipCount: Int
    /// Set when a tip goes through while the tip jar is on screen; shows the thank-you sheet
    @Published var thanks: Thanks?

    struct Thanks: Identifiable {
        enum Source { case settings, prompt }
        let id = UUID()
        let tier: Tier
        let source: Source
        /// Which tip this is for this person: 1 for their first
        let count: Int
    }

    private static let tipCountKey = "tipJar.tipCount"
    private var updatesTask: Task<Void, Never>?

    private init() {
        tipCount = UserDefaults.standard.integer(forKey: Self.tipCountKey)
    }

    var hasTipped: Bool { tipCount > 0 }

    /// Call once at launch: finishes purchases that complete outside the
    /// purchase sheet (Ask to Buy, interrupted payments, other devices)
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await loadProducts() }
    }

    func loadProducts() async {
        if loadState == .loaded, !products.isEmpty { return }
        loadState = .loading
        do {
            let fetched = try await Product.products(for: Self.tiers.map(\.id))
            products = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
            loadState = fetched.isEmpty ? .unavailable : .loaded
        } catch {
            loadState = .unavailable
        }
    }

    func tip(_ tier: Tier, from source: Thanks.Source = .settings) async {
        guard purchasing == nil, let product = products[tier.id] else { return }
        purchasing = tier.id
        defer { purchasing = nil }

        do {
            switch try await product.purchase() {
            case .success(let result):
                if await handle(result, toast: false) {
                    thanks = Thanks(tier: tier, source: source, count: tipCount)
                }
            case .pending:
                // Ask to Buy or a payment that needs approval; Transaction.updates picks it up later
                ToastManager.shared.show("Waiting for approval", subtitle: "Your tip goes through once it's approved.", icon: "hourglass")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            ToastManager.shared.show("Couldn't send the tip", subtitle: "Nothing was charged. Try again in a bit.", kind: .error)
        }
    }

    /// Counts and finishes a tip. Returns whether it was a new, valid tip.
    /// Tips that arrive later (Ask to Buy) get a toast, since the person may be anywhere in the app.
    @discardableResult
    private func handle(_ result: VerificationResult<StoreKit.Transaction>, toast: Bool = true) async -> Bool {
        guard case .verified(let transaction) = result else { return false }
        defer { Task { await transaction.finish() } }
        // A refunded tip is just finished; nothing to take back in the app
        guard transaction.revocationDate == nil else { return false }
        tipCount += 1
        UserDefaults.standard.set(tipCount, forKey: Self.tipCountKey)
        if toast {
            ToastManager.shared.show("Thank you for the tip!", subtitle: "It keeps Sinced going.", icon: "heart.fill", kind: .success)
        }
        return true
    }
}

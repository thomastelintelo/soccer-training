// PlusSubscriptionManager.swift
// Manages the Futbol Trainnier Plus monthly subscription.

import Foundation
import Observation
import StoreKit

@Observable
@MainActor
final class PlusSubscriptionManager {
    static let productID = "com.thomastelintelo.soccertraining.plus.monthly"

    private(set) var product: Product?
    private(set) var isPurchasing = false
    private(set) var statusMessage = "Loading Plus subscription…"

    var monthlyPriceText: String {
        product.map { "\($0.displayPrice)/month" } ?? "$9.99/month"
    }

    func prepare() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
            statusMessage = product == nil
                ? "Plus must be configured in App Store Connect."
                : "Unlock all Plus benefits for \(monthlyPriceText)."
        } catch {
            statusMessage = "Plus pricing is unavailable right now."
        }

        await refreshEntitlement()
    }

    func purchase() async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                UserDefaults.standard.set(true, forKey: "isProMember")
                statusMessage = "Plus is active."
                await transaction.finish()
            case .pending:
                statusMessage = "The purchase is waiting for approval."
            case .userCancelled:
                statusMessage = "The purchase was cancelled."
            @unknown default:
                statusMessage = "The purchase did not finish."
            }
        } catch {
            statusMessage = "The purchase could not be completed."
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlement()
        } catch {
            statusMessage = "Purchases could not be restored."
        }
    }

    func refreshEntitlement() async {
        var hasActivePlus = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productID == Self.productID else { continue }
            guard transaction.revocationDate == nil else { continue }

            if transaction.expirationDate.map({ $0 > Date() }) ?? true {
                hasActivePlus = true
            }
        }

        UserDefaults.standard.set(hasActivePlus, forKey: "isProMember")
        if hasActivePlus {
            statusMessage = "Plus is active."
        }
    }

    private func checkVerified<T>(
        _ result: VerificationResult<T>
    ) throws -> T {
        switch result {
        case .verified(let value):
            value
        case .unverified:
            throw StoreError.failedVerification
        }
    }

    private enum StoreError: Error {
        case failedVerification
    }
}

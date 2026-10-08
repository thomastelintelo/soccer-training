import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class PlusPurchaseStore {
    static let productID = "com.soccertraining.futboleliteplus.yearly"

    private(set) var product: Product?
    private(set) var isUnlocked = false
    private(set) var isLoading = false
    var errorMessage: String?

    var displayPrice: String {
        product?.displayPrice ?? "$9.99"
    }

    func prepare() async {
        guard product == nil else {
            await refreshEntitlement()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            product = try await Product.products(for: [Self.productID]).first
            await refreshEntitlement()
            if product == nil {
                errorMessage = "Futbol Elite Plus is not available from the App Store yet."
            }
        } catch {
            errorMessage = "The App Store could not load Futbol Elite Plus. Please try again."
        }
    }

    func purchase() async {
        if product == nil {
            await prepare()
        }
        guard let product else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                isUnlocked = true
                await transaction.finish()
            case .pending:
                errorMessage = "The purchase is waiting for approval."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "The purchase could not be completed."
            }
        } catch {
            errorMessage = "The purchase could not be completed. Please try again."
        }
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isUnlocked {
                errorMessage = "No Futbol Elite Plus purchase was found for this Apple Account."
            }
        } catch {
            errorMessage = "Purchases could not be restored. Please try again."
        }
    }

    func refreshEntitlement() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                hasEntitlement = true
                break
            }
        }
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debugPlusUnlocked") {
            hasEntitlement = true
        }
        #endif
        isUnlocked = hasEntitlement
    }

    #if DEBUG
    func unlockForTesting() {
        UserDefaults.standard.set(true, forKey: "debugPlusUnlocked")
        errorMessage = nil
        isUnlocked = true
    }
    #endif

    func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.productID else { continue }

            if transaction.revocationDate == nil {
                isUnlocked = true
            } else {
                await refreshEntitlement()
            }
            await transaction.finish()
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): value
        case .unverified: throw PlusPurchaseError.failedVerification
        }
    }
}

private enum PlusPurchaseError: Error {
    case failedVerification
}

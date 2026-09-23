// RewardedAdManager.swift
// Loads and presents the rewarded ad used to earn bonus points in the Store.

import Foundation
import Observation

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@Observable
@MainActor
final class RewardedAdManager: NSObject {
    private(set) var isReady = false
    private(set) var isLoading = false
    private(set) var statusMessage = "Preparing rewarded ad…"

    #if canImport(GoogleMobileAds)
    private var rewardedAd: RewardedAd?
    private let testAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    #endif

    func prepare() async {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start()
        await loadAd()
        #else
        statusMessage = "Add the Google Mobile Ads package in Xcode to enable rewarded ads."
        #endif
    }

    func showAd(onReward: @escaping @MainActor () -> Void) {
        #if canImport(GoogleMobileAds)
        guard let ad = rewardedAd, isReady else {
            statusMessage = "The ad is still loading."
            return
        }

        rewardedAd = nil
        isReady = false
        statusMessage = "Watch the full ad to earn your points."
        ad.present(from: nil) {
            onReward()
            self.statusMessage = "Reward earned! 50 points were added."
        }
        #else
        statusMessage = "Rewarded ads need the Google Mobile Ads package."
        #endif
    }

    #if canImport(GoogleMobileAds)
    private func loadAd() async {
        guard !isLoading else { return }
        isLoading = true
        statusMessage = "Loading rewarded ad…"

        do {
            let ad = try await RewardedAd.load(with: testAdUnitID, request: Request())
            rewardedAd = ad
            rewardedAd?.fullScreenContentDelegate = self
            isReady = true
            statusMessage = "Watch an ad to earn 50 points."
        } catch {
            statusMessage = "No ad is available right now. Try again later."
        }

        isLoading = false
    }
    #endif
}

#if canImport(GoogleMobileAds)
extension RewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { await loadAd() }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        statusMessage = "The ad could not be shown. Try again."
        Task { await loadAd() }
    }
}
#endif

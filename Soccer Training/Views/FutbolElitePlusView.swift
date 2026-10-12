import SwiftUI

struct FutbolElitePlusView: View {
    @Environment(PlusPurchaseStore.self) private var plusStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingPurchaseError = false

    private let features = [
        PlusFeature(icon: "figure.soccer", title: "40+ Elite Drills", detail: "Advanced finishing, passing, ball mastery, control, and match-speed challenges."),
        PlusFeature(icon: "list.bullet.clipboard.fill", title: "Premium Guided Sessions", detail: "Complete Plus sessions with warm-ups, selected drills, timers, and cool-downs."),
        PlusFeature(icon: "bolt.fill", title: "Match-Speed Training", detail: "Higher-intensity combinations that connect multiple skills in one workout."),
        PlusFeature(icon: "target", title: "Exclusive Challenges", detail: "Accuracy, weak-foot, juggling, pressure, and complete-player challenges."),
        PlusFeature(icon: "arrow.down.circle.fill", title: "Future Plus Content", detail: "New Plus drills and sessions are included while your plan is active."),
        PlusFeature(icon: "calendar", title: "One Full Year", detail: "Plus content stays unlocked for the entire subscription year."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    PlusHeroView(price: plusStore.displayPrice)

                    VStack(spacing: 12) {
                        ForEach(features) { feature in
                            PlusFeatureRow(feature: feature)
                        }
                    }

                    if plusStore.isUnlocked {
                        Label("Futbol Elite Plus is unlocked", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        Button {
                            Task {
                                await plusStore.purchase()
                                showingPurchaseError = plusStore.errorMessage != nil
                            }
                        } label: {
                            HStack {
                                if plusStore.isLoading { ProgressView().tint(.white) }
                            Text("Start Yearly Plus — \(plusStore.displayPrice)")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(plusStore.isLoading)

                        Button("Restore Purchase") {
                            Task { await plusStore.restorePurchases() }
                        }
                        .font(.subheadline.bold())
                        .disabled(plusStore.isLoading)

                        #if DEBUG
                        Button("Preview Plus for Testing") {
                            plusStore.unlockForTesting()
                            dismiss()
                        }
                        .font(.subheadline.bold())
                        .buttonStyle(.bordered)
                        #endif
                    }

                    if let errorMessage = plusStore.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Text("Payment is charged to your Apple Account. The subscription renews yearly unless canceled at least 24 hours before renewal. You can manage or cancel it in your App Store account settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(SoccerBackgroundView())
            .navigationTitle("Futbol Elite Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await plusStore.prepare() }
            .alert("Purchase Not Available", isPresented: $showingPurchaseError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(plusStore.errorMessage ?? "The App Store could not start this purchase.")
            }
        }
        .tint(Color.soccerAccent)
    }
}

private struct PlusFeature: Identifiable {
    let icon: String
    let title: String
    let detail: String
    var id: String { title }
}

private struct PlusHeroView: View {
    let price: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 54))
                .foregroundStyle(.yellow)
            Text("TRAIN LIKE AN ELITE PLAYER")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Unlock every Plus feature for \(price) per year.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [Color.soccerAccent, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }
}

private struct PlusFeatureRow: View {
    let feature: PlusFeature

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: feature.icon)
                .font(.title2.bold())
                .foregroundStyle(Color.soccerAccent)
                .frame(width: 48, height: 48)
                .background(Color.soccerAccent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title).font(.headline)
                Text(feature.detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

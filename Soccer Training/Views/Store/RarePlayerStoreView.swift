// RarePlayerStoreView.swift
// The Store tab: Plus subscription pitch, points earning/purchasing, and
// the weekly cash and points-based rare player offers.

import SwiftUI

private enum StoreCategory: String, CaseIterable, Identifiable {
    case players = "Players"
    case points = "Points"

    var id: String { rawValue }
}

struct RarePlayerStoreView: View {
    @State private var selectedCategory = StoreCategory.players
    @State private var rewardedAdManager = RewardedAdManager()
    @State private var plusSubscription = PlusSubscriptionManager()
    @AppStorage("totalPoints") private var totalPoints = 0
    @AppStorage("isProMember") private var isProMember = false
    @AppStorage("rarePlayerStockIDs") private var stockIDs = ""
    @AppStorage("rarePlayerLastDailyRefreshV2") private var lastRefresh = 0.0
    @AppStorage("cashPlayerStockIDsV4") private var cashStockIDs = ""
    @AppStorage("cashPlayerLastRefreshV4") private var cashLastRefresh = 0.0

    private var availableIDs: Set<String> {
        Set(stockIDs.split(separator: "|").map(String.init))
    }

    private var cashAvailableIDs: Set<String> {
        Set(cashStockIDs.split(separator: "|").map(String.init))
    }

    private var weeklyCashOffers: [RarePlayerOffer] {
        CashStoreCatalog.players.filter { cashAvailableIDs.contains($0.id) }
    }

    private var rareDropOffers: [RarePlayerOffer] {
        RarePlayerCatalog.offers
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Label("FUTBOL TRAINNIER PLUS", systemImage: "crown.fill")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.soccerGold)

                    Text("Get more points, better drills, exclusive Plus Training, and more rewards every time you train.")
                        .font(.headline)

                    Label("25% more points from every completed drill", systemImage: "star.fill")
                    Label("Exclusive advanced and fun Plus drills", systemImage: "figure.soccer")
                    Label("Better progress toward players and crates", systemImage: "arrow.up.circle.fill")

                    Button {
                        Task {
                            await plusSubscription.purchase()
                        }
                    } label: {
                        Label(
                            isProMember
                                ? "PLUS ACTIVE"
                                : "SUBSCRIBE • \(plusSubscription.monthlyPriceText)",
                            systemImage: isProMember ? "checkmark.seal.fill" : "crown.fill"
                        )
                        .font(.title3)
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 64)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.soccerGreen)
                    .disabled(
                        isProMember
                            || plusSubscription.isPurchasing
                            || plusSubscription.product == nil
                    )

                    Text("Auto-renews monthly until cancelled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button("Restore Purchases") {
                        Task {
                            await plusSubscription.restore()
                        }
                    }
                    .font(.subheadline)

                    Text(plusSubscription.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)
            }

            Section {
                Picker("Store category", selection: $selectedCategory) {
                    ForEach(StoreCategory.allCases) { category in
                        Label(
                            category.rawValue,
                            systemImage: category == .players ? "person.3.fill" : "star.fill"
                        )
                        .tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }

            if selectedCategory == .points {
                Section("Earn Points") {
                    Button {
                        rewardedAdManager.showAd {
                            totalPoints += 50
                        }
                    } label: {
                        Label("Watch Ad • Earn 50 Points", systemImage: "play.rectangle.fill")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!rewardedAdManager.isReady)

                    Text(rewardedAdManager.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Buy Points") {
                    Text("Choose a points pack to use in the Player Shop.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(CashStoreCatalog.pointsPacks) { pack in
                        HStack {
                            Label("\(pack.points) Points", systemImage: "star.fill")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.soccerGold)
                            Spacer()
                            Button(pack.price) { }
                                .buttonStyle(.borderedProminent)
                                .disabled(true)
                        }
                        .padding(.vertical, 6)
                    }
                }
            } else {
                Section("Player Store • 6 Players This Week") {
                    ForEach(weeklyCashOffers) { offer in
                        cashPlayerRow(offer)
                    }
                }

                Section("Rare Player Drop • Buy with Points") {
                    Text("This bonus point offer refreshes every day. There is a 2% chance that one GOAT or elite player appears.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(rareDropOffers) { offer in
                        rarePlayerRow(offer)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.soccerNavy)
        .navigationTitle("Store")
        .task {
            async let adPreparation: Void = rewardedAdManager.prepare()
            async let plusPreparation: Void = plusSubscription.prepare()
            _ = await (adPreparation, plusPreparation)
        }
        .onAppear {
            refreshStockIfNeeded()
            refreshCashStockIfNeeded()
        }
    }

    private func cashPlayerRow(_ offer: RarePlayerOffer) -> some View {
        HStack(spacing: 14) {
            PlayerPhotoView(player: offer.player, size: 62)
                .overlay {
                    Circle()
                        .stroke(Color.soccerGreen, lineWidth: 2)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(offer.player.name)
                    .font(.headline)

                Text("\(offer.player.position) • \(offer.player.overall) OVR • \(offer.tier)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label("Unlimited Availability", systemImage: "infinity.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.soccerGreen)

                Button("Buy for \(offer.price)") { }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
            }
        }
        .padding(.vertical, 8)
    }

    private func rarePlayerRow(_ offer: RarePlayerOffer) -> some View {
        let isAvailable = availableIDs.contains(offer.id)
        let pointCost = rarePointCost(for: offer)
        let formattedPointCost = pointCost.formatted()

        return HStack(spacing: 14) {
            PlayerPhotoView(player: offer.player, size: 68)
                .overlay {
                    Circle()
                        .stroke(isAvailable ? Color.soccerGold : Color.gray, lineWidth: 3)
                }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(offer.player.name)
                        .font(.headline)
                    Text(offer.tier)
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.soccerGold)
                        .foregroundStyle(Color.black)
                        .clipShape(.capsule)
                }

                Text("\(offer.player.position) • \(offer.player.overall) OVR")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label(
                    isAvailable ? "Available This Week • \(formattedPointCost) Points" : "Not Available This Week • \(formattedPointCost) Points",
                    systemImage: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isAvailable ? Color.soccerGold : Color.gray)

                Button(isAvailable ? "Buy for \(formattedPointCost) Points" : "Not Available This Week") { }
                    .buttonStyle(.borderedProminent)
                    .tint(isAvailable ? Color.soccerGreen : Color.gray)
                    .disabled(true)
            }
        }
        .padding(.vertical, 8)
    }

    private func rarePointCost(for offer: RarePlayerOffer) -> Int {
        switch offer.player.overall {
        case 99...:
            12_000
        case 98:
            10_000
        case 97:
            8_000
        default:
            7_000
        }
    }

    private func refreshCashStockIfNeeded() {
        let now = Date().timeIntervalSince1970
        let week: TimeInterval = 7 * 24 * 60 * 60
        guard cashLastRefresh == 0 || now - cashLastRefresh >= week else { return }

        let weeklySuperstarID = CashStoreCatalog.players
            .filter { $0.tier == "Superstar" }
            .randomElement()?
            .id
        let weeklyEliteID = CashStoreCatalog.players
            .filter { $0.tier == "Elite" }
            .randomElement()?
            .id
        let lowerTierIDs = CashStoreCatalog.players
            .filter { $0.tier == "Quality" || $0.tier == "Solid" }
            .shuffled()
            .prefix(4)
            .map(\.id)

        cashStockIDs = (
            [weeklySuperstarID, weeklyEliteID].compactMap { $0 } + lowerTierIDs
        )
        .joined(separator: "|")
        cashLastRefresh = now
    }

    private func refreshStockIfNeeded() {
        let now = Date().timeIntervalSince1970
        let day: TimeInterval = 24 * 60 * 60
        guard lastRefresh == 0 || now - lastRefresh >= day else { return }

        if Int.random(in: 0..<100) < 2, let rarePlayer = rareDropOffers.randomElement() {
            stockIDs = rarePlayer.id
        } else {
            stockIDs = ""
        }
        lastRefresh = now
    }
}

// PlayerShopView.swift
// The Player Shop tab: player crates, position browsing, and search.

import StoreKit
import SwiftUI

private struct CrateOdds {
    let goat: Int
    let superstar: Int
    let legendary: Int
    let elite: Int
    let otherRare: Int
    let good: Int
    let points: Int
    let regular: Int

    var rare: Int {
        goat + superstar + legendary + elite + otherRare
    }
}

private enum PlayerCrateTier: String, CaseIterable, Identifiable {
    case starter
    case pro
    case premium

    var id: String { rawValue }

    var name: LocalizedStringResource {
        switch self {
        case .starter:
            "Starter Crate"
        case .pro:
            "Pro Crate"
        case .premium:
            "Premium Crate"
        }
    }

    var cost: Int {
        switch self {
        case .starter:
            150
        case .pro:
            300
        case .premium:
            600
        }
    }

    var odds: CrateOdds {
        switch self {
        case .starter:
            CrateOdds(
                goat: 10,
                superstar: 1_000,
                legendary: 2_000,
                elite: 3_000,
                otherRare: 5_000,
                good: 20_000,
                points: 10_000,
                regular: 58_990
            )
        case .pro:
            CrateOdds(
                goat: 50,
                superstar: 2_500,
                legendary: 4_000,
                elite: 6_000,
                otherRare: 7_500,
                good: 30_000,
                points: 10_000,
                regular: 39_950
            )
        case .premium:
            CrateOdds(
                goat: 200,
                superstar: 5_000,
                legendary: 7_000,
                elite: 9_000,
                otherRare: 10_000,
                good: 40_000,
                points: 10_000,
                regular: 18_800
            )
        }
    }

    func percentageText(for count: Int) -> String {
        let percentage = Double(count) / 1_000
        return percentage.formatted(.number.precision(.fractionLength(0...3))) + "%"
    }
}

private struct PlayerCrateCard: View {
    let tier: PlayerCrateTier
    let availablePoints: Int
    let onOpen: () -> Void

    var body: some View {
        let odds = tier.odds

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(tier.name, systemImage: "shippingbox.fill")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soccerGold)
                Spacer()
                Text("\(tier.cost) points")
                    .fontWeight(.bold)
            }

            LabeledContent("Regular player", value: tier.percentageText(for: odds.regular))
            LabeledContent("Good player", value: tier.percentageText(for: odds.good))
            LabeledContent("Rare player", value: tier.percentageText(for: odds.rare))
            LabeledContent("Points reward", value: tier.percentageText(for: odds.points))
            LabeledContent("GOAT included in Rare", value: tier.percentageText(for: odds.goat))
                .foregroundStyle(.secondary)

            Button {
                onOpen()
            } label: {
                Label(
                    availablePoints >= tier.cost
                        ? "Open for \(tier.cost) Points"
                        : "Need \(tier.cost - availablePoints) More Points",
                    systemImage: "sparkles"
                )
                .font(.headline)
                .fontWeight(.heavy)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.soccerGreen)
            .disabled(availablePoints < tier.cost)
        }
        .padding(.vertical, 8)
    }
}

struct PlayerShopView: View {
    @Binding var totalPoints: Int
    @AppStorage("ownedPlayerIDs") private var ownedPlayerIDs = ""
    @AppStorage("playerShopDailyStockV6") private var stockText = ""
    @AppStorage("playerShopLastDailyRestockV6") private var lastRestock = 0.0
    @State private var shopMessage = ""
    @State private var showShopMessage = false
    @State private var searchText = ""
    @State private var selectedPosition = "All"
    @State private var yamalProduct: Product?
    @State private var isPurchasingYamal = false

    private let yamalProductID = "com.thomastelintelo.soccertraining.yamal"

    private let positionOrder = ["GK", "LB", "CB", "RB", "LM", "CM", "RM", "ST"]

    private var allShopPlayers: [SoccerPlayer] {
        PlayerCatalog.players
    }

    private var regularPlayers: [SoccerPlayer] {
        allShopPlayers.filter { stock[$0.id, default: 0] > 0 }
    }

    private var yamal: SoccerPlayer {
        PlayerCatalog.players.first { $0.id == "yamal" }
            ?? SoccerPlayer(id: "yamal", name: "Lamine Yamal", position: "RM", overall: 97, cost: 8_000, weeklyStock: 0)
    }

    private var ownedIDs: Set<String> {
        Set(ownedPlayerIDs.split(separator: "|").map(String.init))
    }

    private var stock: [String: Int] {
        var savedStock: [String: Int] = [:]

        for entry in stockText.split(separator: "|") {
            let parts = entry.split(separator: ":")
            guard parts.count == 2, let count = Int(parts[1]) else { continue }
            savedStock[String(parts[0])] = count
        }

        for player in allShopPlayers where savedStock[player.id] == nil {
            savedStock[player.id] = 0
        }

        return savedStock
    }

    private var matchingPlayers: [SoccerPlayer] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        return regularPlayers
            .filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.position.localizedCaseInsensitiveContains(query)
            }
            .sorted {
                let firstPosition = positionOrder.firstIndex(of: $0.position) ?? positionOrder.count
                let secondPosition = positionOrder.firstIndex(of: $1.position) ?? positionOrder.count
                if firstPosition == secondPosition {
                    return $0.overall > $1.overall
                }
                return firstPosition < secondPosition
            }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    Text("BUILD YOUR DREAM TEAM")
                        .font(.caption)
                        .fontWeight(.black)
                        .tracking(1.2)

                    HStack(alignment: .firstTextBaseline) {
                        Text("Transfer Market")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                        Spacer()
                        Label("\(totalPoints)", systemImage: "star.fill")
                            .font(.title2)
                            .fontWeight(.heavy)
                    }

                    Text("Open crates or sign players by position. Better crates cost more and give stronger odds.")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.soccerNavy)
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Color.soccerLime, Color.soccerGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20)
                )
                .listRowBackground(Color.clear)
            }

            Section("Choose Position") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(["All"] + positionOrder, id: \.self) { position in
                            Button(position) {
                                selectedPosition = position
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedPosition == position ? Color.soccerGreen : Color.soccerSurface)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Player Crates") {
                Text("Higher-cost crates have better chances of getting Good, Rare, and GOAT players.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(PlayerCrateTier.allCases) { tier in
                    PlayerCrateCard(
                        tier: tier,
                        availablePoints: totalPoints
                    ) {
                        openPlayerCrate(tier)
                    }

                    if tier != PlayerCrateTier.allCases.last {
                        Divider()
                    }
                }
            }

            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ForEach(
                    positionOrder.filter { selectedPosition == "All" || $0 == selectedPosition },
                    id: \.self
                ) { position in
                    Section(position) {
                        ForEach(
                            regularPlayers
                                .filter { $0.position == position }
                                .sorted { $0.overall > $1.overall }
                        ) { player in
                            playerRow(player)
                        }
                    }
                }
            } else if matchingPlayers.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                Section("Search Results") {
                    ForEach(matchingPlayers) { player in
                        playerRow(player)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.soccerNavy)
        .navigationTitle("Player Shop")
        .safeAreaPadding(.bottom, 72)
        .searchable(text: $searchText, prompt: "Search players or positions")
        .onAppear {
            restockIfNeeded()
        }
        .task {
            yamalProduct = try? await Product.products(for: [yamalProductID]).first
        }
        .alert("Player Shop", isPresented: $showShopMessage) {
            Button("OK") { }
        } message: {
            Text(shopMessage)
        }
    }

    private var rareYamalRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(yamal.name)
                        .font(.headline)
                    Text("\(yamal.position) • Overall \(yamal.overall) • Rare")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Color.soccerGold)
            }

            if ownedIDs.contains(yamal.id) {
                Label("Owned", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.soccerGreen)
            } else if let yamalProduct {
                Button {
                    Task {
                        await purchaseYamal(yamalProduct)
                    }
                } label: {
                    Text(isPurchasingYamal ? "Purchasing…" : "Buy for \(yamalProduct.displayPrice)")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPurchasingYamal)
            } else {
                Text("Rare purchase unavailable until the product is configured in App Store Connect.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func purchaseYamal(_ product: Product) async {
        isPurchasingYamal = true
        defer { isPurchasingYamal = false }

        do {
            let result = try await product.purchase()
            guard case .success(.verified(let transaction)) = result else { return }

            var updatedOwnedIDs = ownedIDs
            updatedOwnedIDs.insert(yamal.id)
            ownedPlayerIDs = updatedOwnedIDs.sorted().joined(separator: "|")
            await transaction.finish()
            shopMessage = "\(yamal.name) was added to My Team!"
            showShopMessage = true
        } catch {
            shopMessage = "The purchase could not be completed."
            showShopMessage = true
        }
    }

    private func playerRow(_ player: SoccerPlayer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.name)
                        .font(.headline)
                    Text("\(player.position) • Overall \(player.overall)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("OVR \(player.overall)")
                    .fontWeight(.heavy)
                    .padding(8)
                    .background(player.overall >= 89 ? Color.soccerGreen : Color.soccerSurface)
                    .foregroundStyle(Color.soccerCream)
                    .clipShape(.rect(cornerRadius: 9))
            }

            HStack {
                Label("\(player.cost) points", systemImage: "star.fill")
                    .foregroundStyle(Color.soccerGreen)
                Spacer()
                if !ownedIDs.contains(player.id) {
                    Label("Available", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.soccerLime)
                }
            }
            .font(.subheadline)

            Button(buttonTitle(for: player)) {
                buy(player)
            }
            .font(.headline)
            .fontWeight(.heavy)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .background(canBuy(player) ? Color.soccerGreen : Color.gray)
            .foregroundStyle(Color.soccerCream)
            .clipShape(.rect(cornerRadius: 14))
            .disabled(!canBuy(player))
        }
        .padding(.vertical, 8)
    }

    private func canBuy(_ player: SoccerPlayer) -> Bool {
        !ownedIDs.contains(player.id) && totalPoints >= player.cost
    }

    private func buttonTitle(for player: SoccerPlayer) -> String {
        if ownedIDs.contains(player.id) {
            return "Owned"
        }
        if totalPoints < player.cost {
            return "Need \(player.cost - totalPoints) More Points"
        }
        return "Buy Player"
    }

    private func buy(_ player: SoccerPlayer) {
        guard canBuy(player) else { return }

        var updatedOwnedIDs = ownedIDs
        updatedOwnedIDs.insert(player.id)
        ownedPlayerIDs = updatedOwnedIDs.sorted().joined(separator: "|")
        totalPoints -= player.cost

        shopMessage = "\(player.name) was added to My Team!"
        showShopMessage = true
    }

    private func openPlayerCrate(_ tier: PlayerCrateTier) {
        guard totalPoints >= tier.cost else { return }
        totalPoints -= tier.cost

        let roll = Int.random(in: 0..<100_000)
        let odds = tier.odds
        let goatIDs: Set<String> = ["ronaldo", "messi", "pele"]
        let superstarIDs: Set<String> = ["yamal", "mbappe", "haaland", "neymar"]
        let legendaryIDs: Set<String> = ["ronaldo_nazario", "maradona"]
        let eliteIDs: Set<String> = ["bellingham", "van_dijk", "vinicius", "kane"]
        let specialIDs = goatIDs
            .union(superstarIDs)
            .union(legendaryIDs)
            .union(eliteIDs)
        let goodIDs = Set(
            regularPlayers
                .filter { $0.overall >= 85 && !specialIDs.contains($0.id) }
                .map(\.id)
        )
        let otherRareIDs = Set(
            regularPlayers
                .filter { (79...84).contains($0.overall) && !specialIDs.contains($0.id) }
                .map(\.id)
        )
        let regularIDs = Set(
            regularPlayers
                .filter { $0.overall <= 78 && !specialIDs.contains($0.id) }
                .map(\.id)
        )

        let playerRewards: [(weight: Int, ids: Set<String>, name: String)] = [
            (odds.goat, goatIDs, "GOAT"),
            (odds.superstar, superstarIDs, "Superstar"),
            (odds.legendary, legendaryIDs, "Legendary player"),
            (odds.elite, eliteIDs, "Elite player"),
            (odds.otherRare, otherRareIDs, "Other rare"),
            (odds.good, goodIDs, "Good player"),
        ]

        var upperBound = 0
        for reward in playerRewards {
            upperBound += reward.weight
            if roll < upperBound {
                awardCratePlayer(from: reward.ids, tierName: reward.name)
                return
            }
        }

        upperBound += odds.points
        if roll < upperBound {
            awardCratePoints()
            return
        }

        awardCratePlayer(from: regularIDs, tierName: "Regular player")
    }

    private func awardCratePlayer(from ids: Set<String>, tierName: String) {
        let candidates = allShopPlayers.filter { ids.contains($0.id) }

        guard let player = candidates.randomElement() else {
            awardCratePoints()
            return
        }

        if ownedIDs.contains(player.id) {
            totalPoints += 50
            shopMessage = "Duplicate \(player.name)! You received 50 points instead."
        } else {
            var updatedOwnedIDs = ownedIDs
            updatedOwnedIDs.insert(player.id)
            ownedPlayerIDs = updatedOwnedIDs.sorted().joined(separator: "|")
            shopMessage = "\(tierName): You unlocked \(player.name)!"
        }

        showShopMessage = true
    }

    private func awardCratePoints() {
        let pointsWon = Int.random(in: 50...150)
        totalPoints += pointsWon
        shopMessage = "You won \(pointsWon) points!"
        showShopMessage = true
    }

    private func restockIfNeeded() {
        let now = Date().timeIntervalSince1970
        let day: TimeInterval = 24 * 60 * 60

        if stockText.isEmpty || lastRestock == 0 || now - lastRestock >= day {
            let freshStock = Dictionary(
                uniqueKeysWithValues: allShopPlayers.map { player in
                    let availabilityRoll = Int.random(in: 0..<100_000)
                    let isAvailable: Bool
                    if player.overall >= 90 {
                        isAvailable = availabilityRoll < 5
                    } else if player.overall >= 85 {
                        isAvailable = availabilityRoll < 20_000
                    } else {
                        isAvailable = true
                    }
                    return (player.id, isAvailable ? max(1, player.weeklyStock) : 0)
                }
            )
            saveStock(freshStock)
            lastRestock = now
        }
    }

    private func dailyStockChance(for player: SoccerPlayer) -> Int {
        switch player.id {
        case "ronaldo", "messi", "pele":
            1
        case "ronaldo_nazario", "maradona":
            2
        case "yamal", "mbappe", "haaland", "neymar":
            3
        case "van_dijk", "vinicius", "bellingham", "kane":
            4
        case "saka", "rodri", "pedri", "martinez_gk":
            10
        case "alisson", "neuer", "maignan", "raya", "costa":
            15
        case "salah":
            20
        default:
            player.overall >= 85 ? 20 : 80
        }
    }

    private func saveStock(_ stock: [String: Int]) {
        stockText = stock
            .map { "\($0.key):\($0.value)" }
            .sorted()
            .joined(separator: "|")
    }
}

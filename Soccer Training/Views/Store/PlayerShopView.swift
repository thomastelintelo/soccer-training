// PlayerShopView.swift
// The Player Shop tab: player crates, position browsing, and search.

import StoreKit
import SwiftUI

#if DEBUG
private struct DevPlusUnlockView: View {
    @AppStorage("isProMember") private var isProMember = false
    @AppStorage("totalPoints") private var totalPoints = 0

    var body: some View {
        Form {
            Section {
                Toggle("Plus Mode", isOn: $isProMember)
            } footer: {
                Text("Simulates an active Plus subscription without a real purchase. Debug builds only.")
            }

            Section {
                Button("Add 1,000 Points") { totalPoints += 1000 }
                Button("Reset Points to 0", role: .destructive) { totalPoints = 0 }
            } footer: {
                Text("Grants free points for testing crates and player purchases. Debug builds only.")
            }
        }
        .navigationTitle("Dev Tools")
    }
}
private typealias _DevToolsView = DevPlusUnlockView
#else
private struct _DevToolsView: View { var body: some View { EmptyView() } }
#endif

private struct ShopTotalPointsKey: EnvironmentKey { static let defaultValue: Int = 0 }
extension EnvironmentValues { var _shopTotalPoints: Int { get { self[ShopTotalPointsKey.self] } set { self[ShopTotalPointsKey.self] = newValue } } }

private struct ShopHeader: View {
    @Environment(\._shopTotalPoints) private var _totalPoints

    var body: some View {
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
                Label("\(_totalPoints)", systemImage: "star.fill")
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
    }
}

private struct CrateReveal: Identifiable {
    let id = UUID()
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
}

private struct CratePresentView: View {
    let reward: CrateReveal
    let onDismiss: () -> Void

    @State private var isUnwrapped = false
    @State private var lidOffset: CGFloat = 0
    @State private var boxWiggle: Double = 0
    @State private var showConfetti = false
    @State private var showReward = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            if showConfetti {
                ConfettiView()
            }

            if !isUnwrapped {
                VStack(spacing: 20) {
                    Text("A gift arrived!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.soccerCream)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.soccerGreen, Color.soccerNavy],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 160, height: 130)
                            .overlay(
                                Rectangle()
                                    .fill(Color.soccerGold)
                                    .frame(width: 22)
                            )
                            .overlay(
                                Rectangle()
                                    .fill(Color.soccerGold)
                                    .frame(height: 22)
                            )

                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.soccerGold)
                            .frame(width: 56, height: 44)
                            .rotationEffect(.degrees(-40))
                            .offset(x: -18, y: -66)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.soccerGold)
                            .frame(width: 56, height: 44)
                            .rotationEffect(.degrees(40))
                            .offset(x: 18, y: -66)
                    }
                    .rotationEffect(.degrees(boxWiggle))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                            boxWiggle = 4
                        }
                    }

                    Text("Tap to open")
                        .font(.headline)
                        .foregroundStyle(Color.soccerLime)
                }
                .transition(.opacity)
                .onTapGesture {
                    Haptics.success()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isUnwrapped = true
                    }
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                            showReward = true
                        }
                    }
                }
            } else {
                VStack(spacing: 18) {
                    Image(systemName: reward.icon)
                        .font(.system(size: 76))
                        .foregroundStyle(reward.tint)
                        .symbolEffect(.bounce, value: showReward)
                        .scaleEffect(showReward ? 1 : 0.3)
                        .opacity(showReward ? 1 : 0)

                    Text(reward.title)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.soccerCream)
                        .multilineTextAlignment(.center)
                        .opacity(showReward ? 1 : 0)

                    Text(reward.subtitle)
                        .font(.headline)
                        .foregroundStyle(Color.soccerCream.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .opacity(showReward ? 1 : 0)

                    if showReward {
                        Button("Awesome!") {
                            Haptics.tap()
                            onDismiss()
                        }
                        .font(.headline)
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(Color.soccerLime)
                        .foregroundStyle(Color.soccerNavy)
                        .clipShape(.rect(cornerRadius: 14))
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                        .transition(.opacity)
                    }
                }
                .padding(24)
            }
        }
    }
}

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
                goat: 5,
                superstar: 500,
                legendary: 1_000,
                elite: 1_500,
                otherRare: 2_500,
                good: 10_000,
                points: 10_000,
                regular: 74_495
            )
        case .pro:
            CrateOdds(
                goat: 25,
                superstar: 1_250,
                legendary: 2_000,
                elite: 3_000,
                otherRare: 3_750,
                good: 15_000,
                points: 10_000,
                regular: 64_975
            )
        case .premium:
            CrateOdds(
                goat: 100,
                superstar: 2_500,
                legendary: 3_500,
                elite: 4_500,
                otherRare: 5_000,
                good: 20_000,
                points: 10_000,
                regular: 54_400
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
    @AppStorage("playerShopDailyStockV7") private var stockText = ""
    @AppStorage("playerShopLastDailyRestockV7") private var lastRestock = 0.0
    @State private var shopMessage = ""
    @State private var showShopMessage = false
    @State private var crateReveal: CrateReveal?
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

    /// The best player currently in stock, shown as a hero card so opening
    /// the shop feels like unveiling today's star signing.
    private var featuredPlayer: SoccerPlayer? {
        regularPlayers
            .filter { !ownedIDs.contains($0.id) }
            .max { $0.overall < $1.overall }
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
                ShopHeader()
                    .listRowBackground(Color.clear)
            }

            if let featuredPlayer {
                Section {
                    featuredPlayerCard(featuredPlayer)
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity)
                }
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
        .environment(\._shopTotalPoints, totalPoints)
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Dev") { _DevToolsView() }
            }
            #endif
        }
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
        .fullScreenCover(item: $crateReveal) { reveal in
            CratePresentView(reward: reveal) {
                crateReveal = nil
            }
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

    private func featuredPlayerCard(_ player: SoccerPlayer) -> some View {
        VStack(spacing: 10) {
            Label("Featured Today", systemImage: "star.circle.fill")
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerGold)

            PlayerCardView(player: player, effectiveOverall: player.overall)

            Button(buttonTitle(for: player)) {
                buy(player)
            }
            .font(.headline)
            .fontWeight(.heavy)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(canBuy(player) ? Color.soccerGreen : Color.gray)
            .foregroundStyle(Color.soccerCream)
            .clipShape(.rect(cornerRadius: 14))
            .disabled(!canBuy(player))
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func tierLabel(for player: SoccerPlayer) -> String {
        switch PlayerCardTier.tier(for: player.overall) {
        case .special: "SPECIAL"
        case .gold: "GOLD"
        case .silver: "SILVER"
        case .bronze: "BRONZE"
        }
    }

    private func playerRow(_ player: SoccerPlayer) -> some View {
        HStack(alignment: .top, spacing: 14) {
            PlayerCardView(player: player, effectiveOverall: player.overall)
                .scaleEffect(0.55)
                .frame(width: 220 * 0.55, height: 300 * 0.55)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.name)
                        .font(.headline)
                    HStack(spacing: 6) {
                        Text(player.position)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(tierLabel(for: player))
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.soccerGold.opacity(0.25), in: .capsule)
                            .foregroundStyle(Color.soccerGold)
                    }
                }

                Label("\(player.cost) points", systemImage: "star.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.soccerGreen)

                if !ownedIDs.contains(player.id) {
                    Label("Available", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerLime)
                }

                Spacer(minLength: 0)

                Button(buttonTitle(for: player)) {
                    buy(player)
                }
                .font(.headline)
                .fontWeight(.heavy)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(canBuy(player) ? Color.soccerGreen : Color.gray)
                .foregroundStyle(Color.soccerCream)
                .clipShape(.rect(cornerRadius: 14))
                .disabled(!canBuy(player))
            }
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

        var updatedStock = stock
        updatedStock[player.id] = max(0, updatedStock[player.id, default: 0] - 1)
        saveStock(updatedStock)

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
            crateReveal = CrateReveal(
                icon: "arrow.triangle.2.circlepath",
                tint: .secondary,
                title: "Duplicate!",
                subtitle: "\(player.name) again — enjoy 50 points instead."
            )
        } else {
            var updatedOwnedIDs = ownedIDs
            updatedOwnedIDs.insert(player.id)
            ownedPlayerIDs = updatedOwnedIDs.sorted().joined(separator: "|")
            crateReveal = CrateReveal(
                icon: "star.fill",
                tint: tierTint(tierName),
                title: tierName,
                subtitle: "\(player.name) joins your team!"
            )
        }
    }

    private func awardCratePoints() {
        let pointsWon = Int.random(in: 5...15) * 10
        totalPoints += pointsWon
        crateReveal = CrateReveal(
            icon: "star.circle.fill",
            tint: Color.soccerGold,
            title: "Bonus Points!",
            subtitle: "You won \(pointsWon) points!"
        )
    }

    private func tierTint(_ tierName: String) -> Color {
        switch tierName {
        case "GOAT", "Superstar":
            return Color.soccerGold
        case "Legendary player", "Elite player":
            return Color.soccerLime
        case "Other rare", "Good player":
            return Color.soccerGreen
        default:
            return Color.soccerCream
        }
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

    private func saveStock(_ stock: [String: Int]) {
        stockText = stock
            .map { "\($0.key):\($0.value)" }
            .sorted()
            .joined(separator: "|")
    }
}


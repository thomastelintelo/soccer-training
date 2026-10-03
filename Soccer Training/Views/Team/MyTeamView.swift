// MyTeamView.swift
// The player's Starting 11 on a soccer field, with substitution pickers.

import SwiftUI

private struct LineupSlot: Identifiable {
    let id: String
    let position: String
    let occurrence: Int
    let label: String
}

struct MyTeamView: View {
    @AppStorage("ownedPlayerIDs") private var ownedPlayerIDs = ""
    @AppStorage("startingLineupSelections") private var lineupSelectionText = ""
    @AppStorage("totalPoints") private var totalPoints = 0
    @AppStorage("playerUpgradeLevels") private var upgradeLevelsText = ""
    @AppStorage("favoriteTeam") private var favoriteTeam = ""
    @State private var upgradeMessage = ""
    @State private var showUpgradeMessage = false
    @State private var upgradeSearchText = ""
    @State private var playerForDetail: SoccerPlayer?
    @State private var sellMessage = ""
    @State private var showSellMessage = false
    @State private var hasAppeared = false

    private let positionOrder = ["GK", "LB", "CB", "RB", "LM", "CM", "RM", "ST"]

    private var ownedPlayers: [SoccerPlayer] {
        let ownedIDs = Set(ownedPlayerIDs.split(separator: "|").map(String.init))
        return PlayerCatalog.players.filter { ownedIDs.contains($0.id) }
    }

    private func sortedByPositionThenOverall(_ players: [SoccerPlayer]) -> [SoccerPlayer] {
        players.sorted {
            let firstPosition = positionOrder.firstIndex(of: $0.position) ?? positionOrder.count
            let secondPosition = positionOrder.firstIndex(of: $1.position) ?? positionOrder.count
            if firstPosition == secondPosition {
                return $0.overall > $1.overall
            }
            return firstPosition < secondPosition
        }
    }

    private var upgradeSearchQuery: String {
        upgradeSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var upgradeSearchResults: [SoccerPlayer] {
        guard !upgradeSearchQuery.isEmpty else { return [] }
        return sortedByPositionThenOverall(
            ownedPlayers.filter {
                $0.name.localizedCaseInsensitiveContains(upgradeSearchQuery)
                    || $0.position.localizedCaseInsensitiveContains(upgradeSearchQuery)
            }
        )
    }

    private var upgradeLevels: [String: Int] {
        PlayerUpgrade.levels(from: upgradeLevelsText)
    }

    private func effectiveOverall(for player: SoccerPlayer) -> Int {
        PlayerUpgrade.effectiveOverall(for: player, levels: upgradeLevels)
    }

    private var lineupPlayers: [SoccerPlayer] {
        lineupSlots.compactMap { player(for: $0.position, occurrence: $0.occurrence) }
    }

    private var teamOverall: Int {
        guard !lineupPlayers.isEmpty else { return 0 }
        let total = lineupPlayers.reduce(0) { $0 + effectiveOverall(for: $1) }
        return total / lineupPlayers.count
    }

    private func nextUpgradeCost(for player: SoccerPlayer, stat: String) -> Int? {
        let nextLevel = PlayerUpgrade.level(for: player.id, stat: stat, in: upgradeLevels) + 1
        guard nextLevel <= PlayerUpgrade.maxLevel else { return nil }
        return PlayerUpgrade.cost(for: player, toReachLevel: nextLevel)
    }

    private func upgrade(_ player: SoccerPlayer, stat: String) {
        guard let cost = nextUpgradeCost(for: player, stat: stat), totalPoints >= cost else { return }

        totalPoints -= cost
        var updatedLevels = upgradeLevels
        updatedLevels["\(player.id):\(stat)", default: 0] += 1
        upgradeLevelsText = PlayerUpgrade.encode(updatedLevels)

        Haptics.success()
        upgradeMessage = "\(player.name)'s \(stat) is up to \(effectiveOverall(for: player)) OVR!"
        showUpgradeMessage = true
    }

    private func sellValue(for player: SoccerPlayer) -> Int {
        let rawValue = Double(player.cost) * 0.15
        return max(10, Int((rawValue / 10).rounded()) * 10)
    }

    private func sellPlayer(_ player: SoccerPlayer) {
        let refund = sellValue(for: player)

        var remainingOwnedIDs = Set(ownedPlayerIDs.split(separator: "|").map(String.init))
        remainingOwnedIDs.remove(player.id)
        ownedPlayerIDs = remainingOwnedIDs.sorted().joined(separator: "|")

        let remainingLevels = upgradeLevels.filter { !$0.key.hasPrefix("\(player.id):") }
        upgradeLevelsText = PlayerUpgrade.encode(remainingLevels)

        let remainingSelections = lineupSelections.filter { $0.value != player.id }
        lineupSelectionText = remainingSelections
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: "|")

        totalPoints += refund
        playerForDetail = nil

        Haptics.tap()
        sellMessage = "Sold \(player.name) for \(refund) points."
        showSellMessage = true
    }

    private let lineupSlots = [
        LineupSlot(id: "ST0", position: "ST", occurrence: 0, label: "Striker 1"),
        LineupSlot(id: "ST1", position: "ST", occurrence: 1, label: "Striker 2"),
        LineupSlot(id: "LM0", position: "LM", occurrence: 0, label: "Left Midfielder"),
        LineupSlot(id: "CM0", position: "CM", occurrence: 0, label: "Center Midfielder 1"),
        LineupSlot(id: "CM1", position: "CM", occurrence: 1, label: "Center Midfielder 2"),
        LineupSlot(id: "RM0", position: "RM", occurrence: 0, label: "Right Midfielder"),
        LineupSlot(id: "LB0", position: "LB", occurrence: 0, label: "Left Back"),
        LineupSlot(id: "CB0", position: "CB", occurrence: 0, label: "Center Back 1"),
        LineupSlot(id: "CB1", position: "CB", occurrence: 1, label: "Center Back 2"),
        LineupSlot(id: "RB0", position: "RB", occurrence: 0, label: "Right Back"),
        LineupSlot(id: "GK0", position: "GK", occurrence: 0, label: "Goalkeeper"),
    ]

    private var lineupSelections: [String: String] {
        Dictionary(
            uniqueKeysWithValues: lineupSelectionText.split(separator: "|").compactMap { entry in
                let parts = entry.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                return (String(parts[0]), String(parts[1]))
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Starting 11")
                    .font(.largeTitle)
                    .fontWeight(.heavy)

                Text("Your players are shown in their spots on the field.")
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    if let team = FavoriteTeam(rawValue: favoriteTeam) {
                        ClubCrestView(team: team, size: 44)
                        Text(team.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                    } else {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.title2)
                            .foregroundStyle(Color.soccerLime)
                        Text("Your Club")
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(teamOverall)")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color.soccerGold)
                        Text("CLUB OVR")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.soccerLime.opacity(0.5), lineWidth: 1)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.soccerSurface,
                                    Color.soccerNavy,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    SoccerFieldLines()

                    VStack {
                        HStack(spacing: 48) {
                            teamPlayerSpot(for: "ST", occurrence: 0, portraitNumber: 1)
                            teamPlayerSpot(for: "ST", occurrence: 1, portraitNumber: 2)
                        }

                        Spacer()

                        HStack {
                            teamPlayerSpot(for: "LM", portraitNumber: 3)
                            Spacer()
                            teamPlayerSpot(for: "CM", occurrence: 0, portraitNumber: 4)
                            teamPlayerSpot(for: "CM", occurrence: 1, portraitNumber: 5)
                            Spacer()
                            teamPlayerSpot(for: "RM", portraitNumber: 6)
                        }

                        Spacer()

                        HStack {
                            teamPlayerSpot(for: "LB", portraitNumber: 7)
                            Spacer()
                            teamPlayerSpot(for: "CB", occurrence: 0, portraitNumber: 8)
                            teamPlayerSpot(for: "CB", occurrence: 1, portraitNumber: 9)
                            Spacer()
                            teamPlayerSpot(for: "RB", portraitNumber: 10)
                        }

                        Spacer()

                        teamPlayerSpot(for: "GK", portraitNumber: 11)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 24)
                }
                .frame(height: 620)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.soccerLime.opacity(0.75), lineWidth: 2)
                }

                Label(
                    "\(ownedPlayers.count) players owned",
                    systemImage: ownedPlayers.count >= 11 ? "checkmark.circle.fill" : "person.3.fill"
                )
                .font(.headline)
                .foregroundStyle(Color.soccerLime)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Substitutions")
                        .font(.title2)
                        .fontWeight(.heavy)

                    Text("Choose the starter for each position when you own multiple players.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(lineupSlots) { slot in
                        let candidates = players(for: slot.position)
                        let currentPlayer = player(for: slot.position, occurrence: slot.occurrence)

                        if !candidates.isEmpty {
                            HStack {
                                Button {
                                    if let currentPlayer {
                                        playerForDetail = currentPlayer
                                    }
                                } label: {
                                    HStack {
                                        Text(slot.label)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        if let currentPlayer {
                                            Text("\(currentPlayer.name) • \(effectiveOverall(for: currentPlayer)) OVR")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .contentShape(.rect)
                                }
                                .buttonStyle(.plain)

                                Picker(
                                    slot.label,
                                    selection: lineupBinding(for: slot)
                                ) {
                                    ForEach(candidates) { player in
                                        Text("\(player.name) • \(player.overall) OVR")
                                            .tag(player.id)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .fixedSize()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Player Upgrades")
                        .font(.title2)
                        .fontWeight(.heavy)

                    Text("Spend points to level up a player's individual stats — pace, shooting, passing, dribbling, defending, and physical — up to 3 levels each. Tap a player to upgrade.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Label("\(totalPoints)", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundStyle(Color.soccerLime)

                    if upgradeSearchQuery.isEmpty {
                        ForEach(positionOrder, id: \.self) { position in
                            let playersAtPosition = sortedByPositionThenOverall(
                                ownedPlayers.filter { $0.position == position }
                            )

                            if !playersAtPosition.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(position)
                                        .font(.subheadline)
                                        .fontWeight(.heavy)
                                        .foregroundStyle(Color.soccerLime)

                                    ForEach(playersAtPosition) { player in
                                        upgradeRow(for: player)
                                    }
                                }
                            }
                        }
                    } else if upgradeSearchResults.isEmpty {
                        Text("No players match \"\(upgradeSearchQuery)\"")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(upgradeSearchResults) { player in
                            upgradeRow(for: player)
                        }
                    }
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 18))
            }
            .padding()
        }
        .searchable(text: $upgradeSearchText, prompt: "Search your players to upgrade")
        .background(Color.soccerNavy)
        .foregroundStyle(Color.soccerCream)
        .navigationTitle("My Team")
        .onAppear {
            withAnimation {
                hasAppeared = true
            }
        }
        .alert("Player Upgrade", isPresented: $showUpgradeMessage) {
            Button("OK") { }
        } message: {
            Text(upgradeMessage)
        }
        .alert("Player Sold", isPresented: $showSellMessage) {
            Button("OK") { }
        } message: {
            Text(sellMessage)
        }
        .sheet(item: $playerForDetail) { player in
            PlayerDetailSheet(
                player: player,
                effectiveOverall: effectiveOverall(for: player),
                upgradeLevels: upgradeLevels,
                totalPoints: totalPoints,
                sellValue: sellValue(for: player),
                onUpgrade: { stat in upgrade(player, stat: stat) },
                onSell: { sellPlayer(player) }
            )
        }
    }

    private func teamPlayerSpot(for position: String, occurrence: Int = 0, portraitNumber: Int) -> some View {
        let matchedPlayer = player(for: position, occurrence: occurrence)
        return TeamPlayerSpot(
            player: matchedPlayer,
            overall: matchedPlayer.map { effectiveOverall(for: $0) },
            position: position,
            portraitNumber: portraitNumber
        )
        .onTapGesture {
            if let matchedPlayer {
                playerForDetail = matchedPlayer
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.5)
        .animation(
            .spring(response: 0.45, dampingFraction: 0.65).delay(Double(portraitNumber) * 0.05),
            value: hasAppeared
        )
    }

    private func upgradeRow(for player: SoccerPlayer) -> some View {
        let totalLevel = PlayerUpgrade.totalLevels(for: player.id, in: upgradeLevels)
        let maxTotal = PlayerUpgrade.statLabels(for: player).count * PlayerUpgrade.maxLevel

        return Button {
            playerForDetail = player
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.name)
                        .fontWeight(.semibold)
                    Text("\(player.position) • \(effectiveOverall(for: player)) OVR • \(totalLevel)/\(maxTotal) upgraded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .foregroundStyle(Color.soccerLime)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

    private func players(for position: String) -> [SoccerPlayer] {
        ownedPlayers
            .filter { $0.position == position }
            .sorted { $0.overall > $1.overall }
    }

    private func player(for position: String, occurrence: Int = 0) -> SoccerPlayer? {
        let matchingPlayers = players(for: position)
        let slotID = "\(position)\(occurrence)"

        if let selectedID = lineupSelections[slotID],
           let selectedPlayer = matchingPlayers.first(where: { $0.id == selectedID }) {
            return selectedPlayer
        }

        guard matchingPlayers.indices.contains(occurrence) else { return nil }

        let selectedForOtherSlots = Set(
            lineupSelections
                .filter { $0.key != slotID }
                .map(\.value)
        )
        let defaultPlayer = matchingPlayers[occurrence]
        if !selectedForOtherSlots.contains(defaultPlayer.id) {
            return defaultPlayer
        }

        return matchingPlayers.first { !selectedForOtherSlots.contains($0.id) }
    }

    private func lineupBinding(for slot: LineupSlot) -> Binding<String> {
        Binding(
            get: {
                player(for: slot.position, occurrence: slot.occurrence)?.id ?? ""
            },
            set: { playerID in
                selectPlayer(playerID, for: slot.id)
            }
        )
    }

    private func selectPlayer(_ playerID: String, for slotID: String) {
        var updatedSelections = lineupSelections
        updatedSelections = updatedSelections.filter { $0.value != playerID }
        updatedSelections[slotID] = playerID
        lineupSelectionText = updatedSelections
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: "|")
    }
}

private struct TeamPlayerSpot: View {
    let player: SoccerPlayer?
    let overall: Int?
    let position: String
    let portraitNumber: Int

    private var portraitName: String {
        Self.portraitNames[(portraitNumber - 1) % Self.portraitNames.count]
    }

    private static let portraitNames = [
        "PlayerFace01",
        "PlayerFace02",
        "PlayerFace03",
        "PlayerFace04",
        "PlayerFace05",
        "PlayerFace06",
        "PlayerFace07",
        "PlayerFace08",
        "PlayerFace09",
        "PlayerFace10",
        "PlayerFace11",
    ]

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(player == nil ? Color.soccerNavy : Color.soccerGreen)
                    .frame(width: 54, height: 54)
                    .overlay {
                        PlayerPhotoView(player: player, size: 50)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.soccerLime, lineWidth: 2)
                    }

                Text(position)
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.soccerLime)
                    .foregroundStyle(Color.soccerNavy)
                    .clipShape(.capsule)
            }

            Text(player?.name.split(separator: " ").last.map(String.init) ?? "Open")
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(overall.map { "\($0) OVR" } ?? "Empty spot")
                .font(.caption2)
                .foregroundStyle(player == nil ? Color.soccerCream.opacity(0.65) : Color.soccerLime)
        }
        .frame(width: 72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            player.map { "\(position), \($0.name), overall \(overall ?? $0.overall)" }
                ?? "\(position), open position"
        )
    }
}

private struct PlayerDetailSheet: View {
    let player: SoccerPlayer
    let effectiveOverall: Int
    let upgradeLevels: [String: Int]
    let totalPoints: Int
    let sellValue: Int
    let onUpgrade: (String) -> Void
    let onSell: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingSellConfirmation = false

    private var statLabels: [String] { PlayerUpgrade.statLabels(for: player) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PlayerCardView(
                        player: player,
                        effectiveOverall: effectiveOverall,
                        upgradeLevels: upgradeLevels
                    )
                    .padding(.top, 8)

                    VStack(spacing: 10) {
                        LabeledContent("Bought for", value: "\(player.cost) points")
                        LabeledContent("Sell value (15%)", value: "\(sellValue) points")
                    }
                    .padding()
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Upgrade Stats")
                            .font(.headline)
                            .fontWeight(.heavy)

                        ForEach(statLabels, id: \.self) { stat in
                            statUpgradeRow(for: stat)
                        }
                    }
                    .padding()
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 14))

                    Button(role: .destructive) {
                        isShowingSellConfirmation = true
                    } label: {
                        Text("Sell Player for \(sellValue) Points")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
            }
            .background(Color.soccerNavy)
            .foregroundStyle(Color.soccerCream)
            .navigationTitle(player.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog(
                "Sell \(player.name) for \(sellValue) points?",
                isPresented: $isShowingSellConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sell Player", role: .destructive) {
                    onSell()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func statUpgradeRow(for stat: String) -> some View {
        let level = PlayerUpgrade.level(for: player.id, stat: stat, in: upgradeLevels)
        let nextLevel = level + 1
        let cost = nextLevel <= PlayerUpgrade.maxLevel
            ? PlayerUpgrade.cost(for: player, toReachLevel: nextLevel)
            : nil

        return HStack {
            Text(stat)
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(width: 44, alignment: .leading)
            Text("Lv \(level)/\(PlayerUpgrade.maxLevel)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if let cost {
                Button("+1 for \(cost)") {
                    onUpgrade(stat)
                }
                .font(.caption)
                .fontWeight(.bold)
                .buttonStyle(.borderedProminent)
                .tint(Color.soccerGreen)
                .disabled(totalPoints < cost)
            } else {
                Text("MAX")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soccerGold)
            }
        }
    }
}

private struct SoccerFieldLines: View {
    var body: some View {
        GeometryReader { geometry in
            let lineColor = Color.soccerCream.opacity(0.38)

            ZStack {
                Rectangle()
                    .stroke(lineColor, lineWidth: 2)
                    .padding(12)

                Rectangle()
                    .fill(lineColor)
                    .frame(height: 2)

                Circle()
                    .stroke(lineColor, lineWidth: 2)
                    .frame(width: 94, height: 94)

                VStack {
                    Rectangle()
                        .stroke(lineColor, lineWidth: 2)
                        .frame(width: geometry.size.width * 0.48, height: 72)

                    Spacer()

                    Rectangle()
                        .stroke(lineColor, lineWidth: 2)
                        .frame(width: geometry.size.width * 0.48, height: 72)
                }
                .padding(.vertical, 12)
            }
        }
        .allowsHitTesting(false)
    }
}

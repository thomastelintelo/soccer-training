// LeaderboardsView.swift
// Team-rating and points leaderboards, mixing bot teams with the player.

import SwiftUI

struct LeaderboardsView: View {
    let username: String
    let totalPoints: Int
    @AppStorage("ownedPlayerIDs") private var ownedPlayerIDs = ""
    @AppStorage("playerShopDailyStockV2") private var stockText = ""
    @AppStorage("playerUpgradeLevels") private var upgradeLevelsText = ""
    @State private var hasAppeared = false

    private let requiredPositions = [
        "GK": 1, "LB": 1, "CB": 2, "RB": 1,
        "LM": 1, "CM": 2, "RM": 1, "ST": 2,
    ]

    private var ownedPlayers: [SoccerPlayer] {
        let ownedIDs = Set(ownedPlayerIDs.split(separator: "|").map(String.init))
        return PlayerCatalog.players.filter { ownedIDs.contains($0.id) }
    }

    private var hasFullTeam: Bool {
        requiredPositions.allSatisfy { position, count in
            ownedPlayers.filter { $0.position == position }.count >= count
        }
    }

    private var teamOverall: Int {
        let upgradeLevels = PlayerUpgrade.levels(from: upgradeLevelsText)
        let selectedPlayers = requiredPositions.flatMap { position, count in
            Array(
                ownedPlayers
                    .filter { $0.position == position }
                    .sorted { $0.overall > $1.overall }
                    .prefix(count)
            )
        }
        guard selectedPlayers.count == 11 else { return 0 }
        let totalOverall = selectedPlayers.reduce(0) { total, player in
            total + PlayerUpgrade.effectiveOverall(for: player, levels: upgradeLevels)
        }
        return totalOverall / selectedPlayers.count
    }

    private var teamRankings: [LeaderboardEntry] {
        let botTeamNames = [
            "CR7Fan's XI", "MessiGOAT FC", "TopBins United", "GoalMachine XI",
            "SpeedyStriker FC", "SkillMovesOnly", "FutureGOATs", "SundayBallers", "NoLookPass FC",
        ]
        var rankings = botTeamNames.enumerated().map { index, name in
            LeaderboardEntry(
                id: "team\(index + 1)",
                name: name,
                score: BotTeamGenerator.rating(seed: index, stockText: stockText)
            )
        }
        if hasFullTeam {
            rankings.append(LeaderboardEntry(id: "playerTeam", name: "\(username)'s Team", score: teamOverall))
        }
        return rankings.sorted { $0.score > $1.score }
    }

    private var pointRankings: [LeaderboardEntry] {
        var rankings = [
            LeaderboardEntry(id: "points1", name: "CR7Fan", score: 2_750),
            LeaderboardEntry(id: "points2", name: "MessiGOAT", score: 2_300),
            LeaderboardEntry(id: "points3", name: "GoalMachine", score: 1_850),
            LeaderboardEntry(id: "points4", name: "SpeedyStriker", score: 1_500),
            LeaderboardEntry(id: "points5", name: "TopBins", score: 1_200),
            LeaderboardEntry(id: "points6", name: "SkillMoves", score: 950),
            LeaderboardEntry(id: "points7", name: "GoldenBoot", score: 725),
            LeaderboardEntry(id: "eli", name: "Eli", score: 560),
            LeaderboardEntry(id: "points8", name: "PassMaster", score: 500),
            LeaderboardEntry(id: "points9", name: "FutureGOAT", score: 300),
            LeaderboardEntry(id: "noah", name: "Noah", score: 220),
            LeaderboardEntry(id: "points10", name: "SoccerKid", score: 150),
        ]

        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedUsername != "eli" && normalizedUsername != "noah" {
            rankings.append(LeaderboardEntry(id: "currentPlayer", name: username, score: totalPoints))
        }

        return rankings.sorted { $0.score > $1.score }
    }

    var body: some View {
        List {
            Section("Team Rating Leaderboard") {
                if !hasFullTeam {
                    Label(
                        "Complete your Starting 11 to add your team",
                        systemImage: "lock.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                ForEach(Array(teamRankings.enumerated()), id: \.element.id) { index, entry in
                    NavigationLink {
                        if entry.id == "playerTeam" {
                            MyTeamView()
                        } else {
                            OpponentTeamView(
                                teamName: entry.name,
                                teamOverall: entry.score,
                                seed: Int(entry.id.dropFirst(4)).map { $0 - 1 } ?? 0
                            )
                        }
                    } label: {
                        rankingRow(rank: index + 1, entry: entry, unit: "OVR")
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(x: hasAppeared ? 0 : -16)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.04), value: hasAppeared)
                }
            }

            Section("Most Points Leaderboard") {
                ForEach(Array(pointRankings.enumerated()), id: \.element.id) { index, entry in
                    rankingRow(rank: index + 1, entry: entry, unit: "points")
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(x: hasAppeared ? 0 : -16)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.04), value: hasAppeared)
                }
            }
        }
        .navigationTitle("Leaderboards")
        .onAppear {
            hasAppeared = true
        }
    }

    private func medalIcon(for rank: Int) -> (name: String, color: Color)? {
        switch rank {
        case 1: ("trophy.fill", Color.soccerGold)
        case 2: ("medal.fill", Color(white: 0.75))
        case 3: ("medal.fill", Color(red: 0.70, green: 0.45, blue: 0.2))
        default: nil
        }
    }

    private func rankingRow(rank: Int, entry: LeaderboardEntry, unit: String) -> some View {
        HStack {
            ZStack {
                Text("#\(rank)")
                    .font(.headline)
                    .opacity(medalIcon(for: rank) == nil ? 1 : 0)
                if let medal = medalIcon(for: rank) {
                    Image(systemName: medal.name)
                        .foregroundStyle(medal.color)
                        .font(.headline)
                }
            }
            .frame(width: 42)
            Text(entry.name)
                .fontWeight(entry.id == "currentPlayer" || entry.id == "playerTeam" ? .bold : .regular)
            Spacer()
            Text("\(entry.score) \(unit)")
                .fontWeight(.bold)
                .foregroundStyle(unit == "points" ? Color.soccerGreen : Color.primary)
        }
        .foregroundStyle(entry.id == "currentPlayer" || entry.id == "playerTeam" ? Color.soccerGreen : Color.primary)
    }
}

// LeaderboardsView.swift
// The points leaderboard, mixing bot entries with the signed-in player.
// Each row shows an avatar.

import SwiftUI
import UIKit

struct LeaderboardsView: View {
    let username: String
    let totalPoints: Int
    @AppStorage("profilePhoto") private var profilePhoto = ""
    @State private var hasAppeared = false

    private var ownPhoto: UIImage? {
        guard let data = Data(base64Encoded: profilePhoto) else { return nil }
        return UIImage(data: data)
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
            Section("Points Leaderboard") {
                ForEach(Array(pointRankings.enumerated()), id: \.element.id) { index, entry in
                    rankingRow(rank: index + 1, entry: entry)
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

    private func rankingRow(rank: Int, entry: LeaderboardEntry) -> some View {
        let isCurrentPlayer = entry.id == "currentPlayer"

        return HStack(spacing: 12) {
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
            .frame(width: 32)

            AvatarView(
                name: entry.name,
                photo: isCurrentPlayer ? ownPhoto : nil,
                size: 38
            )

            Text(entry.name)
                .fontWeight(isCurrentPlayer ? .bold : .regular)
            Spacer()
            Text("\(entry.score) points")
                .fontWeight(.bold)
                .foregroundStyle(Color.soccerAccent)
        }
        .foregroundStyle(isCurrentPlayer ? Color.soccerAccent : Color.primary)
    }
}

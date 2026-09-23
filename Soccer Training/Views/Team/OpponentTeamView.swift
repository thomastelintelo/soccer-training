// OpponentTeamView.swift
// Read-only lineup detail for a bot team shown on the leaderboard.

import SwiftUI

struct OpponentTeamView: View {
    let teamName: String
    let teamOverall: Int
    let seed: Int
    @AppStorage("playerShopDailyStockV2") private var stockText = ""

    private let positions = BotTeamGenerator.positions

    private var lineup: [SoccerPlayer] {
        BotTeamGenerator.lineup(seed: seed, stockText: stockText)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.soccerGreen)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(teamName)
                            .font(.title2)
                            .fontWeight(.heavy)
                        Text("Team Overall: \(teamOverall)")
                            .foregroundStyle(Color.soccerGreen)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Starting 11") {
                ForEach(Array(positions.enumerated()), id: \.offset) { index, position in
                    let player = lineup[index]

                    HStack(spacing: 14) {
                        PlayerPhotoView(player: player, size: 52)
                            .overlay {
                                Circle()
                                    .stroke(Color.soccerGreen, lineWidth: 2)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(player.name)
                                .fontWeight(.bold)
                            Text(position)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(player.overall)")
                            .font(.headline)
                            .foregroundStyle(Color.soccerGreen)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.soccerNavy)
        .navigationTitle(teamName)
        .navigationBarTitleDisplayMode(.inline)
    }

}

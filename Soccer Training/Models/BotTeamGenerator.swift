// BotTeamGenerator.swift
// Deterministically builds an opposing team's lineup and rating from a seed,
// used by both the leaderboard and the opponent team detail view.

enum BotTeamGenerator {
    static let positions = ["GK", "LB", "CB", "CB", "RB", "LM", "CM", "CM", "RM", "ST", "ST"]

    static func lineup(seed: Int, stockText: String) -> [SoccerPlayer] {
        let availableIDs: Set<String> = Set(
            stockText.split(separator: "|").compactMap { entry -> String? in
                let parts = entry.split(separator: ":")
                guard parts.count == 2, let count = Int(parts[1]), count > 0 else { return nil }
                return String(parts[0])
            }
        )

        var strongPlayersUsed = 0
        var selectedPlayers: [SoccerPlayer] = []

        for (slotIndex, position) in positions.enumerated() {
            let candidates = PlayerCatalog.players.filter { player in
                guard player.position == position && player.id != "yamal" else { return false }
                if player.overall <= 78 {
                    return true
                }
                return strongPlayersUsed < 2 && availableIDs.contains(player.id)
            }
            let samePositionBefore = positions.prefix(slotIndex).filter { $0 == position }.count
            guard !candidates.isEmpty else { continue }

            let player = candidates[(seed + samePositionBefore) % candidates.count]
            selectedPlayers.append(player)
            if player.overall > 78 {
                strongPlayersUsed += 1
            }
        }

        return selectedPlayers
    }

    static func rating(seed: Int, stockText: String) -> Int {
        let players = lineup(seed: seed, stockText: stockText)
        guard players.count == positions.count else { return 0 }
        return players.map(\.overall).reduce(0, +) / players.count
    }
}

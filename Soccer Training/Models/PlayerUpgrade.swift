// PlayerUpgrade.swift
// Per-stat upgrade levels for owned players: each of a player's 6 card stats
// (PAC/SHO/PAS/DRI/DEF/PHY, or the GK equivalents) can be leveled up to 3
// times independently, each level costing progressively more points.

import Foundation

enum PlayerUpgrade {
    static let maxLevel = 3
    static let statLabels = ["PAC", "SHO", "PAS", "DRI", "DEF", "PHY"]
    static let goalkeeperStatLabels = ["DIV", "HAN", "KIC", "REF", "SPD", "POS"]

    static func statLabels(for player: SoccerPlayer) -> [String] {
        player.position == "GK" ? goalkeeperStatLabels : statLabels
    }

    /// Points required to reach `level` on a single stat, expressed as a
    /// fraction of the player's cost (dividing by 6 keeps the total spend to
    /// fully max every stat roughly equivalent to the old single-dial system).
    static func costMultiplier(forLevel level: Int) -> Double {
        switch level {
        case 1: 1.15
        case 2: 1.25
        case 3: 1.40
        default: 0
        }
    }

    static func cost(for player: SoccerPlayer, toReachLevel level: Int) -> Int {
        let rawCost = Double(player.cost) * costMultiplier(forLevel: level) / 6
        return max(10, Int((rawCost / 10).rounded()) * 10)
    }

    static func level(for playerID: String, stat: String, in levels: [String: Int]) -> Int {
        levels["\(playerID):\(stat)"] ?? 0
    }

    /// Sum of every stat's level for a player, used for a compact badge and
    /// for nudging overall rating up as a player's card is filled out.
    static func totalLevels(for playerID: String, in levels: [String: Int]) -> Int {
        levels.filter { $0.key.hasPrefix("\(playerID):") }.values.reduce(0, +)
    }

    static func effectiveOverall(for player: SoccerPlayer, levels: [String: Int]) -> Int {
        player.overall + totalLevels(for: player.id, in: levels) / 3
    }

    /// Keys are "playerID:STAT" mapped to level (1...maxLevel).
    static func levels(from text: String) -> [String: Int] {
        var levels: [String: Int] = [:]

        for entry in text.split(separator: "|") {
            let parts = entry.split(separator: ":")
            if parts.count == 3, let level = Int(parts[2]) {
                levels["\(parts[0]):\(parts[1])"] = level
            } else if parts.count == 2, let level = Int(parts[1]) {
                // Legacy "id:level" format from the old single-overall-dial
                // upgrade system. Apply the same level to every stat once so
                // players who'd already upgraded don't lose that progress.
                let playerID = String(parts[0])
                let isGoalkeeper = PlayerCatalog.players.first(where: { $0.id == playerID })?.position == "GK"
                for stat in isGoalkeeper ? goalkeeperStatLabels : statLabels {
                    levels["\(playerID):\(stat)"] = level
                }
            }
        }

        return levels
    }

    static func encode(_ levels: [String: Int]) -> String {
        levels
            .filter { $0.value > 0 }
            .map { "\($0.key):\($0.value)" }
            .sorted()
            .joined(separator: "|")
    }
}

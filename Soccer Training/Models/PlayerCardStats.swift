// PlayerCardStats.swift
// Derives FIFA-card-style sub-stats (PAC/SHO/PAS/DRI/DEF/PHY, or goalkeeper
// equivalents) from a player's overall and position. Values are deterministic
// per player — based on a stable string hash, not Swift's randomized Hasher —
// so a card looks the same every time it's shown, including after a relaunch.

import Foundation

struct PlayerCardStat: Identifiable {
    var id: String { label }
    let label: String
    let value: Int
}

enum PlayerCardStats {
    static func stats(
        for player: SoccerPlayer,
        effectiveOverall: Int,
        levels: [String: Int] = [:]
    ) -> [PlayerCardStat] {
        func upgrade(_ label: String) -> Int {
            PlayerUpgrade.level(for: player.id, stat: label, in: levels)
        }

        if player.position == "GK" {
            return [
                stat("DIV", base: effectiveOverall, weight: 2, seed: player.id + "DIV", upgrade: upgrade("DIV")),
                stat("HAN", base: effectiveOverall, weight: 1, seed: player.id + "HAN", upgrade: upgrade("HAN")),
                stat("KIC", base: effectiveOverall, weight: -4, seed: player.id + "KIC", upgrade: upgrade("KIC")),
                stat("REF", base: effectiveOverall, weight: 3, seed: player.id + "REF", upgrade: upgrade("REF")),
                stat("SPD", base: effectiveOverall, weight: -10, seed: player.id + "SPD", upgrade: upgrade("SPD")),
                stat("POS", base: effectiveOverall, weight: 2, seed: player.id + "POS", upgrade: upgrade("POS")),
            ]
        }

        let weights = positionWeights(for: player.position)
        return [
            stat("PAC", base: effectiveOverall, weight: weights.pace, seed: player.id + "PAC", upgrade: upgrade("PAC")),
            stat("SHO", base: effectiveOverall, weight: weights.shooting, seed: player.id + "SHO", upgrade: upgrade("SHO")),
            stat("PAS", base: effectiveOverall, weight: weights.passing, seed: player.id + "PAS", upgrade: upgrade("PAS")),
            stat("DRI", base: effectiveOverall, weight: weights.dribbling, seed: player.id + "DRI", upgrade: upgrade("DRI")),
            stat("DEF", base: effectiveOverall, weight: weights.defending, seed: player.id + "DEF", upgrade: upgrade("DEF")),
            stat("PHY", base: effectiveOverall, weight: weights.physical, seed: player.id + "PHY", upgrade: upgrade("PHY")),
        ]
    }

    private struct PositionWeights {
        let pace: Int
        let shooting: Int
        let passing: Int
        let dribbling: Int
        let defending: Int
        let physical: Int
    }

    private static func positionWeights(for position: String) -> PositionWeights {
        switch position {
        case "ST":
            PositionWeights(pace: 4, shooting: 7, passing: -4, dribbling: 2, defending: -12, physical: 2)
        case "LM", "RM":
            PositionWeights(pace: 6, shooting: 0, passing: 2, dribbling: 6, defending: -9, physical: -4)
        case "CM":
            PositionWeights(pace: -2, shooting: -3, passing: 7, dribbling: 2, defending: 0, physical: 0)
        case "LB", "RB":
            PositionWeights(pace: 4, shooting: -9, passing: 0, dribbling: 0, defending: 4, physical: 0)
        case "CB":
            PositionWeights(pace: -5, shooting: -12, passing: -5, dribbling: -7, defending: 8, physical: 5)
        default:
            PositionWeights(pace: 0, shooting: 0, passing: 0, dribbling: 0, defending: 0, physical: 0)
        }
    }

    private static func stat(_ label: String, base: Int, weight: Int, seed: String, upgrade: Int = 0) -> PlayerCardStat {
        let noise = stableHash(seed) % 7 - 3
        let value = min(99, max(35, base + weight + noise + upgrade))
        return PlayerCardStat(label: label, value: value)
    }

    /// A simple, stable string hash (djb2). Swift's built-in `Hasher` is seeded
    /// randomly per process, so it can't be used here without stats changing
    /// on every app launch.
    private static func stableHash(_ string: String) -> Int {
        var hash = 5381
        for scalar in string.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return abs(hash)
    }
}

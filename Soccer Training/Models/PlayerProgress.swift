// PlayerProgress.swift
// A player's level, derived from total XP. Centralizes the level formula that
// used to be duplicated inline in both ProfileView and DrillTimerView, so the
// two screens can never disagree on what level a given XP total means.

import Foundation

struct PlayerProgress {
    static let xpPerLevel = 500

    let xp: Int

    var level: Int { xp / Self.xpPerLevel + 1 }

    var levelTitle: String {
        switch level {
        case 1...4: "Developing Player"
        case 5...9: "Rising Player"
        case 10...19: "Strong Player"
        default: "Futbol Elite"
        }
    }

    var xpIntoLevel: Int { xp % Self.xpPerLevel }
    var xpUntilNextLevel: Int { Self.xpPerLevel - xpIntoLevel }
    var progressToNextLevel: Double { Double(xpIntoLevel) / Double(Self.xpPerLevel) }

}

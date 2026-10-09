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

    /// The highest rank unlocked at the current level.
    var rank: PlayerRank { PlayerRank.all.last { level >= $0.minLevel } ?? PlayerRank.all[0] }

    /// The next rank still locked, or nil once the top rank is reached.
    var nextRank: PlayerRank? { PlayerRank.all.first { level < $0.minLevel } }

    /// 0...1 progress from the current rank's level toward the next rank's level.
    var progressToNextRank: Double {
        guard let next = nextRank else { return 1 }
        let span = Double(next.minLevel - rank.minLevel)
        let done = Double(level - rank.minLevel) + progressToNextLevel
        return min(1, max(0, done / span))
    }

    var xpIntoLevel: Int { xp % Self.xpPerLevel }
    var xpUntilNextLevel: Int { Self.xpPerLevel - xpIntoLevel }
    var progressToNextLevel: Double { Double(xpIntoLevel) / Double(Self.xpPerLevel) }

    /// UserDefaults keys that hold a player's training progress.
    private static let storedKeys = [
        "playerXP", "totalPoints", "categoryXP", "categoryMinutes", "totalTrainingMinutes",
        "totalGoals", "totalShots", "totalPasses", "totalDribblingAttempts", "totalControls",
        "totalSessions", "trainingStreak", "lastTrainingDate", "completedWeeklyTasks",
        "completedWeeklyDays", "weeklyDrillSubstitutions", "weeklyProgressStart",
        "seenAchievements", "soccerTestBests", "drillBests", "personalBestCount", "weeklyLog", "goalDrills", "goalMinutes", "goalAccuracy", "soccerTestAttempts",
    ]

    /// Wipes all saved progress. Called when a player signs out.
    static func resetStoredProgress() {
        for key in storedKeys { UserDefaults.standard.removeObject(forKey: key) }
    }
}

/// An unlockable rank earned by reaching a level.
struct PlayerRank: Identifiable {
    let name: String
    let minLevel: Int
    let systemImage: String

    var id: String { name }

    static let all: [PlayerRank] = [
        PlayerRank(name: "Rookie", minLevel: 1, systemImage: "figure.walk"),
        PlayerRank(name: "Bronze", minLevel: 3, systemImage: "shield.fill"),
        PlayerRank(name: "Silver", minLevel: 6, systemImage: "shield.lefthalf.filled"),
        PlayerRank(name: "Gold", minLevel: 10, systemImage: "medal.fill"),
        PlayerRank(name: "Platinum", minLevel: 15, systemImage: "star.circle.fill"),
        PlayerRank(name: "Diamond", minLevel: 20, systemImage: "diamond.fill"),
        PlayerRank(name: "Legend", minLevel: 30, systemImage: "crown.fill"),
    ]
}

/// Turns saved test results into stat bonuses and awards XP for taking tests.
enum TestProgression {
    static let attemptXP = 15
    static let firstResultXP = 100
    static let personalBestXP = 50

    /// Test category -> training category that receives the XP.
    static func trainingCategory(for testCategory: String) -> String {
        testCategory == "Fitness" ? "Workout" : testCategory
    }

    /// How close a result is to the test target (0...1, capped at 1).
    static func score(_ test: SoccerTest, best: Double) -> Double {
        guard best > 0, test.target > 0 else { return 0 }
        let ratio = test.lowerIsBetter ? test.target / best : best / test.target
        return min(1, ratio)
    }

    /// Rating bonus (0...12) from the average score of completed tests in the
    /// given test categories. Beating targets in more tests raises the stat.
    static func ratingBonus(forTestCategories categories: [String], bests: [String: Double]) -> Int {
        let scores = SoccerTestCatalog.all
            .filter { categories.contains($0.category) }
            .compactMap { test in bests[test.id].map { score(test, best: $0) } }
        guard !scores.isEmpty else { return 0 }
        return Int((scores.reduce(0, +) / Double(scores.count) * 12).rounded())
    }
}

/// Personal bests for drills (most successes recorded in one session),
/// persisted as JSON under "drillBests".
enum DrillBests {
    static func decode(_ text: String) -> [String: Int] {
        guard let data = text.data(using: .utf8),
              let values = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
        return values
    }

    static func encode(_ values: [String: Int]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }
}

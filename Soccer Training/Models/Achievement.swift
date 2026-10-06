// Achievement.swift
// A single unlockable milestone (badge), shown on the Progress and Profile tabs.
// The full list lives here so both screens always show the same badges and the
// same unlock rules.

import Foundation

struct Achievement: Identifiable {
    let title: String
    let detail: String
    let systemImage: String
    let isUnlocked: Bool

    var id: String { title }

    static func catalog(
        totalGoals: Int,
        totalSessions: Int,
        sessionsCompleted: Int,
        trainingStreak: Int,
        totalPoints: Int,
        level: Int,
        soccerIQXP: Int
    ) -> [Achievement] {
        [
            Achievement(title: "First Goal", detail: "Score your first training goal", systemImage: "soccerball", isUnlocked: totalGoals >= 1),
            Achievement(title: "Goal Getter", detail: "Score 50 training goals", systemImage: "scope", isUnlocked: totalGoals >= 50),
            Achievement(title: "Session Finisher", detail: "Complete your first full session", systemImage: "checkmark.seal.fill", isUnlocked: sessionsCompleted >= 1),
            Achievement(title: "Session Regular", detail: "Complete 10 full sessions", systemImage: "list.bullet.clipboard.fill", isUnlocked: sessionsCompleted >= 10),
            Achievement(title: "Getting Started", detail: "Complete 5 drills", systemImage: "figure.run", isUnlocked: totalSessions >= 5),
            Achievement(title: "Dedicated", detail: "Complete 25 drills", systemImage: "figure.run.circle.fill", isUnlocked: totalSessions >= 25),
            Achievement(title: "On a Roll", detail: "Reach a 3-day streak", systemImage: "flame.fill", isUnlocked: trainingStreak >= 3),
            Achievement(title: "Unstoppable", detail: "Reach a 7-day streak", systemImage: "flame.circle.fill", isUnlocked: trainingStreak >= 7),
            Achievement(title: "Month Strong", detail: "Reach a 30-day streak", systemImage: "calendar.badge.clock", isUnlocked: trainingStreak >= 30),
            Achievement(title: "Point Collector", detail: "Hold 1,000 points", systemImage: "star.fill", isUnlocked: totalPoints >= 1_000),
            Achievement(title: "High Roller", detail: "Hold 10,000 points", systemImage: "star.circle.fill", isUnlocked: totalPoints >= 10_000),
            Achievement(title: "Level Five", detail: "Reach level 5", systemImage: "trophy.fill", isUnlocked: level >= 5),
            Achievement(title: "Elite Trainer", detail: "Reach level 15", systemImage: "crown.fill", isUnlocked: level >= 15),
            Achievement(title: "Game Intelligence", detail: "Earn 200 Soccer IQ XP", systemImage: "brain.head.profile", isUnlocked: soccerIQXP >= 200),
        ]
    }
}

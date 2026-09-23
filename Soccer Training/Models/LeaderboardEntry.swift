// LeaderboardEntry.swift
// A single ranked row on the team-rating or points leaderboard.

struct LeaderboardEntry: Identifiable {
    let id: String
    let name: String
    let score: Int
}

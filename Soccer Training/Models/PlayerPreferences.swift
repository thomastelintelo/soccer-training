// PlayerPreferences.swift
// What the player told us about themselves during onboarding and can change in
// Profile: age, position, level, goals, equipment, and time to train. The AI
// coach and the Home recommendations read these. Values are stored under the
// same keys the app already used (playerUsername, playerPosition, playerBestSkill),
// so existing players keep their details.

import Foundation

enum PlayerPrefKey {
    /// Bumped whenever preferences change, so views that read them redraw.
    static let revision = "playerPreferencesRevision"
    static let age = "playerAge"
    static let skillLevel = "playerSkillLevel"
    static let goals = "playerGoals"
    static let equipment = "playerEquipment"
    static let indoorOnly = "playerIndoorOnly"
    static let trainingMinutes = "playerTrainingMinutes"
    static let trainingDays = "playerTrainingDays"
}

struct PlayerPreferences: Equatable {
    static let positions = ["Goalkeeper", "Defender", "Midfielder", "Winger", "Striker"]
    static let bestSkills = ["Control", "Passing", "Shooting", "Dribbling"]
    static let trainingMinuteOptions = [15, 20, 30, 45, 60]
    static let trainingDayOptions = [2, 3, 4, 5, 6, 7]

    /// 0 means the player hasn't said.
    var age: Int
    var position: String
    var bestSkill: String
    var level: DrillLevel
    var goals: [String]
    var equipment: EquipmentNeeds
    var indoorOnly: Bool
    var trainingMinutes: Int
    var trainingDays: Int

    static func load(_ defaults: UserDefaults = .standard) -> PlayerPreferences {
        let minutes = defaults.integer(forKey: PlayerPrefKey.trainingMinutes)
        let days = defaults.integer(forKey: PlayerPrefKey.trainingDays)
        return PlayerPreferences(
            age: defaults.integer(forKey: PlayerPrefKey.age),
            position: defaults.string(forKey: "playerPosition") ?? "",
            bestSkill: defaults.string(forKey: "playerBestSkill") ?? "",
            level: DrillLevel(rawValue: defaults.string(forKey: PlayerPrefKey.skillLevel) ?? "") ?? .beginner,
            goals: PipeList.decode(defaults.string(forKey: PlayerPrefKey.goals) ?? ""),
            equipment: EquipmentNeeds.from(tokens: PipeList.decode(defaults.string(forKey: PlayerPrefKey.equipment) ?? "ball")),
            indoorOnly: defaults.bool(forKey: PlayerPrefKey.indoorOnly),
            trainingMinutes: minutes > 0 ? minutes : 30,
            trainingDays: days > 0 ? days : 4
        )
    }

    /// Positions the coach should lean toward when no position is known.
    static func defaultSkills(forPosition position: String) -> [String] {
        switch position {
        case "Goalkeeper": ["Goalkeeping", "Control", "Passing"]
        case "Defender": ["Defense", "Passing", "Control"]
        case "Midfielder": ["Passing", "Control", "Dribbling"]
        case "Winger": ["Dribbling", "Shooting", "Control"]
        case "Striker": ["Shooting", "Control", "Dribbling"]
        default: ["Control", "Passing", "Dribbling"]
        }
    }
}

/// Helpers for the pipe-separated lists the app stores in @AppStorage strings.
enum PipeList {
    static func decode(_ text: String) -> [String] {
        text.split(separator: "|").map(String.init).filter { !$0.isEmpty }
    }

    static func encode(_ items: some Sequence<String>) -> String {
        Array(Set(items)).sorted().joined(separator: "|")
    }
}

enum FavoriteDrills {
    static let storageKey = "favoriteDrillNames"

    static func set(from text: String) -> Set<String> {
        Set(PipeList.decode(text))
    }

    static func toggled(_ name: String, in text: String) -> String {
        var names = set(from: text)
        if names.contains(name) {
            names.remove(name)
        } else {
            names.insert(name)
        }
        return PipeList.encode(names)
    }
}

extension EquipmentNeeds {
    /// The stored tokens for the equipment labels a player picked, e.g. "Cones" -> "cones".
    static func tokens(forLabels labels: Set<String>) -> [String] {
        options.filter { labels.contains($0.label) }.map(\.token)
    }

    /// The labels to show for stored tokens.
    static func labels(forTokens tokens: [String]) -> Set<String> {
        Set(options.filter { tokens.contains($0.token) }.map(\.label))
    }
}

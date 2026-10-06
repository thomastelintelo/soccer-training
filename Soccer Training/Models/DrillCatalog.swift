// DrillCatalog.swift
// The single source of truth for the drill library. Every drill's skill, level,
// duration, equipment, player count, and age and position fit is derived here,
// so the library, filters, detail pages, and the AI coach all read the same data.
//
// Equipment and duration come straight from the existing drill content.
// Player count, age, and position are inferred from each drill's category,
// name, and equipment list. They are estimates meant to steer filtering and
// recommendations, not coaching facts.

import Foundation

/// How hard a drill is for the player, relative to the other drills in its topic.
enum DrillLevel: String, CaseIterable, Identifiable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    /// Position on a 0...2 scale, used to score how close a drill is to a player's level.
    var rank: Int {
        switch self {
        case .beginner: 0
        case .intermediate: 1
        case .advanced: 2
        }
    }
}

/// Equipment a drill needs beyond the ball, which every drill assumes.
struct EquipmentNeeds: OptionSet, Hashable {
    let rawValue: Int

    static let cones = EquipmentNeeds(rawValue: 1 << 0)
    static let wall = EquipmentNeeds(rawValue: 1 << 1)
    static let partner = EquipmentNeeds(rawValue: 1 << 2)
    static let goal = EquipmentNeeds(rawValue: 1 << 3)
    static let gloves = EquipmentNeeds(rawValue: 1 << 4)

    /// Every option, in the order the UI shows them.
    static let options: [(need: EquipmentNeeds, token: String, label: String, icon: String)] = [
        (.cones, "cones", "Cones", "triangle.fill"),
        (.wall, "wall", "Wall", "rectangle.fill"),
        (.partner, "partner", "Partner", "person.2.fill"),
        (.goal, "goal", "Goal", "sportscourt.fill"),
        (.gloves, "gloves", "Gloves", "hand.raised.fill"),
    ]

    var labels: [String] {
        Self.options.filter { contains($0.need) }.map(\.label)
    }

    var tokens: [String] {
        Self.options.filter { contains($0.need) }.map(\.token)
    }

    static func from(tokens: [String]) -> EquipmentNeeds {
        var result: EquipmentNeeds = []
        for option in options where tokens.contains(option.token) {
            result.insert(option.need)
        }
        return result
    }
}

/// Who a drill needs to train with.
enum PlayerCount: String, CaseIterable, Identifiable {
    case solo = "Solo"
    case partner = "With a partner"
    case group = "Small group"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .solo: "person.fill"
        case .partner: "person.2.fill"
        case .group: "person.3.fill"
        }
    }
}

struct DrillInfo: Identifiable {
    let name: String
    /// The Drills tab topic this drill is listed under.
    let topic: String
    /// The skill it trains (e.g. "Dribbling"), from DrillPresentation.
    let skill: String
    let durationSeconds: Int
    let level: DrillLevel
    let equipment: EquipmentNeeds
    let equipmentText: String
    let playerCount: PlayerCount
    /// 0 means suitable for any age.
    let minimumAge: Int
    /// Positions the drill suits best. Empty means every position.
    let positions: [String]
    let isIndoor: Bool

    var id: String { name }
    var minutes: Int { durationSeconds / 60 }
}

enum DrillCatalog {
    /// Skills a player can train, in the order the UI lists them.
    static let skills = [
        "Shooting", "Dribbling", "Passing", "Control", "First Touch", "Technique",
        "Speed & Finishing", "Soccer IQ", "Goalkeeping", "Defense", "Workout", "Plus Training",
    ]

    static let positions = ["Goalkeeper", "Defender", "Midfielder", "Winger", "Striker"]

    /// The 184 drills in the Drills library.
    static let library: [DrillInfo] = DrillTopics.all.flatMap { topic -> [DrillInfo] in
        let levels = levelsByName(topic.drills.map(\.name))
        return topic.drills.map { drill in
            makeInfo(name: drill.name, topic: topic.name, level: levels[drill.name] ?? .beginner)
        }
    }

    private static let byName: [String: DrillInfo] = Dictionary(
        uniqueKeysWithValues: library.map { ($0.name, $0) }
    )

    /// Details for any drill the app can open. Session templates use a few drills
    /// that are not in the library, so those are described on demand.
    static func info(for name: String) -> DrillInfo {
        byName[name] ?? makeInfo(name: name, topic: DrillPresentation.category(for: name), level: .intermediate)
    }

    static func skill(for name: String) -> String {
        DrillPresentation.category(for: name)
    }

    // MARK: - Filtering helpers

    /// Whether `needs` can be met with the equipment the player owns.
    static func canUse(_ info: DrillInfo, owned: EquipmentNeeds) -> Bool {
        info.equipment.isSubset(of: owned)
    }

    // MARK: - Derivation

    /// Buckets a topic's drills into thirds by duration. Ties are broken by a
    /// stable hash so drills of the same length don't all land in one bucket.
    private static func levelsByName(_ names: [String]) -> [String: DrillLevel] {
        let sorted = names.sorted { lhs, rhs in
            let left = DrillTimerView.duration(for: lhs)
            let right = DrillTimerView.duration(for: rhs)
            if left != right { return left < right }
            return StableHash.value(lhs) < StableHash.value(rhs)
        }

        var result: [String: DrillLevel] = [:]
        let count = Double(sorted.count)
        for (index, name) in sorted.enumerated() {
            let fraction = Double(index) / count
            if fraction < 1.0 / 3.0 {
                result[name] = .beginner
            } else if fraction < 2.0 / 3.0 {
                result[name] = .intermediate
            } else {
                result[name] = .advanced
            }
        }
        return result
    }

    private static func makeInfo(name: String, topic: String, level: DrillLevel) -> DrillInfo {
        let skill = DrillPresentation.category(for: name)
        let equipmentText = DrillPresentation.equipment(for: name, category: skill)
        let equipment = equipmentNeeds(from: equipmentText)

        return DrillInfo(
            name: name,
            topic: topic,
            skill: skill,
            durationSeconds: DrillTimerView.duration(for: name),
            level: level,
            equipment: equipment,
            equipmentText: equipmentText,
            playerCount: playerCount(for: name, equipment: equipment),
            minimumAge: skill == "Plus Training" ? 14 : (level == .advanced ? 12 : 0),
            positions: positions(for: skill),
            isIndoor: DrillPresentation.isIndoor(name)
        )
    }

    /// Reads the free-text equipment line for the items it requires. Phrases such
    /// as "or partner", "or marked target", and "when instructed" mark optional
    /// items, so they don't rule a drill out.
    static func equipmentNeeds(from text: String) -> EquipmentNeeds {
        let lower = text.lowercased()
        if lower.contains("no equipment") { return [] }

        var needs: EquipmentNeeds = []
        if lower.contains("cone") || lower.contains("gate") {
            needs.insert(.cones)
        }
        if lower.contains("wall") && !lower.contains("or partner") {
            needs.insert(.wall)
        }
        if lower.contains("partner") && !lower.contains("or partner") && !lower.contains("when instructed") {
            needs.insert(.partner)
        }
        if lower.contains("goal") && !lower.contains("or marked target") && !lower.contains("when instructed") {
            needs.insert(.goal)
        }
        if lower.contains("glove") {
            needs.insert(.gloves)
        }
        return needs
    }

    private static func playerCount(for name: String, equipment: EquipmentNeeds) -> PlayerCount {
        let groupWords = ["Possession", "Triangle", "Four Corner", "Overload", "Transition", "Compact Line", "Zonal", "Double Team"]
        if groupWords.contains(where: { name.localizedCaseInsensitiveContains($0) }) {
            return .group
        }

        let partnerWords = [
            "1v1", "v One", "Shadow", "Save", "Parry", "Catch", "Collection", "Tackle", "Jockey",
            "Close Down", "Block", "Cover", "Delay", "Last Man", "Show Inside", "Mark Tight",
            "Goalkeeper", "Command the Box", "Attacker",
        ]
        if equipment.contains(.partner) || partnerWords.contains(where: { name.localizedCaseInsensitiveContains($0) }) {
            return .partner
        }
        return .solo
    }

    private static func positions(for skill: String) -> [String] {
        switch skill {
        case "Goalkeeping": ["Goalkeeper"]
        case "Defense": ["Defender", "Midfielder"]
        case "Shooting", "Speed & Finishing": ["Striker", "Winger"]
        case "Dribbling", "Technique": ["Winger", "Striker", "Midfielder"]
        default: []
        }
    }
}

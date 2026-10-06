// CoachPlanner.swift
// The AI coach. It reads a plain-English request ("I'm a 14-year-old winger, 30
// minutes, one ball and four cones, dribbling and weak foot"), turns it into
// constraints, and builds a session from drills that already exist in the
// library. It never invents a drill: every step comes from DrillCatalog.
//
// The planner is rule-based and runs entirely on-device, so it works offline and
// with no API key. It is the seam where a language model could later rank or
// reword plans, as long as the model only chooses from DrillCatalog.library.

import Foundation

struct CoachRequest: Equatable {
    var minutes: Int
    /// Skills to focus on, most important first.
    var skills: [String]
    var position: String?
    var age: Int?
    var level: DrillLevel
    /// Equipment the player has, beyond the ball.
    var equipment: EquipmentNeeds
    var indoorOnly: Bool
    var weakFoot: Bool
}

struct CoachPlan {
    let title: String
    let drills: [DrillInfo]
    let steps: [SessionStep]
    let totalMinutes: Int
    /// One short line per drill, explaining why it was picked.
    let reasons: [String: String]
    /// Anything the player should know, such as a request that couldn't be fully met.
    let notes: [String]
    /// Skills the session covers, in the order the player asked for them.
    let focus: [String]

    var session: ActiveSession {
        ActiveSession(title: title, steps: steps)
    }
}

enum CoachPlanner {
    static let warmUpName = "Dynamic Warm Up"
    static let coolDownName = "Cool Down Stretch"

    // MARK: - Reading a request

    /// The request the player's saved preferences imply, with no text typed.
    static func defaultRequest(for preferences: PlayerPreferences) -> CoachRequest {
        CoachRequest(
            minutes: preferences.trainingMinutes,
            skills: preferences.goals.isEmpty
                ? PlayerPreferences.defaultSkills(forPosition: preferences.position)
                : preferences.goals,
            position: preferences.position.isEmpty ? nil : preferences.position,
            age: preferences.age > 0 ? preferences.age : nil,
            level: preferences.level,
            equipment: preferences.equipment,
            indoorOnly: preferences.indoorOnly,
            weakFoot: false
        )
    }

    /// Fills in anything the text doesn't mention from the player's preferences.
    static func request(from text: String, preferences: PlayerPreferences) -> CoachRequest {
        let lower = text.lowercased()
        var request = defaultRequest(for: preferences)

        if let minutes = minutes(in: lower) { request.minutes = minutes }
        if let age = age(in: lower) { request.age = age }
        if let position = position(in: lower) { request.position = position }
        if let level = level(in: lower) { request.level = level }
        if let equipment = equipment(in: lower) { request.equipment = equipment }
        if lower.contains("indoor") || lower.contains("small space") || lower.contains("garage") {
            request.indoorOnly = true
        }
        request.weakFoot = lower.contains("weak foot") || lower.contains("weaker foot") || lower.contains("other foot")

        let mentioned = skills(in: lower)
        if !mentioned.isEmpty {
            request.skills = mentioned
        }
        return request
    }

    private static func minutes(in lower: String) -> Int? {
        if let match = lower.firstMatch(of: #/(\d{1,3})\s*(?:minutes|minute|mins|min)\b/#), let value = Int(match.1) {
            return min(max(value, 10), 120)
        }
        if let match = lower.firstMatch(of: #/(\d)\s*(?:hours|hour|hr)\b/#), let value = Int(match.1) {
            return min(value * 60, 120)
        }
        return nil
    }

    private static func age(in lower: String) -> Int? {
        if let match = lower.firstMatch(of: #/(\d{1,2})\s*[- ]?\s*(?:years?|yrs?|yo|y/o)\b/#), let value = Int(match.1), (5...80).contains(value) {
            return value
        }
        if let match = lower.firstMatch(of: #/(?:i'?m|i am|age|aged)\s*(\d{1,2})\b/#), let value = Int(match.1), (5...80).contains(value) {
            return value
        }
        return nil
    }

    private static func position(in lower: String) -> String? {
        if lower.contains("goalkeeper") || lower.contains("goalie") || lower.contains("keeper") {
            return "Goalkeeper"
        }
        if lower.contains("winger") || lower.contains("wing ") || lower.contains("wide player") {
            return "Winger"
        }
        if lower.contains("defender") || lower.contains("center back") || lower.contains("centre back")
            || lower.contains("full back") || lower.contains("fullback") {
            return "Defender"
        }
        if lower.contains("midfield") || lower.contains("playmaker") {
            return "Midfielder"
        }
        if lower.contains("striker") || lower.contains("forward") || lower.contains("center forward") {
            return "Striker"
        }
        return nil
    }

    private static func level(in lower: String) -> DrillLevel? {
        if lower.contains("beginner") || lower.contains("just started") || lower.contains("new to")
            || lower.contains("starting out") {
            return .beginner
        }
        if lower.contains("intermediate") {
            return .intermediate
        }
        if lower.contains("advanced") || lower.contains("elite") || lower.contains("experienced")
            || lower.contains("competitive") {
            return .advanced
        }
        return nil
    }

    /// Equipment the player mentions. If they mention none, the saved equipment applies.
    private static func equipment(in lower: String) -> EquipmentNeeds? {
        if lower.contains("no equipment") || lower.contains("bodyweight") || lower.contains("nothing but") {
            return []
        }

        var found: EquipmentNeeds = []
        if lower.contains("cone") || lower.contains("marker") || lower.contains("gate") {
            found.insert(.cones)
        }
        if lower.contains("wall") {
            found.insert(.wall)
        }
        if lower.contains("partner") || lower.contains("friend") || lower.contains("teammate") || lower.contains("buddy") {
            found.insert(.partner)
        }
        if lower.contains(#/\bgoals?\b/#) {
            found.insert(.goal)
        }
        if lower.contains("glove") {
            found.insert(.gloves)
        }
        return found.isEmpty ? nil : found
    }

    /// Skills mentioned in the text, ordered by where they first appear, so
    /// "dribbling and passing" puts dribbling first.
    private static func skills(in lower: String) -> [String] {
        let keywords: [(skill: String, words: [String])] = [
            ("Dribbling", ["dribbl", "1v1", "one v one", "take on", "close control", "ball control"]),
            ("Shooting", ["shoot", "finish", "strik", "scoring"]),
            ("Passing", ["pass", "switch play", "crossing"]),
            ("First Touch", ["first touch", "receiv", "settle"]),
            ("Control", ["control", "juggl", "touches", "ball mastery"]),
            ("Technique", ["skill move", "trick", "technique", "flick", "spin", "step over", "rainbow"]),
            ("Defense", ["defend", "defence", "tackl", "jockey", "marking", "pressing"]),
            ("Goalkeeping", ["keeper", "goalkeep", "saves", "diving", "handling", "distribution"]),
            ("Speed & Finishing", ["speed", "sprint", "agility", "quick feet", "explosive"]),
            ("Soccer IQ", ["awareness", "scan", "decision", "game intelligence", "soccer iq", "reading the game", "vision"]),
            ("Workout", ["fitness", "conditioning", "strength", "stamina", "endurance", "core workout", "core strength"]),
        ]

        var found: [(skill: String, position: String.Index)] = []
        for keyword in keywords {
            let positions = keyword.words.compactMap { lower.range(of: $0)?.lowerBound }
            if let first = positions.min() {
                found.append((keyword.skill, first))
            }
        }
        return found.sorted { $0.position < $1.position }.map(\.skill)
    }

    // MARK: - Planning

    static func plan(
        for request: CoachRequest,
        history: [TrainingEntry],
        favorites: Set<String>,
        now: Date = Date()
    ) -> CoachPlan {
        var notes: [String] = []
        let lastTrained = TrainingLog.lastTrained(history)
        let warmUpMinutes = DrillTimerView.duration(for: warmUpName) / 60
        let coolDownMinutes = DrillTimerView.duration(for: coolDownName) / 60
        let drillMinutes = max(5, request.minutes - warmUpMinutes - coolDownMinutes)
        let daySeed = TrainingStreak.dayString(for: now)

        // The pool the player's own setup allows. Anything it leaves out is reported below.
        let strictPool = candidates(for: request, owned: request.equipment, indoorOnly: request.indoorOnly)
        var pool = strictPool
        if pool.isEmpty {
            pool = candidates(for: request, owned: [], indoorOnly: request.indoorOnly)
            if !pool.isEmpty {
                notes.append("Nothing in your library uses your equipment for this request, so the coach picked drills that need only a ball.")
            }
        }
        if pool.isEmpty {
            pool = candidates(for: request, owned: [], indoorOnly: false)
            if !pool.isEmpty {
                notes.append("There aren't enough indoor drills for this request, so the session includes outdoor ones.")
            }
        }

        for skill in request.skills where !strictPool.contains(where: { $0.skill == skill }) {
            notes.append("No \(skill.lowercased()) drills fit your equipment, space, and age yet.")
        }
        if strictPool.count < 8 {
            let unowned = EquipmentNeeds.options
                .filter { !request.equipment.contains($0.need) }
                .map { $0.label.lowercased() }
            if !unowned.isEmpty {
                notes.append("Only \(strictPool.count) drills fit this setup. Adding \(unowned.prefix(3).joined(separator: ", ")) in Profile would unlock more.")
            }
        }

        func isWeakFootDrill(_ info: DrillInfo) -> Bool {
            info.name.localizedCaseInsensitiveContains("weak foot")
        }

        func score(_ info: DrillInfo) -> Int {
            var total = 0
            if let index = request.skills.firstIndex(of: info.skill) {
                total += max(6 - index, 2)
            } else {
                total -= 2
            }
            if request.weakFoot && isWeakFootDrill(info) {
                total += 5
            }
            if let position = request.position, !info.positions.isEmpty {
                total += info.positions.contains(position) ? 2 : -2
            }
            total += 2 - abs(info.level.rank - request.level.rank) * 2
            if favorites.contains(info.name) {
                total += 1
            }
            if let last = lastTrained[info.name] {
                let days = Calendar.current.dateComponents([.day], from: last, to: now).day ?? 0
                if days < 3 {
                    total -= 4
                } else if days < 7 {
                    total -= 1
                }
            }
            if request.indoorOnly && info.isIndoor {
                total += 2
            }
            return total
        }

        // Ties are broken by a hash that changes daily, so the suggestions vary
        // from day to day but stay the same within a day.
        let ranked = pool.sorted { lhs, rhs in
            let left = score(lhs)
            let right = score(rhs)
            if left != right { return left > right }
            return StableHash.value(lhs.name + daySeed) < StableHash.value(rhs.name + daySeed)
        }

        // Short sessions get two drills. Longer ones fill the time, up to eight.
        let maxDrills = request.minutes <= 15 ? 2 : 8
        var chosen: [DrillInfo] = []
        var remaining = drillMinutes

        func isChosen(_ info: DrillInfo) -> Bool {
            chosen.contains { $0.name == info.name }
        }

        func fits(_ info: DrillInfo) -> Bool {
            info.minutes <= remaining + 2
        }

        func take(_ info: DrillInfo) {
            chosen.append(info)
            remaining -= info.minutes
        }

        // First, one drill for each requested skill, so the session covers what was asked.
        for skill in request.skills where chosen.count < maxDrills {
            if let pick = ranked.first(where: { $0.skill == skill && !isChosen($0) && fits($0) }) {
                take(pick)
            }
        }

        // A weak-foot request always gets at least one weak-foot drill, if the setup allows one.
        if request.weakFoot && chosen.count < maxDrills && !chosen.contains(where: isWeakFootDrill) {
            if let pick = ranked.first(where: { isWeakFootDrill($0) && !isChosen($0) && fits($0) }) {
                take(pick)
            }
        }

        // Then fill the remaining time, preferring requested skills and only then
        // reaching for other drills.
        for info in ranked where chosen.count < maxDrills && remaining > 0 && request.skills.contains(info.skill) {
            if !isChosen(info) && fits(info) {
                take(info)
            }
        }
        for info in ranked where chosen.count < maxDrills && remaining > 0 {
            if !isChosen(info) && fits(info) {
                take(info)
            }
        }

        if chosen.isEmpty, let shortest = ranked.min(by: { $0.minutes < $1.minutes }) {
            take(shortest)
        }

        chosen.sort { $0.level.rank < $1.level.rank }

        var reasons: [String: String] = [:]
        for info in chosen {
            reasons[info.name] = reason(for: info, request: request, favorites: favorites)
        }

        let totalMinutes = warmUpMinutes + coolDownMinutes + chosen.reduce(0) { $0 + $1.minutes }
        if totalMinutes < request.minutes - 5 {
            notes.append("This session runs \(totalMinutes) minutes instead of \(request.minutes), because the drills that fit your setup are shorter.")
        }

        var steps = [SessionStep(role: "Warm-Up", drillName: warmUpName)]
        steps += chosen.enumerated().map { index, info in
            SessionStep(role: "Drill \(index + 1)", drillName: info.name)
        }
        steps.append(SessionStep(role: "Cool-Down", drillName: coolDownName))

        var focus: [String] = []
        for info in chosen where !focus.contains(info.skill) {
            focus.append(info.skill)
        }

        // Name the session after what it actually trains, not a skill that had no drills.
        let covered = request.skills.filter { focus.contains($0) }
        let primary = covered.first ?? focus.first ?? "Full"
        let hasWeakFoot = chosen.contains(where: isWeakFootDrill)
        return CoachPlan(
            title: request.weakFoot && hasWeakFoot ? "Weak Foot & \(primary)" : "\(primary) Session",
            drills: chosen,
            steps: steps,
            totalMinutes: totalMinutes,
            reasons: reasons,
            notes: notes,
            focus: focus
        )
    }

    /// Drills that satisfy the request's hard limits: equipment, age, indoor
    /// space, position, and whether the player asked for fitness or top-level work.
    private static func candidates(for request: CoachRequest, owned: EquipmentNeeds, indoorOnly: Bool) -> [DrillInfo] {
        DrillCatalog.library.filter { info in
            guard DrillCatalog.canUse(info, owned: owned) else { return false }
            guard info.minimumAge <= (request.age ?? 99) else { return false }
            if indoorOnly && !info.isIndoor { return false }
            if info.positions == ["Goalkeeper"] && request.position != "Goalkeeper" && !request.skills.contains("Goalkeeping") {
                return false
            }
            if (info.skill == "Workout" || info.skill == "Plus Training") && !request.skills.contains(info.skill) {
                return false
            }
            return true
        }
    }

    private static func reason(for info: DrillInfo, request: CoachRequest, favorites: Set<String>) -> String {
        var parts = ["Targets \(info.skill.lowercased())"]
        if request.weakFoot && info.name.localizedCaseInsensitiveContains("weak foot") {
            parts.append("builds your weaker foot")
        }
        if let position = request.position, info.positions.contains(position) {
            parts.append("suits a \(position.lowercased())")
        }
        let used = info.equipment.labels
        if !used.isEmpty {
            parts.append("uses your \(used.map { $0.lowercased() }.joined(separator: " and "))")
        }
        if favorites.contains(info.name) {
            parts.append("one of your favorites")
        }
        return parts.joined(separator: " · ")
    }
}

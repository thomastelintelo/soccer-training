// SessionStep.swift
// One step in a guided training session: a warm-up, a main drill, or the
// cool-down, in order.

import Foundation

struct SessionStep: Identifiable {
    let role: String
    let drillName: String

    // Stable, content-derived id — not a fresh UUID(). A session's steps are
    // built once and never reconstructed with new identities, but every
    // other model in this app learned that lesson the hard way, so this one
    // starts correct.
    var id: String { "\(role)-\(drillName)" }
}

enum SessionBuilder {
    /// A warm-up, 4 varied drills from the category (shuffled, so repeat
    /// sessions don't train the same four drills every time), and a
    /// cool-down.
    static func steps(category: String, drills: [Drill]) -> [SessionStep] {
        var result: [SessionStep] = [SessionStep(role: "Warm-Up", drillName: "Dynamic Warm Up")]

        let picks = drills.shuffled().prefix(4)
        for (index, drill) in picks.enumerated() {
            result.append(SessionStep(role: "Drill \(index + 1)", drillName: drill.name))
        }

        result.append(SessionStep(role: "Cool-Down", drillName: "Cool Down Stretch"))
        return result
    }

    /// A warm-up, the given drills in order, and a cool-down — used for a
    /// named SessionTemplate, where the drill lineup is hand-picked rather
    /// than randomly sampled from the whole category.
    static func steps(fixedDrillNames: [String]) -> [SessionStep] {
        var result: [SessionStep] = [SessionStep(role: "Warm-Up", drillName: "Dynamic Warm Up")]

        for (index, name) in fixedDrillNames.enumerated() {
            result.append(SessionStep(role: "Drill \(index + 1)", drillName: name))
        }

        result.append(SessionStep(role: "Cool-Down", drillName: "Cool Down Stretch"))
        return result
    }
}

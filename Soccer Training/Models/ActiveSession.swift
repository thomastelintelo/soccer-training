// ActiveSession.swift
// A guided session the player has started but not finished. It is saved as
// JSON so Home can offer "Continue Training" even after the app is closed.

import Foundation

struct ActiveSession: Codable, Equatable {
    enum StepStatus: String, Codable {
        case pending
        case done
        case skipped
    }

    struct Step: Codable, Equatable, Identifiable {
        let role: String
        let drillName: String
        var status: StepStatus

        var id: String { "\(role)-\(drillName)" }
    }

    let title: String
    var steps: [Step]
    var currentIndex: Int
    var pointsEarned: Int
    var isFinished: Bool

    init(title: String, steps: [SessionStep]) {
        self.title = title
        self.steps = steps.map { Step(role: $0.role, drillName: $0.drillName, status: .pending) }
        self.currentIndex = 0
        self.pointsEarned = 0
        self.isFinished = false
    }

    var completedCount: Int {
        steps.filter { $0.status == .done }.count
    }

    /// Warm-up and cool-down are included in the count, as they are steps too.
    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        let handled = steps.filter { $0.status != .pending }.count
        return Double(handled) / Double(steps.count)
    }

    var currentStep: Step? {
        steps.indices.contains(currentIndex) ? steps[currentIndex] : nil
    }

    /// Drills only, leaving out the warm-up and cool-down.
    var mainDrillCount: Int {
        steps.filter { $0.role.hasPrefix("Drill") }.count
    }

    var totalMinutes: Int {
        steps.reduce(0) { $0 + DrillTimerView.duration(for: $1.drillName) / 60 }
    }
}

enum ActiveSessionStore {
    static let storageKey = "activeSessionJSON"

    static func load(_ defaults: UserDefaults = .standard) -> ActiveSession? {
        guard
            let text = defaults.string(forKey: storageKey),
            let data = text.data(using: .utf8),
            let session = try? JSONDecoder().decode(ActiveSession.self, from: data)
        else {
            return nil
        }
        return session.isFinished ? nil : session
    }

    static func save(_ session: ActiveSession, _ defaults: UserDefaults = .standard) {
        guard
            let data = try? JSONEncoder().encode(session),
            let text = String(data: data, encoding: .utf8)
        else {
            return
        }
        defaults.set(text, forKey: storageKey)
    }

    static func clear(_ defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey)
    }
}

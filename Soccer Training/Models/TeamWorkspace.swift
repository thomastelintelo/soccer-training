import Foundation

struct TeamMember: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var age: Int
    var position: String
    var isCaptain: Bool
    var points: Int
}

struct TeamAssignment: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var details: String
    var equipment: String
    var assignedMemberID: UUID?
    var createdAt: Date
    var durationMinutes: Int? = nil
    /// Set when the coach picked a drill from the player Drills tab.
    var playerDrillName: String? = nil
}

struct TeamCustomDrill: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var instructions: String
    var equipment: String
    var durationMinutes: Int? = nil
}

struct CoachScheduleItem: Codable, Identifiable, Hashable {
    let id: UUID
    var weekday: String
    var startTime: Date
    var focus: String
    var drillName: String
    var durationMinutes: Int
}

struct TeamWorkspace: Codable, Identifiable, Hashable {
    var id: String { joinCode }
    var teamName: String
    var joinCode: String
    var ageGroup: String
    var coachName: String
    var members: [TeamMember]
    var assignments: [TeamAssignment]
    var customDrills: [TeamCustomDrill]
    var schedule: [CoachScheduleItem]?
    var removedMemberIDs: [UUID]? = nil
}

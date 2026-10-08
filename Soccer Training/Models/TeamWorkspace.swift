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
}

struct TeamCustomDrill: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var instructions: String
    var equipment: String
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
}

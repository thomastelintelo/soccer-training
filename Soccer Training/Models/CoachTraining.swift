import Foundation

enum AppRole: String {
    case player
    case coach
}

struct CoachAgeGroup: Identifiable, Hashable {
    let age: Int

    var id: Int { age }
    var title: String { "U\(age)" }

    static let all = (5...21).map(CoachAgeGroup.init)
}

enum CoachDrillCategory: String, CaseIterable, Identifiable {
    case shooting = "Shooting"
    case dribbling = "Dribbling"
    case passing = "Passing"
    case control = "Control"
    case fitness = "Fitness"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .shooting: "scope"
        case .dribbling: "figure.soccer"
        case .passing: "arrow.left.arrow.right"
        case .control: "circle.grid.cross.fill"
        case .fitness: "figure.run"
        }
    }
}

struct CoachDrill: Identifiable {
    let name: String
    let category: CoachDrillCategory
    let minimumAge: Int
    let maximumAge: Int
    let durationMinutes: Int
    let players: String
    let equipment: [String]
    let setup: String
    let coachingFocus: String

    var id: String { "\(category.rawValue)-\(name)" }

    var recommendedAges: String {
        minimumAge == maximumAge
            ? "Recommended U\(minimumAge)"
            : "Recommended U\(minimumAge)–U\(maximumAge)"
    }

    func isRecommended(for age: Int) -> Bool {
        (minimumAge...maximumAge).contains(age)
    }
}

enum CoachDrillLibrary {
    private struct Seed {
        let name: String
        let category: CoachDrillCategory
        let ages: ClosedRange<Int>
        let duration: Int
    }

    private static let seeds: [Seed] = [
        Seed(name: "Goal Scoring Safari", category: .shooting, ages: 5...7, duration: 8),
        Seed(name: "Cone Castle Knockdown", category: .shooting, ages: 5...8, duration: 8),
        Seed(name: "1v1 Score and Celebrate", category: .shooting, ages: 6...9, duration: 10),
        Seed(name: "Four-Corner Finishing", category: .shooting, ages: 8...11, duration: 12),
        Seed(name: "First-Touch Finish", category: .shooting, ages: 9...13, duration: 12),
        Seed(name: "Weak-Foot Finish Circuit", category: .shooting, ages: 10...14, duration: 14),
        Seed(name: "Cutback Finishing Waves", category: .shooting, ages: 11...16, duration: 15),
        Seed(name: "Cross and Finish Rotation", category: .shooting, ages: 12...17, duration: 16),
        Seed(name: "Combination Finishing", category: .shooting, ages: 13...21, duration: 18),
        Seed(name: "Pressure Finishing Game", category: .shooting, ages: 14...21, duration: 20),

        Seed(name: "Traffic Lights", category: .dribbling, ages: 5...7, duration: 8),
        Seed(name: "Treasure Island Dribble", category: .dribbling, ages: 5...8, duration: 8),
        Seed(name: "Sharks and Minnows", category: .dribbling, ages: 6...10, duration: 10),
        Seed(name: "Cone Maze Adventure", category: .dribbling, ages: 7...10, duration: 10),
        Seed(name: "Change-of-Direction Grid", category: .dribbling, ages: 8...12, duration: 12),
        Seed(name: "1v1 Gate Attack", category: .dribbling, ages: 9...14, duration: 14),
        Seed(name: "Skill Move Escape", category: .dribbling, ages: 10...15, duration: 14),
        Seed(name: "Wide Channel Take-On", category: .dribbling, ages: 12...18, duration: 16),
        Seed(name: "Numbers-Up Dribbling Game", category: .dribbling, ages: 13...21, duration: 18),
        Seed(name: "Transition Dribble Challenge", category: .dribbling, ages: 15...21, duration: 20),

        Seed(name: "Pass to the Coach", category: .passing, ages: 5...7, duration: 8),
        Seed(name: "Partner Passing Gates", category: .passing, ages: 6...9, duration: 10),
        Seed(name: "Pass and Follow Square", category: .passing, ages: 7...11, duration: 10),
        Seed(name: "Passing Diamond", category: .passing, ages: 8...12, duration: 12),
        Seed(name: "Wall Pass and Move", category: .passing, ages: 9...14, duration: 14),
        Seed(name: "4v2 Keep Away", category: .passing, ages: 10...15, duration: 14),
        Seed(name: "Third-Player Combination", category: .passing, ages: 11...17, duration: 16),
        Seed(name: "Switch the Point of Attack", category: .passing, ages: 12...18, duration: 18),
        Seed(name: "Possession to Target Players", category: .passing, ages: 13...21, duration: 20),
        Seed(name: "Breaking Lines Rondo", category: .passing, ages: 15...21, duration: 20),

        Seed(name: "Control and Freeze", category: .control, ages: 5...7, duration: 8),
        Seed(name: "Coach Says Touches", category: .control, ages: 5...8, duration: 8),
        Seed(name: "Ball Mastery Shapes", category: .control, ages: 6...10, duration: 10),
        Seed(name: "First-Touch Gates", category: .control, ages: 8...12, duration: 12),
        Seed(name: "Receive, Turn, Escape", category: .control, ages: 9...14, duration: 14),
        Seed(name: "Aerial Control Stations", category: .control, ages: 10...16, duration: 15),
        Seed(name: "Back-Foot Receiving", category: .control, ages: 11...17, duration: 16),
        Seed(name: "Pressure Control Rondo", category: .control, ages: 12...18, duration: 18),
        Seed(name: "Half-Turn Possession", category: .control, ages: 13...21, duration: 18),
        Seed(name: "Match-Speed First Touch", category: .control, ages: 15...21, duration: 20),

        Seed(name: "Animal Movement Relay", category: .fitness, ages: 5...7, duration: 8),
        Seed(name: "Tag with a Ball", category: .fitness, ages: 5...9, duration: 8),
        Seed(name: "Movement Adventure Course", category: .fitness, ages: 6...10, duration: 10),
        Seed(name: "Agility and Reaction Relay", category: .fitness, ages: 8...12, duration: 12),
        Seed(name: "Ball-Speed Race", category: .fitness, ages: 9...14, duration: 12),
        Seed(name: "Repeated Sprint with the Ball", category: .fitness, ages: 11...16, duration: 15),
        Seed(name: "Change-of-Direction Circuit", category: .fitness, ages: 12...18, duration: 16),
        Seed(name: "Conditioned Transition Game", category: .fitness, ages: 13...21, duration: 18),
        Seed(name: "Soccer Endurance Intervals", category: .fitness, ages: 15...21, duration: 20),
        Seed(name: "High-Intensity Small-Sided Game", category: .fitness, ages: 16...21, duration: 22),

        // Extra session options give coaches enough variety to build a full season.
        Seed(name: "Rapid Fire Finish", category: .shooting, ages: 7...11, duration: 10),
        Seed(name: "Numbers Shooting Race", category: .shooting, ages: 7...12, duration: 12),
        Seed(name: "Turn and Finish", category: .shooting, ages: 8...14, duration: 14),
        Seed(name: "Near-Post Far-Post", category: .shooting, ages: 9...15, duration: 14),
        Seed(name: "Finishing Diamond", category: .shooting, ages: 10...16, duration: 16),
        Seed(name: "Two-Touch Box Finishing", category: .shooting, ages: 11...18, duration: 16),
        Seed(name: "Second-Ball Finishing", category: .shooting, ages: 12...21, duration: 18),
        Seed(name: "Timed Finishing Circuit", category: .shooting, ages: 12...21, duration: 18),
        Seed(name: "3v2 to Goal", category: .shooting, ages: 13...21, duration: 20),
        Seed(name: "Late Runner Finish", category: .shooting, ages: 14...21, duration: 20),

        Seed(name: "Dribble Freeze Dance", category: .dribbling, ages: 5...8, duration: 8),
        Seed(name: "Gate Collector", category: .dribbling, ages: 6...10, duration: 10),
        Seed(name: "Mirror Dribbling", category: .dribbling, ages: 7...12, duration: 10),
        Seed(name: "Four-Corner Escape", category: .dribbling, ages: 8...13, duration: 12),
        Seed(name: "Defender in the Maze", category: .dribbling, ages: 9...14, duration: 14),
        Seed(name: "1v1 End-Zone Attack", category: .dribbling, ages: 10...16, duration: 16),
        Seed(name: "2v2 Wide Take-On", category: .dribbling, ages: 11...18, duration: 18),
        Seed(name: "Counterattack Carry", category: .dribbling, ages: 12...21, duration: 18),
        Seed(name: "Overload and Break Line", category: .dribbling, ages: 13...21, duration: 20),
        Seed(name: "Match-Speed Skill Circuit", category: .dribbling, ages: 15...21, duration: 20),

        Seed(name: "Passing Treasure Hunt", category: .passing, ages: 5...8, duration: 8),
        Seed(name: "Colored Gate Passing", category: .passing, ages: 6...10, duration: 10),
        Seed(name: "Pass Through the Traffic", category: .passing, ages: 7...12, duration: 12),
        Seed(name: "Two-Ball Passing Square", category: .passing, ages: 8...14, duration: 14),
        Seed(name: "Rondo Rotation", category: .passing, ages: 9...15, duration: 15),
        Seed(name: "Bounce-Pass Combination", category: .passing, ages: 10...17, duration: 16),
        Seed(name: "Three-Zone Possession", category: .passing, ages: 11...18, duration: 18),
        Seed(name: "Play Through Midfield", category: .passing, ages: 12...21, duration: 20),
        Seed(name: "Switch and Penetrate", category: .passing, ages: 13...21, duration: 20),
        Seed(name: "One-Touch Transition Rondo", category: .passing, ages: 15...21, duration: 22),

        Seed(name: "Soft Touch Islands", category: .control, ages: 5...8, duration: 8),
        Seed(name: "Touch and Chase", category: .control, ages: 6...10, duration: 10),
        Seed(name: "Receive Through a Gate", category: .control, ages: 7...12, duration: 12),
        Seed(name: "Turn Away from Pressure", category: .control, ages: 8...14, duration: 14),
        Seed(name: "First-Touch Compass", category: .control, ages: 9...15, duration: 14),
        Seed(name: "Receive Between Lines", category: .control, ages: 10...17, duration: 16),
        Seed(name: "Aerial Receive and Pass", category: .control, ages: 11...18, duration: 18),
        Seed(name: "Scanning Before the Ball", category: .control, ages: 12...21, duration: 18),
        Seed(name: "Tight-Area First Touch", category: .control, ages: 13...21, duration: 20),
        Seed(name: "Directional Touch Game", category: .control, ages: 15...21, duration: 20),

        Seed(name: "Soccer Obstacle Adventure", category: .fitness, ages: 5...8, duration: 8),
        Seed(name: "Cone Color Reaction", category: .fitness, ages: 6...10, duration: 10),
        Seed(name: "Partner Chase Relay", category: .fitness, ages: 7...12, duration: 10),
        Seed(name: "Ball Agility Ladder", category: .fitness, ages: 8...14, duration: 12),
        Seed(name: "Sprint and Recover", category: .fitness, ages: 9...15, duration: 14),
        Seed(name: "Explosive First Five", category: .fitness, ages: 10...17, duration: 15),
        Seed(name: "Repeated Transition Runs", category: .fitness, ages: 11...18, duration: 16),
        Seed(name: "Power and Balance Circuit", category: .fitness, ages: 12...21, duration: 18),
        Seed(name: "Game-Speed Conditioning", category: .fitness, ages: 13...21, duration: 20),
        Seed(name: "Competitive Fitness League", category: .fitness, ages: 15...21, duration: 22),
    ]

    static let allDrills: [CoachDrill] = seeds.map(makeDrill)

    static func drills(
        recommendedFor ageGroup: CoachAgeGroup?,
        category: CoachDrillCategory?
    ) -> [CoachDrill] {
        allDrills.filter { drill in
            let matchesAge = ageGroup.map { drill.isRecommended(for: $0.age) } ?? true
            let matchesCategory = category.map { drill.category == $0 } ?? true
            return matchesAge && matchesCategory
        }
    }

    static func drills(for ageGroup: CoachAgeGroup, category: CoachDrillCategory) -> [CoachDrill] {
        drills(recommendedFor: ageGroup, category: category)
    }

    nonisolated private static func makeDrill(from seed: Seed) -> CoachDrill {
        let players = seed.ages.upperBound <= 9 ? "4–8 players" : seed.ages.lowerBound >= 14 ? "10–18 players" : "6–14 players"

        let equipment: [String]
        let setup: String
        let focus: String

        switch seed.category {
        case .shooting:
            equipment = ["Balls", "Cones", "Bibs", "2 goals"]
            setup = "Create two finishing stations with a supply of balls. Players work in short lines, shoot, collect a ball, and rotate to the other station."
            focus = "Balanced approach, accurate contact, finishing with both feet, and reacting quickly for rebounds."
        case .dribbling:
            equipment = ["One ball per player", "Cones", "Bibs", "2 small goals"]
            setup = "Mark a grid with several gates and safe space between players. Begin unopposed, then add defenders or a directional target."
            focus = "Close control, awareness, changes of speed and direction, and protecting the ball under pressure."
        case .passing:
            equipment = ["Balls", "Cones", "Bibs"]
            setup = "Build passing lanes or a possession area. Keep spare balls around the outside so play restarts immediately."
            focus = "Passing weight, support angles, communication, scanning, and moving after the pass."
        case .control:
            equipment = ["Balls", "Cones", "Bibs", "Agility poles"]
            setup = "Create receiving gates inside a grid. Serve from different angles and gradually add passive, then active, pressure."
            focus = "Early body shape, a soft first touch into space, checking shoulders, and preparing the next action."
        case .fitness:
            equipment = ["Balls", "Cones", "Bibs", "Agility poles"]
            setup = "Set up short work stations with clear running lanes and recovery areas. Use a ball whenever possible and keep repetitions brief."
            focus = "Safe movement quality, coordination, acceleration, deceleration, and age-appropriate recovery."
        }

        return CoachDrill(
            name: seed.name,
            category: seed.category,
            minimumAge: seed.ages.lowerBound,
            maximumAge: seed.ages.upperBound,
            durationMinutes: seed.duration,
            players: players,
            equipment: equipment,
            setup: setup,
            coachingFocus: focus
        )
    }
}

import Foundation

struct SoccerTest: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let instructions: String
    let equipment: String
    let unit: String
    let target: Double
    let lowerIsBetter: Bool
    let icon: String
}

enum SoccerTestCatalog {
    static let categories = ["Shooting", "Dribbling", "Passing", "Control", "Fitness", "Goalkeeping"]

    static let all: [SoccerTest] = [
        test("shoot-10", "10-Shot Accuracy", "Shooting", "Take 10 shots from a marked spot. Count shots that hit either corner target.", "Ball, goal, 2 corner targets", "goals", 7, false, "scope"),
        test("shoot-weak", "Weak-Foot Finishing", "Shooting", "Take 10 controlled shots using only your weaker foot. Count goals.", "Ball and goal", "goals", 6, false, "figure.soccer"),
        test("shoot-60", "60-Second Finishing", "Shooting", "Score as many times as possible in 60 seconds, retrieving each rebound safely.", "Ball, goal, timer", "goals", 8, false, "timer"),
        test("shoot-crossbar", "Crossbar Challenge", "Shooting", "Take 10 attempts from a safe age-appropriate distance. Count crossbar hits.", "Ball and full-size goal", "hits", 3, false, "target"),
        test("shoot-power", "Power and Accuracy", "Shooting", "Take 8 firm shots. Count only shots that enter a marked side zone.", "Ball, goal, cones", "goals", 5, false, "bolt.fill"),
        test("shoot-volley", "Volley Control Test", "Shooting", "Serve the ball to yourself for 10 controlled volleys. Count shots on target.", "Ball and goal or wall target", "on target", 6, false, "soccerball"),

        test("dribble-slalom", "Cone Slalom Sprint", "Dribbling", "Dribble through 8 cones and back. Record your fastest clean time.", "Ball, 8 cones, timer", "seconds", 18, true, "figure.soccer"),
        test("dribble-box", "Box Touch Challenge", "Dribbling", "Stay inside a 4-yard box and complete as many controlled touches as possible in 30 seconds.", "Ball, 4 cones, timer", "touches", 75, false, "square.grid.3x3.fill"),
        test("dribble-gates", "Gate Dribble Test", "Dribbling", "Dribble through as many different cone gates as possible in 60 seconds.", "Ball, 12 cones, timer", "gates", 14, false, "point.3.connected.trianglepath.dotted"),
        test("dribble-turns", "Turn Combo Test", "Dribbling", "Complete a pullback, inside hook, outside hook, and Cruyff turn. Count clean full combinations in 60 seconds.", "Ball, cone, timer", "combos", 6, false, "arrow.trianglehead.2.clockwise.rotate.90"),
        test("dribble-figure8", "Figure-Eight Speed", "Dribbling", "Complete five figure-eight laps around two cones. Record the fastest clean time.", "Ball, 2 cones, timer", "seconds", 25, true, "infinity"),
        test("dribble-1v1", "Skill Move Repetitions", "Dribbling", "Perform a chosen 1v1 move past a cone, reset, and repeat for 60 seconds.", "Ball, cone, timer", "reps", 12, false, "wand.and.stars"),

        test("pass-wall30", "30-Second Wall Passing", "Passing", "Pass against a wall using two touches. Count accurate returns controlled inside your area.", "Ball, wall, timer, 2 cones", "passes", 22, false, "arrow.left.arrow.right"),
        test("pass-gates", "Passing Gates Accuracy", "Passing", "Play 20 passes through a two-yard gate from an age-appropriate distance. Count successes.", "Ball, 2 cones", "passes", 15, false, "scope"),
        test("pass-weak", "Weak-Foot Passing", "Passing", "Play 20 wall passes using only your weaker foot. Count accurate returns.", "Ball, wall, 2 cones", "passes", 14, false, "figure.soccer"),
        test("pass-one", "One-Touch Passing", "Passing", "Complete as many controlled one-touch wall passes as possible in 30 seconds.", "Ball, wall, timer", "passes", 18, false, "bolt.fill"),
        test("pass-long", "Long-Pass Targets", "Passing", "Attempt 10 longer passes into a marked target square. Count balls that finish inside.", "Ball, cones, open space", "targets", 6, false, "paperplane.fill"),
        test("pass-alt", "Alternating Feet Passes", "Passing", "Alternate left and right foot on every wall pass for 60 seconds. Count clean passes.", "Ball, wall, timer", "passes", 35, false, "arrow.left.arrow.right.circle.fill"),

        test("control-juggle", "Juggling Personal Best", "Control", "Keep the ball in the air using legal body parts. Record your longest streak.", "Ball", "touches", 30, false, "soccerball"),
        test("control-first", "First-Touch Gates", "Control", "Receive 20 wall passes and take your first touch through alternating gates. Count successes.", "Ball, wall, 4 cones", "controls", 15, false, "circle.grid.cross.fill"),
        test("control-aerial", "Aerial Control", "Control", "Serve 15 balls above waist height and settle each within one step. Count clean controls.", "Ball", "controls", 10, false, "arrow.down.circle.fill"),
        test("control-sole", "Sole Touch Speed", "Control", "Complete alternating sole taps for 30 seconds while keeping the ball still.", "Ball and timer", "touches", 70, false, "shoeprints.fill"),
        test("control-turn", "Receive-and-Turn", "Control", "Pass against a wall, receive on the half-turn, and pass again. Count clean repetitions in 60 seconds.", "Ball, wall, timer", "reps", 14, false, "arrow.turn.up.right"),
        test("control-box", "Tight-Space Mastery", "Control", "Complete inside-outside touches without leaving a small box for 45 seconds.", "Ball, 4 cones, timer", "touches", 80, false, "square.dashed"),

        test("fit-sprint", "20-Meter Sprint", "Fitness", "Sprint 20 meters from a standing start. Record your fastest safe time after a full warm-up.", "4 cones and timer", "seconds", 4, true, "figure.run"),
        test("fit-shuttle", "5-10-5 Shuttle", "Fitness", "Sprint five yards, ten yards the opposite direction, then five yards through the start.", "3 cones and timer", "seconds", 6, true, "arrow.left.and.right"),
        test("fit-ball", "Ball Sprint Course", "Fitness", "Dribble a 30-meter course with two changes of direction. Record a clean time.", "Ball, 4 cones, timer", "seconds", 12, true, "figure.soccer"),
        test("fit-plank", "Plank Hold", "Fitness", "Hold a safe plank with a straight body line. Stop when form breaks.", "Exercise mat and timer", "seconds", 60, false, "figure.core.training"),
        test("fit-jump", "Standing Broad Jump", "Fitness", "From a standing start, jump forward and land under control. Record the best of three.", "Tape measure", "centimeters", 150, false, "figure.jumprope"),
        test("fit-recovery", "Repeated Sprint Test", "Fitness", "Complete six 20-meter sprints with 20 seconds rest. Record the total time.", "Cones and timer", "seconds", 35, true, "stopwatch.fill"),

        test("gk-reaction", "Goalkeeper Reaction Saves", "Goalkeeping", "Have a partner serve 20 safe shots from close range. Count controlled saves.", "Balls, goal, partner", "saves", 14, false, "hand.raised.fill"),
        test("gk-handling", "Clean Handling Test", "Goalkeeping", "Catch 15 serves at varied safe heights. Count catches held without a rebound.", "Ball and partner", "catches", 12, false, "hands.sparkles.fill"),
        test("gk-feet", "Goalkeeper Footwork", "Goalkeeping", "Move through a four-cone set-position pattern five times. Record the fastest clean time.", "4 cones and timer", "seconds", 20, true, "shoeprints.fill"),
        test("gk-throw", "Throw Distribution", "Goalkeeping", "Throw 10 balls into a marked target area. Count accurate deliveries.", "Balls and cones", "targets", 7, false, "paperplane.fill"),
        test("gk-kick", "Kick Distribution", "Goalkeeping", "Kick 10 stationary balls into a wide target channel. Count accurate deliveries.", "Balls and cones", "targets", 6, false, "figure.soccer"),
        test("gk-low", "Low Save Circuit", "Goalkeeping", "Complete 10 alternating low saves from safe partner serves. Count clean holds.", "Balls, goal, partner", "saves", 8, false, "arrow.down.left.and.arrow.up.right"),
    ]

    private static func test(
        _ id: String,
        _ name: String,
        _ category: String,
        _ instructions: String,
        _ equipment: String,
        _ unit: String,
        _ target: Double,
        _ lowerIsBetter: Bool,
        _ icon: String
    ) -> SoccerTest {
        SoccerTest(
            id: id,
            name: name,
            category: category,
            instructions: instructions,
            equipment: equipment,
            unit: unit,
            target: target,
            lowerIsBetter: lowerIsBetter,
            icon: icon
        )
    }
}

enum SoccerTestResults {
    static func decode(_ text: String) -> [String: Double] {
        guard let data = text.data(using: .utf8),
              let values = try? JSONDecoder().decode([String: Double].self, from: data) else { return [:] }
        return values
    }

    static func encode(_ values: [String: Double]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }

    static func formatted(_ value: Double, unit: String) -> String {
        let number = value.rounded() == value ? value.formatted(.number.precision(.fractionLength(0))) : value.formatted(.number.precision(.fractionLength(1)))
        return "\(number) \(unit)"
    }
}

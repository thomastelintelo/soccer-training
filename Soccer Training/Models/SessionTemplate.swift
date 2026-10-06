// SessionTemplate.swift
// Hand-picked, themed sessions for each category (e.g. several different
// ways to run a shooting session), on top of the always-available Mixed
// Session that pulls a random 4 drills from the category.

import Foundation

struct SessionTemplate: Identifiable {
    let name: String
    let detail: String
    let category: String
    let drillNames: [String]

    var id: String { "\(category)-\(name)" }
}

enum SessionTemplateCatalog {
    static let templates: [SessionTemplate] = [
        // Shooting gets extra depth since it's the most commonly requested focus.
        SessionTemplate(
            name: "Finishing Clinic",
            detail: "Near post, cutback, far post, and finesse finishes",
            category: "Shooting",
            drillNames: ["Near Post Finish", "Cutback Finish", "Far Post Finish", "Finesse Corner Finish"]
        ),
        SessionTemplate(
            name: "Power & Placement",
            detail: "Drive the ball hard and pick your corner",
            category: "Shooting",
            drillNames: ["Power Shots", "Instep Drive Finish", "Curl Shot Finish", "Driven Low Finish"]
        ),
        SessionTemplate(
            name: "Pressure Finishing",
            detail: "Finish fast and finish tired, like a real match",
            category: "Shooting",
            drillNames: ["Pressure Finish Gauntlet", "Finishing Clock", "One Touch Finish", "Rebound Finish"]
        ),
        SessionTemplate(
            name: "Weak Foot Focus",
            detail: "Build confidence finishing with your weaker foot",
            category: "Shooting",
            drillNames: ["Weak Foot Finishing", "Inside Foot Placement", "Outside Foot Finish", "Turn and Shoot"]
        ),

        SessionTemplate(
            name: "Change of Direction",
            detail: "Turns and feints to lose a defender",
            category: "Dribbling",
            drillNames: ["Cruyff Turn", "Scissors Move", "Step Over Exit", "Body Feint"]
        ),
        SessionTemplate(
            name: "Speed Dribbling",
            detail: "Run at pace with the ball under control",
            category: "Dribbling",
            drillNames: ["Speed Dribble", "Zigzag Sprint", "Push and Explode", "Sprint and Shield"]
        ),

        SessionTemplate(
            name: "Short Passing Combos",
            detail: "Quick, accurate passes in tight spaces",
            category: "Passing",
            drillNames: ["Wall Passing", "One Touch Passing", "Give and Go", "Quick Combination Pass"]
        ),
        SessionTemplate(
            name: "Long & Switch Passing",
            detail: "Pick out a target across the field",
            category: "Passing",
            drillNames: ["Long Passing", "Switch Play Pass", "Driven Diagonal Pass", "Through Ball Timing"]
        ),

        SessionTemplate(
            name: "First Touch Essentials",
            detail: "Settle the ball cleanly under control",
            category: "Control",
            drillNames: ["Wall Control", "Chest Control", "Bounce Control", "Sole Cushion"]
        ),
        SessionTemplate(
            name: "Juggling & Ball Mastery",
            detail: "Build close control and ball feel",
            category: "Control",
            drillNames: ["Juggling", "Ball Mastery", "Two Foot Juggling", "Toe Tap Challenge"]
        ),

        SessionTemplate(
            name: "Shot Stopping",
            detail: "Reactions and positioning to make saves",
            category: "Goalkeeping",
            drillNames: ["Set Position Saves", "Reaction Saves", "Low Diving Saves", "Near Post Saves"]
        ),
        SessionTemplate(
            name: "Handling & Distribution",
            detail: "Catch cleanly and start the attack",
            category: "Goalkeeping",
            drillNames: ["High Ball Catch", "Scoop Saves", "Throw Distribution", "Distribution Accuracy"]
        ),

        SessionTemplate(
            name: "1v1 Defending",
            detail: "Stay patient and win the ball back",
            category: "Defense",
            drillNames: ["Jockeying", "Close Down", "Standing Tackle Timing", "1v1 Shadow"]
        ),
        SessionTemplate(
            name: "Recovery & Positioning",
            detail: "Get goal-side and cover your teammates",
            category: "Defense",
            drillNames: ["Recovery Run", "Backpedal and Turn", "Cover Shadow", "Hold the Line"]
        ),

        SessionTemplate(
            name: "Elite Finishing",
            detail: "Advanced circuits for clinical finishing",
            category: "Plus Training",
            drillNames: ["Elite Finishing Circuit", "Overload Finishing Circuit", "Rapid Fire Volleys", "Precision Cross Finish"]
        ),
        SessionTemplate(
            name: "Complete Player Circuit",
            detail: "Combine every skill at match intensity",
            category: "Plus Training",
            drillNames: ["Complete Midfielder Circuit", "Box to Box Circuit", "Game Speed Possession", "Technical Mastery Circuit"]
        ),

        SessionTemplate(
            name: "Signature Skill Moves",
            detail: "Beat a defender with real moves",
            category: "Technique",
            drillNames: ["Elastico Flick", "Nutmeg Attempt", "La Croqueta", "Rainbow Flick"]
        ),
        SessionTemplate(
            name: "Spin & Turn Moves",
            detail: "Roll, drag, and spin away from pressure",
            category: "Technique",
            drillNames: ["Roulette Spin", "Berba Spin Turn", "Hocus Pocus Spin", "Okocha Shoulder Drop"]
        ),

        SessionTemplate(
            name: "Sprint Finishing",
            detail: "Finish with your legs already tired",
            category: "Speed & Finishing",
            drillNames: ["Agility Gate Sprint", "Full Field Sprint Finish", "Rapid Fire Finishing", "Finish Under Fatigue"]
        ),
        SessionTemplate(
            name: "Clinical Finishing",
            detail: "Clean technique at full speed",
            category: "Speed & Finishing",
            drillNames: ["Snap Shot Finish", "Rising Drive Finish", "Dipping Volley Finish", "Driven Near Post Finish"]
        ),

        SessionTemplate(
            name: "Receiving Under Pressure",
            detail: "Take a good first touch with a defender close",
            category: "First Touch",
            drillNames: ["Receive Under Pressure", "Spin Out of Pressure", "Receive Behind the Line", "First Touch Direction Change"]
        ),
        SessionTemplate(
            name: "Touch & Release",
            detail: "One clean touch, then play",
            category: "First Touch",
            drillNames: ["First Touch Gates", "Two Touch Mastery", "Cushion Touch", "Back Foot Control"]
        ),

        SessionTemplate(
            name: "Scanning & Awareness",
            detail: "See the field before the ball arrives",
            category: "Soccer IQ",
            drillNames: ["Scan Before Touch", "Field Awareness Circuit", "Game Speed Scanning", "Numbers Up Counter"]
        ),
        SessionTemplate(
            name: "Decision Making",
            detail: "Read the game and choose fast",
            category: "Soccer IQ",
            drillNames: ["Quick Decision Gates", "Decision Under Pressure", "Press Trigger Recognition", "Read and React Passing"]
        ),

        SessionTemplate(
            name: "Speed & Agility",
            detail: "Quicker feet, faster first step",
            category: "Workout",
            drillNames: ["Agility Sprints", "Ladder Footwork Drill", "Lateral Hops", "Explosive Start Sprints"]
        ),
        SessionTemplate(
            name: "Strength & Core",
            detail: "Build the base that powers everything else",
            category: "Workout",
            drillNames: ["Core Stability", "Plank Variations", "Leg Strength", "Single Leg Strength"]
        ),

        SessionTemplate(
            name: "Small Space Ball Mastery",
            detail: "Full session in a small, safe indoor space",
            category: "Indoor Training",
            drillNames: ["Ball Mastery", "Toe Tap Challenge", "Sole Roll Circuit", "Box Ball Mastery"]
        ),
        SessionTemplate(
            name: "Indoor Passing & Control",
            detail: "Wall passing and tight touches indoors",
            category: "Indoor Training",
            drillNames: ["Indoor Wall Passing", "Wall Touch Challenge", "Small Space Weave", "Foundation Touches"]
        ),
    ]

    static func templates(for category: String) -> [SessionTemplate] {
        templates.filter { $0.category == category }
    }
}

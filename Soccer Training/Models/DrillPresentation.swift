// DrillPresentation.swift
// Maps a drill name to its category, artwork, equipment list, and focus text.
// Used by AllDrillsView, DrillListView, and DrillTimerView.

enum DrillPresentation {
    static let categories: [(name: String, drills: Set<String>)] = [
        ("Shooting", ["Practice Shooting", "Quick Shot", "Dribble and Shoot", "First Touch Finish", "Target Corners", "Power Shots", "Weak Foot Finishing", "Turn and Shoot", "Volley Finish", "Near Post Finish", "Cutback Finish", "Far Post Finish", "Low Driven Finish", "Rebound Finish", "One Touch Finish"]),
        ("Dribbling", ["Cone Weave", "Speed Dribble", "Box Dribble", "L-Drag Turn", "Stop and Go", "Pullback Turn", "Figure Eight", "Zigzag Sprint", "Scissors Move", "Change of Pace", "Shield and Turn", "Cruyff Turn", "V-Cut Dribble", "Double Touch", "Body Feint", "Step Over Exit", "Drag Push", "Slalom Control"]),
        ("Control", ["Juggling", "Wall Control", "Inside-Outside Touches", "Sole Roll and Push", "Aerial Control", "First Touch Gates", "Thigh Control", "Chest Control", "Cushion Touch", "Outside Foot Control", "Ball Mastery", "Toe Tap Challenge", "Sole Roll Circuit", "Tight Space Turns", "Foundation Touches", "Small Space Weave", "Bounce Control", "Half Turn Control", "Directional First Touch", "Sole Cushion", "High Ball Settle", "Turn on First Touch", "Box Ball Mastery", "Sole Tap Rhythm", "Indoor Figure Eight", "Wall Touch Challenge"]),
        ("Passing", ["Wall Passing", "One Touch Passing", "Weak Foot Passing", "Pass and Turn", "Long Passing", "Two Touch Passing", "Driven Wall Pass", "Indoor Wall Passing", "Triangle Passing", "Outside Foot Pass", "Give and Go", "Passing Gates", "First Time Pass", "Lofted Pass"]),
        ("Goalkeeping", ["Set Position Saves", "Low Diving Saves", "Goalkeeper Footwork", "Angle Positioning", "Throw Distribution", "Cross Collection", "Reaction Saves", "1v1 Goalkeeper", "High Ball Catch", "Scoop Saves", "Quick Hands", "Near Post Saves", "Collapse Dive", "Foot Saves", "Distribution Accuracy"]),
        ("Defense", ["Jockeying", "Defensive Shuffle", "Close Down", "Recovery Run", "Block and Clear", "1v1 Shadow", "Backpedal and Turn", "Interception Steps", "Clear and Recover", "Delay the Attacker", "Cover Shadow", "Tackle Timing", "Wide Channel Defense"]),
        ("Plus Training", ["Elite Finishing Circuit", "Pressure Passing", "Advanced Ball Mastery", "Explosive Dribble", "First Touch Under Pressure", "Match Speed Control", "Complete Midfielder Circuit", "Striker Movement Circuit", "Crossbar Challenge", "Around the World", "Beat the Cone", "Weak Foot Hero", "Skill Move Combo", "Rapid Fire Finishing", "Perfect Pass Streak", "Juggling Ladder"]),
        ("Workout", ["Running", "Abs Circuit", "Arm Strength", "Leg Strength", "Chest Workout", "Full Body Workout", "Agility Sprints", "Recovery Stretch", "Shuttle Runs", "Balance Circuit", "Quick Feet", "Core Stability", "Lateral Hops", "Single Leg Strength", "Mobility Flow"]),
    ]

    static func category(for drillName: String) -> String {
        categories.first(where: { $0.drills.contains(drillName) })?.name ?? "Technical"
    }

    static func imageName(for category: String) -> String {
        switch category {
        case "Indoor Training", "Plus Training":
            "DrillControl"
        default:
            "Drill" + category
        }
    }

    static func imageName(for drillName: String, category: String) -> String {
        let alternateNames: [String: Set<String>] = [
            "Shooting": ["Practice Shooting", "Power Shots", "Target Corners", "Volley Finish"],
            "Dribbling": ["Cone Weave", "Zigzag Sprint", "Figure Eight", "Speed Dribble"],
            "Passing": ["Wall Passing", "One Touch Passing", "Driven Wall Pass", "Weak Foot Passing"],
            "Goalkeeping": ["Low Diving Saves", "Reaction Saves", "Set Position Saves", "1v1 Goalkeeper"],
        ]
        return alternateNames[category]?.contains(drillName) == true
            ? "Drill\(category)2"
            : imageName(for: category)
    }

    static func equipment(for drillName: String, category: String) -> String {
        switch drillName {
        case "Juggling":
            "1 soccer ball"
        case "Ball Mastery", "Toe Tap Challenge", "Sole Roll Circuit", "Tight Space Turns":
            "1 soccer ball, small clear indoor space"
        case "Indoor Wall Passing":
            "1 soft soccer ball, safe wall, small clear indoor space"
        case "Pass and Turn":
            "1 soccer ball, wall, 3 cones"
        case "Wall Passing", "One Touch Passing", "Weak Foot Passing", "Driven Wall Pass":
            "1 soccer ball, wall, 1 marker cone"
        case "Wall Control", "Cushion Touch", "Outside Foot Control":
            "1 soccer ball, wall, 4 cones"
        case "Running", "Agility Sprints", "Shuttle Runs":
            "No equipment required"
        case "Recovery Stretch", "Abs Circuit", "Arm Strength", "Chest Workout",
             "Full Body Workout", "Leg Strength":
            "No equipment required"
        case "Goalkeeper Footwork", "Angle Positioning":
            "4 cones, goalkeeper gloves"
        case "Defensive Shuffle", "Close Down", "Recovery Run", "Backpedal and Turn":
            "2–4 cones"
        default:
            switch category {
            case "Shooting": "1 soccer ball, goal or marked target, 4–8 cones"
            case "Dribbling": "1 soccer ball, 6–8 cones"
            case "Passing": "1 soccer ball, wall or partner, 2 cones"
            case "Control": "1 soccer ball, 4 cones, wall or partner when instructed"
            case "Goalkeeping": "1 soccer ball, goalkeeper gloves, goal, partner"
            case "Defense": "1 soccer ball, 4 cones, partner when instructed"
            default: "Cones, water, exercise mat when instructed"
            }
        }
    }

    static func focus(for category: String) -> String {
        switch category {
        case "Shooting": "Technique • Accuracy • Finishing"
        case "Dribbling": "Close control • Speed • Change of direction"
        case "Passing": "First touch • Accuracy • Weight of pass"
        case "Control", "Indoor Training": "Soft touch • Balance • Ball mastery"
        case "Goalkeeping": "Set position • Handling • Reactions"
        case "Defense": "Footwork • Patience • Recovery"
        default: "Strength • Speed • Mobility"
        }
    }
}

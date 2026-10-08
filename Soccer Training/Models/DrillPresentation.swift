// DrillPresentation.swift
// Maps a drill name to its category, artwork, equipment list, and focus text.
// Used by AllDrillsView, DrillListView, and DrillTimerView.

import Foundation

enum DrillPresentation {
    static let categories: [(name: String, drills: Set<String>)] = [
        ("Shooting", ["Practice Shooting", "Quick Shot", "Dribble and Shoot", "First Touch Finish", "Target Corners", "Power Shots", "Weak Foot Finishing", "Turn and Shoot", "Volley Finish", "Near Post Finish", "Cutback Finish", "Far Post Finish", "Low Driven Finish", "Rebound Finish", "One Touch Finish", "Instep Drive Finish", "Half Volley Finish", "Driven Low Finish", "Curl Shot Finish", "First Time Finish", "Angled Run Finish", "Finesse Corner Finish", "Inside Foot Placement", "Outside Foot Finish", "Across the Body Finish", "Set Piece Free Kick", "Penalty Spot Finish", "Backpost Tap In", "Knuckleball Finish", "Finishing Clock", "Pressure Finish Gauntlet"]),
        ("Dribbling", ["Cone Weave", "Speed Dribble", "Box Dribble", "L-Drag Turn", "Stop and Go", "Pullback Turn", "Figure Eight", "Zigzag Sprint", "Scissors Move", "Change of Pace", "Shield and Turn", "Cruyff Turn", "V-Cut Dribble", "Double Touch", "Body Feint", "Step Over Exit", "Drag Push", "Slalom Control", "Lane Change Dribble", "Push and Explode", "Sprint and Shield", "Dribble Gauntlet", "Chain Move Challenge"]),
        ("Control", ["Juggling", "Wall Control", "Inside-Outside Touches", "Sole Roll and Push", "Aerial Control", "Chest Control", "Outside Foot Control", "Ball Mastery", "Toe Tap Challenge", "Sole Roll Circuit", "Tight Space Turns", "Foundation Touches", "Small Space Weave", "Bounce Control", "Half Turn Control", "Directional First Touch", "Sole Cushion", "High Ball Settle", "Turn on First Touch", "Box Ball Mastery", "Sole Tap Rhythm", "Indoor Figure Eight", "Wall Touch Challenge", "Juggle to Control", "Knee Control Drill", "Spin Away Control", "Instep Cushion", "One Touch Settle", "Reaction Control Gates", "Volley Cushion", "Spin and Pass Control", "Wall Rebound Control", "Low Driven Cushion", "Thigh to Foot Control", "Juggle and Volley Control", "Low Ball Cushion", "Two Foot Juggling", "Control Gauntlet", "Pressure Touch Challenge"]),
        ("Passing", ["Wall Passing", "One Touch Passing", "Weak Foot Passing", "Pass and Turn", "Long Passing", "Two Touch Passing", "Driven Wall Pass", "Indoor Wall Passing", "Triangle Passing", "Outside Foot Pass", "Give and Go", "Passing Gates", "First Time Pass", "Lofted Pass", "Lofted Chip Pass", "Rapid Rebound Passing", "Switch Play Pass", "Through Ball Timing", "Backheel Pass", "Disguised Pass", "Quick Combination Pass", "Driven Diagonal Pass", "Blind Side Pass", "Overlap Pass and Run", "Angled Wall Pass", "Third Man Pass", "Short Side Pass", "Weighted Pass Gates", "Curved Wall Pass", "One Touch Wall Combination", "Reverse Pass", "Driven Target Pass", "Chip Over Gate", "Wide to Center Pass", "Pass Under Pressure", "Passing Gauntlet", "Rapid Switch Challenge"]),
        ("Goalkeeping", ["Set Position Saves", "Low Diving Saves", "Goalkeeper Footwork", "Angle Positioning", "Throw Distribution", "Cross Collection", "Reaction Saves", "1v1 Goalkeeper", "High Ball Catch", "Scoop Saves", "Quick Hands", "Near Post Saves", "Collapse Dive", "Foot Saves", "Distribution Accuracy", "Parry and Recover", "Narrow Angle Saves", "Rebound Control Saves", "Low Drive Parry", "Command the Box", "One-on-One Recovery", "High Press Sweeper", "Deflection Saves", "One Hand Parry", "Short Corner Command", "Breakaway Saves", "Footwork Reset Saves", "Tip Over the Bar", "Low Spring Save", "Punch Clearance", "Set and React Saves", "Narrow the Angle Sprint", "Double Save Reaction"]),
        ("Defense", ["Jockeying", "Defensive Shuffle", "Close Down", "Recovery Run", "Block and Clear", "1v1 Shadow", "Backpedal and Turn", "Interception Steps", "Clear and Recover", "Delay the Attacker", "Cover Shadow", "Tackle Timing", "Wide Channel Defense", "Standing Tackle Timing", "Press and Contain", "Show Inside Press", "Double Team Recovery", "Last Man Cover", "Zonal Shuffle", "Channel Press", "Shoulder Block Tackle", "Slide Tackle Timing", "Overlap Tracking", "Compact Line Shuffle", "Aerial Duel Timing", "Press and Recover", "Mark Tight Shadow", "Intercept and Clear", "Hold the Line", "Recovery Sprint Angle", "Read the Pass"]),
        ("Plus Training", ["Elite Finishing Circuit", "Pressure Passing", "Advanced Ball Mastery", "Explosive Dribble", "First Touch Under Pressure", "Match Speed Control", "Complete Midfielder Circuit", "Striker Movement Circuit", "Crossbar Challenge", "Around the World", "Beat the Cone", "Weak Foot Hero", "Skill Move Combo", "Perfect Pass Streak", "Juggling Ladder", "Triangle Possession Circuit", "Shoot-Dribble-Pass Combo", "1v1 to Finish Transition", "Four Corner Passing Circuit", "Receive Turn Finish Combo", "Defensive Press to Counter", "Full Pitch Transition Circuit", "Long Switch and Finish", "Overload Finishing Circuit", "Press Trigger Circuit", "Box to Box Circuit", "Quick Combination Finish", "Game Speed Possession", "Attacking Third Combination", "High Press Counter Circuit", "Possession Under Pressure Circuit", "Full Speed Skill Combo", "Rapid Fire Volleys", "Precision Cross Finish", "Technical Mastery Circuit", "One Touch Wonder", "Elite Touch and Turn", "Pressure Cooker Finishing", "Target Practice Circuit"]),
        ("Workout", ["Running", "Abs Circuit", "Arm Strength", "Leg Strength", "Chest Workout", "Full Body Workout", "Agility Sprints", "Recovery Stretch", "Shuttle Runs", "Balance Circuit", "Quick Feet", "Core Stability", "Lateral Hops", "Single Leg Strength", "Mobility Flow", "Plyometric Jumps", "Sprint Starts", "Hip Mobility Flow", "Resistance Band Activation", "Cool Down Stretch", "Explosive Start Sprints", "Ladder Footwork Drill", "Plank Variations", "Dynamic Warm Up", "Jump Rope Conditioning"]),
        ("Technique", ["Roulette Spin", "Ronaldo Chop", "Elastico Flick", "Hocus Pocus Spin", "Berba Spin Turn", "Matthews Fake", "Rainbow Flick", "Nutmeg Attempt", "Chop and Burst", "Inside Hook Turn", "Rivelino Flick", "Double Scissors", "Fake Shot Dribble", "Cut Inside Burst", "La Croqueta", "Okocha Shoulder Drop", "Sombrero Flick", "Heel to Heel Roll"]),
        ("Speed & Finishing", ["Snap Shot Finish", "Rising Drive Finish", "Laces Drive Finish", "One v One Finish", "Half Space Finish", "Driven Near Post Finish", "Dipping Volley Finish", "Rapid Fire Finishing", "Speed Finishing Ladder", "Agility Gate Sprint", "Full Field Sprint Finish", "Finish Under Fatigue"]),
        ("First Touch", ["First Touch Gates", "Thigh Control", "Cushion Touch", "Spin Out of Pressure", "Receive Under Pressure", "Two Touch Mastery", "Open Body Control", "First Touch Direction Change", "Receive Behind the Line", "Back Foot Control"]),
        ("Soccer IQ", ["Scan Before Touch", "Third Man Movement", "Quick Decision Gates", "Press Trigger Recognition", "Switch of Play Reading", "Numbers Up Counter", "Game Speed Scanning", "Decision Under Pressure", "Field Awareness Circuit", "Read and React Passing"]),
    ]

    /// Drills meant for a small, safe indoor space. Flagged by name so their category's
    /// gameplay flow (timing, scoring) never changes — only their artwork differs.
    static let indoorDrillNames: Set<String> = [
        "Ball Mastery", "Toe Tap Challenge", "Sole Roll Circuit", "Tight Space Turns",
        "Indoor Wall Passing", "Indoor Figure Eight",
    ]

    static func isIndoor(_ drillName: String) -> Bool {
        indoorDrillNames.contains(drillName) || drillName.localizedCaseInsensitiveContains("indoor")
    }

    static func category(for drillName: String) -> String {
        categories.first(where: { $0.drills.contains(drillName) })?.name ?? "Technical"
    }

    /// A stable 0...1 hue derived from the drill's name. We only ship a handful of
    /// real stock photos, so every drill tints its shared photo with its own color —
    /// two drills with the same underlying image still look visibly different.
    static func photoHue(for drillName: String) -> Double {
        Double(stableHash(drillName) % 360) / 360
    }

    /// A simple, stable string hash (djb2). Swift's built-in `Hasher` is seeded
    /// randomly per process, so it can't be used here without the tint changing
    /// on every app launch.
    private static func stableHash(_ string: String) -> Int {
        var hash = 5381
        for scalar in string.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return abs(hash)
    }

    static func imageName(for category: String) -> String {
        switch category {
        case "Indoor Training":
            "IndoorSoccer1"
        case "Plus Training", "First Touch", "Soccer IQ":
            "DrillControl"
        case "Technique":
            "DrillDribbling"
        case "Speed & Finishing":
            "DrillShooting"
        default:
            "Drill" + category
        }
    }

    /// A single SF Symbol per category, used by both the Drills tab's category
    /// grid and each category's drill list so new categories only need one case
    /// added here instead of in every view that shows an icon.
    static func icon(for category: String) -> String {
        switch category {
        case "Shooting": "scope"
        case "Dribbling": "figure.soccer"
        case "Passing": "arrow.left.arrow.right"
        case "Control": "circle.grid.cross.fill"
        case "Goalkeeping": "hand.raised.fill"
        case "Defense": "shield.fill"
        case "Indoor Training": "house.fill"
        case "Plus Training": "crown.fill"
        case "Workout": "figure.strengthtraining.traditional"
        case "Technique": "wand.and.stars"
        case "Speed & Finishing": "bolt.fill"
        case "First Touch": "hand.tap.fill"
        case "Soccer IQ": "brain.head.profile"
        default: "figure.run"
        }
    }

    static func imageName(for drillName: String, category: String) -> String {
        // Every indoor drill uses one of several purpose-built indoor soccer photos.
        // The stable hash keeps each drill's artwork consistent between launches.
        if category == "Indoor Training" || isIndoor(drillName) {
            let indoorImages = ["IndoorSoccer1", "IndoorSoccer2", "IndoorSoccer3", "IndoorSoccer4"]
            return indoorImages[stableHash(drillName) % indoorImages.count]
        }

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
        case "Defensive Shuffle", "Close Down", "Recovery Run", "Backpedal and Turn",
             "Jockeying", "Interception Steps", "Clear and Recover", "Delay the Attacker",
             "Wide Channel Defense":
            "2–4 cones"
        case "Press Trigger Circuit":
            "4–8 cones"
        default:
            switch category {
            case "Shooting": "1 soccer ball, goal or marked target, 4–8 cones"
            case "Dribbling": "1 soccer ball, 6–8 cones"
            case "Passing": "1 soccer ball, wall or partner, 2 cones"
            case "Control": "1 soccer ball, 4 cones, wall or partner when instructed"
            case "Goalkeeping": "1 soccer ball, goalkeeper gloves, goal, partner"
            case "Defense": "1 soccer ball, 4 cones, partner when instructed"
            case "Technique": "1 soccer ball, 2–4 cones, small clear space"
            case "Speed & Finishing": "1 soccer ball, goal or marked target, cones for sprint markers"
            case "First Touch": "1 soccer ball, wall or partner, 2–4 cones"
            case "Soccer IQ": "1 soccer ball, cones for visual cues, partner when instructed"
            case "Plus Training": "1 soccer ball, 4–8 cones, goal or wall when instructed"
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
        case "Technique": "Skill moves • Close control • Confidence on the ball"
        case "Speed & Finishing": "Sprint speed • Composure • Clinical finishing"
        case "First Touch": "Receiving • Touch quality • Quick release"
        case "Soccer IQ": "Scanning • Decision-making • Game awareness"
        default: "Strength • Speed • Mobility"
        }
    }
}

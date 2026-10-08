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

        // More player choices across every training category.
        SessionTemplate(
            name: "Target Accuracy",
            detail: "Pick out corners with controlled, accurate finishes",
            category: "Shooting",
            drillNames: ["Target Corners", "Low Driven Finish", "Far Post Finish", "One Touch Finish"]
        ),
        SessionTemplate(
            name: "Quick-Fire Finishing",
            detail: "Get shots away quickly and react to rebounds",
            category: "Shooting",
            drillNames: ["Quick Shot", "First Touch Finish", "Rebound Finish", "Volley Finish"]
        ),

        SessionTemplate(
            name: "Close Control Circuit",
            detail: "Keep the ball close through tight patterns",
            category: "Dribbling",
            drillNames: ["Cone Weave", "Box Dribble", "Figure Eight", "V-Cut Dribble"]
        ),
        SessionTemplate(
            name: "Deceptive Moves",
            detail: "Use feints and combinations to unbalance defenders",
            category: "Dribbling",
            drillNames: ["Double Touch", "Body Feint", "Drag Push", "Chain Move Challenge"]
        ),

        SessionTemplate(
            name: "Passing Accuracy",
            detail: "Hit gates and targets with different techniques",
            category: "Passing",
            drillNames: ["Passing Gates", "Outside Foot Pass", "Lofted Pass", "Weak Foot Passing"]
        ),
        SessionTemplate(
            name: "Fast Passing Rhythm",
            detail: "Move the ball quickly with one and two touches",
            category: "Passing",
            drillNames: ["Two Touch Passing", "Driven Wall Pass", "First Time Pass", "Rapid Switch Challenge"]
        ),

        SessionTemplate(
            name: "Ground Control",
            detail: "Master close touches, rolls, and turns",
            category: "Control",
            drillNames: ["Inside-Outside Touches", "Sole Roll and Push", "Outside Foot Control", "Half Turn Control"]
        ),
        SessionTemplate(
            name: "Control Under Pressure",
            detail: "Settle difficult balls and escape quickly",
            category: "Control",
            drillNames: ["Aerial Control", "High Ball Settle", "Turn on First Touch", "Pressure Touch Challenge"]
        ),

        SessionTemplate(
            name: "Goalkeeper Footwork",
            detail: "Move, set, and recover for the next save",
            category: "Goalkeeping",
            drillNames: ["Goalkeeper Footwork", "Angle Positioning", "Quick Hands", "Collapse Dive"]
        ),
        SessionTemplate(
            name: "One-on-One Goalkeeper",
            detail: "Close angles and make reaction saves",
            category: "Goalkeeping",
            drillNames: ["1v1 Goalkeeper", "Foot Saves", "Near Post Saves", "Reaction Saves"]
        ),

        SessionTemplate(
            name: "Press and Delay",
            detail: "Close down safely and slow the attacker",
            category: "Defense",
            drillNames: ["Close Down", "Delay the Attacker", "Cover Shadow", "Wide Channel Defense"]
        ),
        SessionTemplate(
            name: "Defensive Movement",
            detail: "Shuffle, recover, intercept, and clear",
            category: "Defense",
            drillNames: ["Defensive Shuffle", "Recovery Run", "Interception Steps", "Clear and Recover"]
        ),

        SessionTemplate(
            name: "Elite Ball Mastery",
            detail: "Advanced touches and moves at match speed",
            category: "Plus Training",
            drillNames: ["Advanced Ball Mastery", "Match Speed Control", "Skill Move Combo", "Elite Touch and Turn"]
        ),
        SessionTemplate(
            name: "Challenge Session",
            detail: "Test accuracy, juggling, and weak-foot quality",
            category: "Plus Training",
            drillNames: ["Crossbar Challenge", "Weak Foot Hero", "Perfect Pass Streak", "Juggling Ladder"]
        ),
        SessionTemplate(
            name: "Match-Speed Attacker",
            detail: "Explosive combinations and finishing at game intensity",
            category: "Plus Training",
            drillNames: ["Explosive Dribble", "Attacking Third Combination", "Quick Combination Finish", "Pressure Cooker Finishing"]
        ),
        SessionTemplate(
            name: "Elite Midfielder",
            detail: "Receive, scan, combine, and control the tempo",
            category: "Plus Training",
            drillNames: ["First Touch Under Pressure", "Pressure Passing", "Complete Midfielder Circuit", "Game Speed Possession"]
        ),
        SessionTemplate(
            name: "High-Press Competitor",
            detail: "Win the ball and attack immediately",
            category: "Plus Training",
            drillNames: ["Press Trigger Circuit", "High Press Counter Circuit", "Defensive Press to Counter", "Full Pitch Transition Circuit"]
        ),
        SessionTemplate(
            name: "Technical Excellence",
            detail: "Demand clean execution at full speed",
            category: "Plus Training",
            drillNames: ["Technical Mastery Circuit", "Elite Touch and Turn", "One Touch Wonder", "Full Speed Skill Combo"]
        ),
        SessionTemplate(
            name: "Clinical Striker",
            detail: "Movement, precision, volleys, and pressure finishing",
            category: "Plus Training",
            drillNames: ["Striker Movement Circuit", "Precision Cross Finish", "Rapid Fire Volleys", "Target Practice Circuit"]
        ),
        SessionTemplate(
            name: "Complete Elite Test",
            detail: "A demanding session covering every major skill",
            category: "Plus Training",
            drillNames: ["Shoot-Dribble-Pass Combo", "Possession Under Pressure Circuit", "Box to Box Circuit", "Elite Finishing Circuit"]
        ),

        SessionTemplate(
            name: "Cuts and Changes",
            detail: "Change direction sharply and accelerate away",
            category: "Technique",
            drillNames: ["Ronaldo Chop", "Matthews Fake", "Chop and Burst", "Inside Hook Turn"]
        ),
        SessionTemplate(
            name: "Creative Flair",
            detail: "Practice expressive moves for confident 1v1 play",
            category: "Technique",
            drillNames: ["Rainbow Flick", "Elastico Flick", "La Croqueta", "Okocha Shoulder Drop"]
        ),

        SessionTemplate(
            name: "Explosive Speed",
            detail: "Accelerate, change direction, and finish",
            category: "Speed & Finishing",
            drillNames: ["Agility Gate Sprint", "Speed Finishing Ladder", "Full Field Sprint Finish", "Snap Shot Finish"]
        ),
        SessionTemplate(
            name: "Finish Under Pressure",
            detail: "Stay composed after intense movement",
            category: "Speed & Finishing",
            drillNames: ["One v One Finish", "Rapid Fire Finishing", "Finish Under Fatigue", "Rising Drive Finish"]
        ),

        SessionTemplate(
            name: "Open Body Receiving",
            detail: "Receive side-on and move forward immediately",
            category: "First Touch",
            drillNames: ["Open Body Control", "Back Foot Control", "Cushion Touch", "First Touch Gates"]
        ),
        SessionTemplate(
            name: "Turning First Touch",
            detail: "Use the first touch to turn away from pressure",
            category: "First Touch",
            drillNames: ["Spin Out of Pressure", "First Touch Direction Change", "Receive Under Pressure", "Two Touch Mastery"]
        ),

        SessionTemplate(
            name: "Playing Through Pressure",
            detail: "Recognize pressure and find the best exit",
            category: "Soccer IQ",
            drillNames: ["Press Trigger Recognition", "Switch of Play Reading", "Decision Under Pressure", "Read and React Passing"]
        ),
        SessionTemplate(
            name: "Smart Movement",
            detail: "Scan, create space, and support the next play",
            category: "Soccer IQ",
            drillNames: ["Scan Before Touch", "Third Man Movement", "Numbers Up Counter", "Field Awareness Circuit"]
        ),

        SessionTemplate(
            name: "Lower Body Power",
            detail: "Build strong legs, balance, and explosive movement",
            category: "Workout",
            drillNames: ["Leg Strength", "Single Leg Strength", "Lateral Hops", "Balance Circuit"]
        ),
        SessionTemplate(
            name: "Full Body Conditioning",
            detail: "Train strength, movement, and endurance together",
            category: "Workout",
            drillNames: ["Full Body Workout", "Arm Strength", "Core Stability", "Shuttle Runs"]
        ),

        SessionTemplate(
            name: "Indoor Turning",
            detail: "Sharp turns and close control in a small space",
            category: "Indoor Training",
            drillNames: ["Tight Space Turns", "Indoor Figure Eight", "Small Space Weave", "Sole Roll Circuit"]
        ),
        SessionTemplate(
            name: "Indoor Touch Challenge",
            detail: "Build rhythm and clean touches without a large field",
            category: "Indoor Training",
            drillNames: ["Foundation Touches", "Sole Tap Rhythm", "Toe Tap Challenge", "Wall Touch Challenge"]
        ),
        SessionTemplate(
            name: "Complete Shooting Session",
            detail: "Technique, power, placement, and pressure finishing",
            category: "Shooting",
            drillNames: ["Practice Shooting", "Power Shots", "Target Corners", "Pressure Finish Gauntlet"]
        ),
        SessionTemplate(
            name: "Complete Dribbling Session",
            detail: "Close control, turns, speed, and a final challenge",
            category: "Dribbling",
            drillNames: ["Cone Weave", "Pullback Turn", "Speed Dribble", "Dribble Gauntlet"]
        ),
        SessionTemplate(
            name: "Complete Passing Session",
            detail: "Accuracy, first-time play, range, and pressure",
            category: "Passing",
            drillNames: ["Wall Passing", "First Time Pass", "Long Passing", "Passing Gauntlet"]
        ),
        SessionTemplate(
            name: "Complete Control Session",
            detail: "Ground, aerial, turning, and pressure control",
            category: "Control",
            drillNames: ["Wall Control", "Aerial Control", "Turn on First Touch", "Control Gauntlet"]
        ),
        SessionTemplate(
            name: "Complete Goalkeeper Session",
            detail: "Set position, handling, reactions, and distribution",
            category: "Goalkeeping",
            drillNames: ["Set Position Saves", "High Ball Catch", "Reaction Saves", "Distribution Accuracy"]
        ),
        SessionTemplate(
            name: "Complete Defender Session",
            detail: "Footwork, pressure, tackling, and recovery",
            category: "Defense",
            drillNames: ["Defensive Shuffle", "Close Down", "Tackle Timing", "Recovery Run"]
        ),
        SessionTemplate(
            name: "Complete Technique Session",
            detail: "Four different moves to practice and combine",
            category: "Technique",
            drillNames: ["Roulette Spin", "Ronaldo Chop", "La Croqueta", "Rainbow Flick"]
        ),
        SessionTemplate(
            name: "Complete First Touch Session",
            detail: "Receive, cushion, turn, and escape pressure",
            category: "First Touch",
            drillNames: ["First Touch Gates", "Cushion Touch", "Spin Out of Pressure", "Receive Under Pressure"]
        ),
        SessionTemplate(
            name: "Complete Soccer IQ Session",
            detail: "Scanning, movement, pressure, and decisions",
            category: "Soccer IQ",
            drillNames: ["Scan Before Touch", "Third Man Movement", "Press Trigger Recognition", "Decision Under Pressure"]
        ),
        SessionTemplate(
            name: "Complete Fitness Session",
            detail: "Mobility, speed, strength, and recovery",
            category: "Workout",
            drillNames: ["Mobility Flow", "Agility Sprints", "Full Body Workout", "Recovery Stretch"]
        ),
    ]

    static func templates(for category: String) -> [SessionTemplate] {
        templates.filter { $0.category == category }
    }
}

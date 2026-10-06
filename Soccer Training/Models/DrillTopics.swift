// DrillTopics.swift
// The drill library's topic lists: every drill the Drills tab shows, grouped
// by topic. Pure data, kept separate so the catalog logic stays readable.

import Foundation

enum DrillTopics {
    static let all: [Topic] = [
        Topic(name: "Shooting", drills: [
            Drill(name: "Practice Shooting"), Drill(name: "Quick Shot"), Drill(name: "Dribble and Shoot"),
            Drill(name: "First Touch Finish"), Drill(name: "Target Corners"), Drill(name: "Power Shots"),
            Drill(name: "Weak Foot Finishing"), Drill(name: "Turn and Shoot"), Drill(name: "Volley Finish"),
            Drill(name: "Near Post Finish"), Drill(name: "Cutback Finish"),
            Drill(name: "Far Post Finish"), Drill(name: "Low Driven Finish"),
            Drill(name: "Rebound Finish"), Drill(name: "One Touch Finish"),
            Drill(name: "Finishing Clock"), Drill(name: "Pressure Finish Gauntlet"),
        ]),
        Topic(name: "Dribbling", drills: [
            Drill(name: "Cone Weave"), Drill(name: "Speed Dribble"), Drill(name: "Box Dribble"),
            Drill(name: "L-Drag Turn"), Drill(name: "Stop and Go"), Drill(name: "Pullback Turn"),
            Drill(name: "Figure Eight"), Drill(name: "Zigzag Sprint"), Drill(name: "Scissors Move"),
            Drill(name: "Change of Pace"), Drill(name: "Shield and Turn"), Drill(name: "Cruyff Turn"),
            Drill(name: "V-Cut Dribble"), Drill(name: "Double Touch"),
            Drill(name: "Body Feint"), Drill(name: "Step Over Exit"),
            Drill(name: "Drag Push"), Drill(name: "Slalom Control"),
            Drill(name: "Dribble Gauntlet"), Drill(name: "Chain Move Challenge"),
        ]),
        Topic(name: "Passing", drills: [
            Drill(name: "Wall Passing"), Drill(name: "One Touch Passing"), Drill(name: "Weak Foot Passing"),
            Drill(name: "Pass and Turn"), Drill(name: "Long Passing"),
            Drill(name: "Two Touch Passing"), Drill(name: "Driven Wall Pass"),
            Drill(name: "Triangle Passing"), Drill(name: "Outside Foot Pass"),
            Drill(name: "Give and Go"), Drill(name: "Passing Gates"),
            Drill(name: "First Time Pass"), Drill(name: "Lofted Pass"),
            Drill(name: "Passing Gauntlet"), Drill(name: "Rapid Switch Challenge"),
        ]),
        Topic(name: "Control", drills: [
            Drill(name: "Juggling"), Drill(name: "Wall Control"), Drill(name: "Inside-Outside Touches"),
            Drill(name: "Sole Roll and Push"), Drill(name: "Aerial Control"),
            Drill(name: "Chest Control"),
            Drill(name: "Outside Foot Control"), Drill(name: "Bounce Control"), Drill(name: "Half Turn Control"),
            Drill(name: "Directional First Touch"), Drill(name: "Sole Cushion"),
            Drill(name: "High Ball Settle"), Drill(name: "Turn on First Touch"),
            Drill(name: "Control Gauntlet"), Drill(name: "Pressure Touch Challenge"),
        ]),
        Topic(name: "Indoor Training", drills: [
            Drill(name: "Ball Mastery"), Drill(name: "Toe Tap Challenge"),
            Drill(name: "Sole Roll Circuit"), Drill(name: "Tight Space Turns"),
            Drill(name: "Indoor Wall Passing"), Drill(name: "Foundation Touches"), Drill(name: "Small Space Weave"),
            Drill(name: "Box Ball Mastery"), Drill(name: "Sole Tap Rhythm"),
            Drill(name: "Indoor Figure Eight"), Drill(name: "Wall Touch Challenge"),
        ]),
        Topic(name: "Goalkeeping", drills: [
            Drill(name: "Set Position Saves"), Drill(name: "Low Diving Saves"), Drill(name: "Goalkeeper Footwork"),
            Drill(name: "Angle Positioning"), Drill(name: "Throw Distribution"), Drill(name: "Cross Collection"),
            Drill(name: "Reaction Saves"), Drill(name: "1v1 Goalkeeper"), Drill(name: "High Ball Catch"),
            Drill(name: "Scoop Saves"), Drill(name: "Quick Hands"),
            Drill(name: "Near Post Saves"), Drill(name: "Collapse Dive"),
            Drill(name: "Foot Saves"), Drill(name: "Distribution Accuracy"),
        ]),
        Topic(name: "Defense", drills: [
            Drill(name: "Jockeying"), Drill(name: "Defensive Shuffle"), Drill(name: "Close Down"),
            Drill(name: "Recovery Run"), Drill(name: "Block and Clear"),
            Drill(name: "1v1 Shadow"), Drill(name: "Backpedal and Turn"),
            Drill(name: "Interception Steps"), Drill(name: "Clear and Recover"),
            Drill(name: "Delay the Attacker"), Drill(name: "Cover Shadow"),
            Drill(name: "Tackle Timing"), Drill(name: "Wide Channel Defense"),
        ]),
        Topic(name: "Plus Training", drills: [
            Drill(name: "Elite Finishing Circuit"), Drill(name: "Pressure Passing"),
            Drill(name: "Advanced Ball Mastery"), Drill(name: "Explosive Dribble"),
            Drill(name: "First Touch Under Pressure"), Drill(name: "Match Speed Control"),
            Drill(name: "Complete Midfielder Circuit"), Drill(name: "Striker Movement Circuit"),
            Drill(name: "Crossbar Challenge"), Drill(name: "Around the World"),
            Drill(name: "Beat the Cone"), Drill(name: "Weak Foot Hero"),
            Drill(name: "Skill Move Combo"),
            Drill(name: "Perfect Pass Streak"), Drill(name: "Juggling Ladder"),
            Drill(name: "Rapid Fire Volleys"), Drill(name: "Precision Cross Finish"),
            Drill(name: "Technical Mastery Circuit"),
            Drill(name: "One Touch Wonder"), Drill(name: "Elite Touch and Turn"),
            Drill(name: "Pressure Cooker Finishing"),
            Drill(name: "Target Practice Circuit"),
        ]),
        Topic(name: "Workout", drills: [
            Drill(name: "Running"), Drill(name: "Abs Circuit"), Drill(name: "Arm Strength"),
            Drill(name: "Leg Strength"), Drill(name: "Chest Workout"), Drill(name: "Full Body Workout"),
            Drill(name: "Agility Sprints"), Drill(name: "Recovery Stretch"), Drill(name: "Shuttle Runs"),
            Drill(name: "Balance Circuit"), Drill(name: "Quick Feet"),
            Drill(name: "Core Stability"), Drill(name: "Lateral Hops"),
            Drill(name: "Single Leg Strength"), Drill(name: "Mobility Flow"),
        ]),
        Topic(name: "Technique", drills: [
            Drill(name: "Roulette Spin"), Drill(name: "Ronaldo Chop"), Drill(name: "Elastico Flick"),
            Drill(name: "Hocus Pocus Spin"), Drill(name: "Berba Spin Turn"), Drill(name: "Matthews Fake"),
            Drill(name: "Rainbow Flick"), Drill(name: "Nutmeg Attempt"), Drill(name: "Chop and Burst"),
            Drill(name: "Inside Hook Turn"), Drill(name: "La Croqueta"), Drill(name: "Okocha Shoulder Drop"),
        ]),
        Topic(name: "Speed & Finishing", drills: [
            Drill(name: "Snap Shot Finish"), Drill(name: "Rising Drive Finish"), Drill(name: "Laces Drive Finish"),
            Drill(name: "One v One Finish"), Drill(name: "Rapid Fire Finishing"),
            Drill(name: "Speed Finishing Ladder"), Drill(name: "Agility Gate Sprint"),
            Drill(name: "Full Field Sprint Finish"), Drill(name: "Finish Under Fatigue"),
        ]),
        Topic(name: "First Touch", drills: [
            Drill(name: "First Touch Gates"), Drill(name: "Thigh Control"), Drill(name: "Cushion Touch"),
            Drill(name: "Spin Out of Pressure"), Drill(name: "Receive Under Pressure"),
            Drill(name: "Two Touch Mastery"), Drill(name: "Open Body Control"),
            Drill(name: "First Touch Direction Change"), Drill(name: "Receive Behind the Line"),
            Drill(name: "Back Foot Control"),
        ]),
        Topic(name: "Soccer IQ", drills: [
            Drill(name: "Scan Before Touch"), Drill(name: "Third Man Movement"),
            Drill(name: "Quick Decision Gates"), Drill(name: "Press Trigger Recognition"),
            Drill(name: "Switch of Play Reading"), Drill(name: "Numbers Up Counter"),
            Drill(name: "Game Speed Scanning"), Drill(name: "Decision Under Pressure"),
            Drill(name: "Field Awareness Circuit"), Drill(name: "Read and React Passing"),
        ]),
    ]
}

// DrillTimerView.swift
// Runs a single drill: countdown or cooldown timer, Pass and Turn callouts,
// instructions, score entry, and progress recording.

import AVFoundation
import SwiftUI

struct DrillTimerView: View {
    private enum ScoreField: Hashable {
        case primary
        case secondary
    }

    let drill: Drill
    let weeklyTaskID: String?
    let weeklyDay: String?
    /// Called once the drill's result is recorded. Session runners use it to advance.
    var onCompleted: (() -> Void)? = nil
    @Binding var totalPoints: Int
    @AppStorage("completedWeeklyTasks") private var completedWeeklyTasks = ""
    @AppStorage("completedWeeklyDays") private var completedWeeklyDays = ""
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0
    @AppStorage("playerXP") private var playerXP = 0
    @AppStorage("categoryXP") private var categoryXPText = ""
    @AppStorage("categoryMinutes") private var categoryMinutesText = ""
    @AppStorage("totalGoals") private var totalGoals = 0
    @AppStorage("totalShots") private var totalShots = 0
    @AppStorage("totalPasses") private var totalPasses = 0
    @AppStorage("totalDribblingAttempts") private var totalDribblingAttempts = 0
    @AppStorage("totalControls") private var totalControls = 0
    @AppStorage("totalSessions") private var totalSessions = 0
    @AppStorage("trainingStreak") private var trainingStreak = 0
    @AppStorage("lastTrainingDate") private var lastTrainingDate = ""
    @AppStorage("rewardBoxes") private var rewardBoxes = 0
    @State private var timeLeft: Int
    @State private var timerActive = false
    @State private var timer: Timer?
    @State private var goalsScored = ""
    @State private var leftFootGoals = ""
    @State private var rightFootGoals = ""
    @State private var controlBoxSize = ""
    @State private var successfulTraps = ""
    @State private var attemptsCompleted = ""
    @State private var successfulAttempts = ""
    @State private var awardedPoints = 0
    @State private var awardedXP = 0
    @State private var didRecordProgress = false
    @State private var calloutCount = 0
    @State private var currentCone = 0
    @State private var calloutsActive = false
    @State private var readyCountdown = 0
    @State private var passTurnStartTask: Task<Void, Never>?
    @State private var trainingDifficulty = DrillDifficulty.easy
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var showScoreQuestion = false
    @State private var showThankYou = false
    @State private var shootingStarted = false
    @State private var shootingCooldown = 60
    @State private var isCompleted = false
    @FocusState private var focusedScoreField: ScoreField?

    init(
        drill: Drill,
        totalPoints: Binding<Int>,
        weeklyTaskID: String? = nil,
        weeklyDay: String? = nil,
        onCompleted: (() -> Void)? = nil
    ) {
        self.drill = drill
        self.weeklyTaskID = weeklyTaskID
        self.weeklyDay = weeklyDay
        self.onCompleted = onCompleted
        _totalPoints = totalPoints
        _timeLeft = State(initialValue: Self.duration(for: drill.name))
    }

    static func duration(for drillName: String) -> Int {
        switch drillName {
        case "Triangle Possession Circuit", "Shoot-Dribble-Pass Combo", "1v1 to Finish Transition",
             "Four Corner Passing Circuit", "Receive Turn Finish Combo", "Defensive Press to Counter",
             "Full Pitch Transition Circuit", "Long Switch and Finish",
             "Overload Finishing Circuit", "Press Trigger Circuit", "Box to Box Circuit",
             "Quick Combination Finish", "Game Speed Possession",
             "Attacking Third Combination", "High Press Counter Circuit", "Finish Under Fatigue",
             "Possession Under Pressure Circuit", "Full Speed Skill Combo":
            480
        case "Full Body Workout", "Running":
            360
        case "Ball Mastery", "Indoor Wall Passing":
            300
        case "Sole Roll Circuit", "Tight Space Turns":
            240
        case "Toe Tap Challenge":
            180
        case "Agility Sprints", "Shuttle Runs", "Leg Strength", "Chest Workout":
            300
        case "Abs Circuit", "Arm Strength":
            240
        case "Recovery Stretch":
            180
        case "Near Post Finish", "Cutback Finish":
            300
        case "V-Cut Dribble", "Double Touch", "Triangle Passing", "Outside Foot Pass",
             "Bounce Control", "Half Turn Control", "Foundation Touches", "Small Space Weave",
             "Scoop Saves", "Quick Hands", "Interception Steps", "Clear and Recover",
             "Balance Circuit", "Quick Feet":
            240
        case "Power Shots", "Long Passing", "Low Diving Saves", "Reaction Saves":
            600
        case "Weak Foot Finishing", "1v1 Goalkeeper", "Wall Passing", "Target Corners",
             "Volley Finish", "Cross Collection":
            480
        case "Quick Shot", "Dribble and Shoot", "First Touch Finish", "Turn and Shoot",
             "Driven Wall Pass", "High Ball Catch", "Juggling":
            360
        case "Cone Weave", "Speed Dribble", "Figure Eight", "Zigzag Sprint",
             "Change of Pace", "Shield and Turn", "Cruyff Turn":
            240
        case "Inside-Outside Touches", "Stop and Go", "Pullback Turn", "Scissors Move",
             "Sole Roll and Push", "L-Drag Turn", "Goalkeeper Footwork",
             "Defensive Shuffle", "Backpedal and Turn":
            180
        default:
            300
        }
    }

    static func minimumPoints(for drillName: String) -> Int {
        let minutes = Int((Double(duration(for: drillName)) / 60).rounded(.up))
        let isWorkout = DrillPresentation.category(for: drillName) == "Workout"
        return minutes * (isWorkout ? 30 : 35) + (isWorkout ? 150 : 0)
    }

    private var drillDuration: Int {
        let baseSeconds = Double(Self.duration(for: drill.name))

        let adjustedMinutes = max(
            2,
            Int((baseSeconds / 60 * trainingDifficulty.durationMultiplier).rounded())
        )
        return adjustedMinutes * 60
    }

    private var drillCategory: String {
        DrillPresentation.category(for: drill.name)
    }

    private var formattedTime: String {
        Self.formattedDuration(timeLeft)
    }

    private static func formattedDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var recordedAttempts: Int {
        if isPassAndTurnDrill {
            return 10
        }
        if isShootingDrill {
            return 20
        }
        if isBallControlDrill {
            return 20
        }
        return Int(attemptsCompleted) ?? 0
    }

    private var recordedSuccesses: Int {
        if isPassAndTurnDrill {
            return calloutCount
        }
        if isShootingDrill {
            return (Int(leftFootGoals) ?? 0) + (Int(rightFootGoals) ?? 0)
        }
        if isBallControlDrill {
            return Int(successfulTraps) ?? 0
        }
        return Int(successfulAttempts) ?? 0
    }

    private var accuracy: Double {
        guard recordedAttempts > 0 else { return 0 }
        return min(1, Double(recordedSuccesses) / Double(recordedAttempts))
    }

    /// Drill minutes rounded up so a drill a few seconds under a full minute
    /// still earns a full minute's worth of points and XP.
    private var drillMinutes: Int {
        Int((Double(drillDuration) / 60).rounded(.up))
    }

    private var basePointsAward: Int {
        let timePoints = drillMinutes * (isWorkoutDrill ? 30 : 35)
        let workoutBonus = isWorkoutDrill ? 150 : 0
        return timePoints
            + workoutBonus
            + trainingDifficulty.reward
            + (weeklyTaskID == nil ? 0 : 25)
    }

    private var pointsAward: Int {
        basePointsAward
    }

    private var xpAward: Int {
        drillMinutes * 10 + recordedSuccesses * 2
    }

    private var weeklyTaskAlreadyCompleted: Bool {
        guard let weeklyTaskID else { return false }
        return completedWeeklyTaskIDs.contains(weeklyTaskID)
    }

    private var completedWeeklyTaskIDs: Set<String> {
        Set(completedWeeklyTasks.split(separator: "|").map(String.init))
    }

    private var completedWeeklyDayNames: Set<String> {
        Set(completedWeeklyDays.split(separator: "|").map(String.init))
    }

    private var isShootingDrill: Bool {
        drillCategory == "Shooting"
    }

    private var isBallControlDrill: Bool {
        drillCategory == "Control"
    }

    private var isDribblingDrill: Bool {
        drillCategory == "Dribbling"
    }

    private var isWorkoutDrill: Bool {
        drillCategory == "Workout"
    }

    private var isPassAndTurnDrill: Bool {
        drill.name == "Pass and Turn"
    }

    private var isPassingDrill: Bool {
        drillCategory == "Passing"
    }

    private var isUntimedDrill: Bool {
        isShootingDrill || isBallControlDrill || isPassingDrill || isDribblingDrill
    }

    private var scoreQuestion: LocalizedStringResource {
        switch drillCategory {
        case "Shooting":
            "Record your shooting results"
        case "Passing":
            "Record your passing results"
        case "Dribbling":
            "Record your dribbling results"
        case "Control":
            "Record your ball-control results"
        default:
            "Record your completed repetitions"
        }
    }

    private var attemptLabel: LocalizedStringResource {
        switch drillCategory {
        case "Passing": "Passes attempted"
        case "Dribbling": "Dribbling attempts"
        case "Control": "Control attempts"
        default: "Repetitions attempted"
        }
    }

    private var successLabel: LocalizedStringResource {
        switch drillCategory {
        case "Passing": "Accurate passes"
        case "Dribbling": "Successful dribbles"
        case "Control": "Successful controls"
        default: "Repetitions completed"
        }
    }

    private var hasValidScore: Bool {
        if isShootingDrill {
            guard let leftGoals = Int(leftFootGoals), let rightGoals = Int(rightFootGoals) else {
                return false
            }
            return (0...10).contains(leftGoals) && (0...10).contains(rightGoals)
        }

        if isBallControlDrill {
            guard let attempts = Int(attemptsCompleted),
                  let controls = Int(successfulTraps)
            else {
                return false
            }
            return attempts > 0 && controls >= 0 && controls <= attempts
        }

        guard let attempts = Int(attemptsCompleted),
              let successes = Int(successfulAttempts)
        else {
            return false
        }
        return attempts > 0 && successes >= 0 && successes <= attempts
    }

    private var practiceRecommendation: LocalizedStringResource? {
        guard showThankYou else { return nil }

        if isPassAndTurnDrill {
            return "Great work! You completed all 10 pass, turn, and dribble callouts."
        }

        if isShootingDrill {
            guard
                let leftGoals = Int(leftFootGoals),
                let rightGoals = Int(rightFootGoals)
            else {
                return nil
            }
            return leftGoals + rightGoals >= 12
                ? "Great finishing! You can spend a little less time on shooting and work on another skill."
                : "Keep practicing your shooting. Give extra attention to the foot that scored fewer goals."
        }

        if isBallControlDrill {
            return accuracy >= 0.8
                ? "Excellent control! Most of your touches stayed under control."
                : "Keep developing your first touch and try to improve your successful-control percentage."
        }

        return accuracy >= 0.8
            ? "Strong results! Your successful attempts increased your XP."
            : "Keep practicing. More successful attempts will increase your XP."
    }

    private var canComplete: Bool {
        showThankYou
    }

    static let passAndTurnText: String = "Stand at your starting point facing away from the wall. Take 5 steps to your left and place Cone 1. Return to the starting point, take 7 steps straight ahead, and place Cone 2. Return again, take 5 steps to your right, and place Cone 3. Stand near a wall with the ball. Press Start and pass the ball firmly against the wall. As the ball returns, listen for the spoken cone number. Receive the ball, turn quickly toward that cone, and dribble to it using small, controlled touches. Return to the starting point and get ready for the next call. Complete all 10 calls to finish the drill and earn points. Choose a difficulty that gives you enough time to return before the next call."

    /// The written instructions for a drill. Shared by the timer screen and the drill
    /// detail page, so both always describe the drill the same way.
    static func instructions(forDrill name: String, minutes: Int) -> String {
        if name == "Pass and Turn" {
            return passAndTurnText
        }
        let category = DrillPresentation.category(for: name)
        let isUntimed = ["Shooting", "Control", "Passing", "Dribbling"].contains(category)
        // Untimed drills (shooting, control, passing, dribbling) don't run a
        // visible countdown — Done just unlocks after this many minutes. Say
        // so explicitly, instead of implying the drill ends exactly at N
        // minutes, so finishing your reps early doesn't read as a bug when
        // Done is still locked.
        let opening = isUntimed
            ? "Complete the \(name) drill. You can mark it done after \(minutes) minutes, so use that time for as many quality repetitions as you can."
            : "Complete the \(name) drill for \(minutes) minutes. Do as many quality repetitions as you can before time ends."

        switch name {
        case "Ball Mastery":
            return "\(opening) Rotate through toe taps, sole rolls, inside-outside touches, and pullbacks. Keep the ball close and avoid breakable objects."
        case "Toe Tap Challenge":
            return "\(opening) Alternate light toe taps on top of the ball. Stay balanced, keep a steady rhythm, and speed up only when every touch is controlled."
        case "Sole Roll Circuit":
            return "\(opening) Roll the ball side to side with your soles, then add pullbacks and diagonal rolls. Use both feet and keep the ball inside your space."
        case "Tight Space Turns":
            return "\(opening) Practice pullback, inside, outside, and Cruyff turns. Take two or three close touches between turns and keep your head up."
        case "Indoor Wall Passing":
            return "\(opening) Use a soft ball and a safe wall. Pass gently, control the return, alternate feet, and count your accurate passes."
        case "Indoor Figure Eight":
            return "\(opening) Dribble a tight figure-eight around two markers in a small safe space. Keep the ball close and alternate the lead foot."
        case "Instep Drive Finish":
            return "\(opening) Strike through the center of the ball with your laces for a flat, driven finish. Plant your standing foot beside the ball and follow through toward the target."
        case "Half Volley Finish":
            return "\(opening) Meet the ball just after it bounces, keep your knee over the ball, and strike down through the center for a clean half-volley."
        case "Roulette Spin":
            return "\(opening) Drag the ball back with the sole of one foot while spinning your body around it, then accelerate away with the other foot."
        case "Ronaldo Chop":
            return "\(opening) Plant your standing foot, chop the ball sharply across your body with the inside of your foot, and explode away in the new direction."
        case "Juggle to Control":
            return "\(opening) Juggle a few touches, then kill the ball dead with a soft first touch and reset. Repeat, mixing foot, thigh, and chest juggles."
        case "Knee Control Drill":
            return "\(opening) Toss the ball onto your knee, cushion it on contact, and let it drop to your feet under control. Alternate knees evenly."
        case "Lofted Chip Pass":
            return "\(opening) Strike underneath the ball with a stabbing motion to loft it over a short obstacle to your target. Focus on a soft, accurate landing."
        case "Rapid Rebound Passing":
            return "\(opening) Pass firmly against a wall and play the return as quickly and cleanly as possible without a heavy first touch. Keep a brisk, steady rhythm."
        case "Parry and Recover":
            return "\(opening) Parry hard shots away from danger with a firm wrist, land balanced, and recover to your feet quickly for a follow-up save."
        case "Narrow Angle Saves":
            return "\(opening) Close the angle by stepping off your line, stay big and balanced, and smother the shot rather than diving early."
        case "Standing Tackle Timing":
            return "\(opening) Stay patient, show the attacker onto your weaker side, and time the tackle for when the ball is slightly away from their feet."
        case "Press and Contain":
            return "\(opening) Sprint to close the gap quickly, then slow down under control a few steps out to contain rather than dive into a tackle."
        case "Triangle Possession Circuit":
            return "\(opening) Set three cones in a triangle 6 steps apart. Pass to one corner, follow your pass, receive at the next corner with an open first touch, and rotate continuously. Switch direction every 2 minutes."
        case "Shoot-Dribble-Pass Combo":
            return "\(opening) Dribble through a line of cones, pass against a wall, control the return, then finish on goal. Reset and repeat the full sequence every time, alternating your finishing foot."
        case "1v1 to Finish Transition":
            return "\(opening) Dribble at a cone acting as a defender, beat it with a change of pace or a turn, then drive forward and finish on goal within 3 touches. Reset fully between reps."
        case "Four Corner Passing Circuit":
            return "\(opening) Set up four cones in a square. Pass to the next corner and sprint to take its place, continuing around the square. Switch passing foot and direction every 2 minutes."
        case "Receive Turn Finish Combo":
            return "\(opening) Receive a pass with your back to goal, take a half-turn first touch into space, and finish in one or two touches. Vary which shoulder you turn over each rep."
        case "Defensive Press to Counter":
            return "\(opening) Close down a cone as the attacker, win the imaginary ball, then immediately dribble forward and finish on goal within 5 seconds. Reset and repeat, alternating your recovery angle."
        case "Full Pitch Transition Circuit":
            return "\(opening) Sprint the length of the area in possession, finish on goal, then sprint back defending an imaginary attacker. Repeat at match intensity."
        case "Long Switch and Finish":
            return "\(opening) Strike a long switching pass to a target, sprint to meet the return pass, and finish first time on goal."
        case "Driven Low Finish":
            return "\(opening) Strike firmly through the bottom half of the ball with your laces to keep the shot low and driven along the ground."
        case "Curl Shot Finish":
            return "\(opening) Strike across the ball with the inside of your foot to bend it around an imaginary defender and into the corner."
        case "First Time Finish":
            return "\(opening) Meet a rolled pass with a firm first-time strike, driving through the center of the ball for power without taking a controlling touch."
        case "Angled Run Finish":
            return "\(opening) Start your run from a wide angle, time your approach to the ball, and finish across your body into the far corner."
        case "Finesse Corner Finish":
            return "\(opening) Use the inside of your foot to lift a soft, placed finish just inside the post rather than driving through it."
        case "Elastico Flick":
            return "\(opening) Touch the ball outside with the outside of your foot, then instantly flick it back inside with the same foot to beat an imaginary defender."
        case "Hocus Pocus Spin":
            return "\(opening) Drag the ball back with your sole, roll it across your body, then spin away using the outside of your other foot."
        case "Lane Change Dribble":
            return "\(opening) Dribble in a straight line, then cut sharply into a new lane every few touches, keeping the ball close as you change direction."
        case "Push and Explode":
            return "\(opening) Push the ball firmly into space ahead of you, then accelerate onto it at full speed before bringing it back under control."
        case "Berba Spin Turn":
            return "\(opening) Shield the ball with your body, drag it back with the sole of your foot, and spin away smoothly in one controlled motion."
        case "Spin Away Control":
            return "\(opening) Cushion the first touch away from pressure, spin your body around the ball, and drive forward in the new direction."
        case "Instep Cushion":
            return "\(opening) Use the top of your foot to cushion a dropping ball dead, keeping it within one step of your body."
        case "One Touch Settle":
            return "\(opening) Kill a firm pass dead on first contact. Keep your ankle relaxed and let the ball die close to your feet."
        case "Back Foot Control":
            return "\(opening) Receive with your back foot to open your body toward the field, setting up your next touch in one movement."
        case "Reaction Control Gates":
            return "\(opening) Have a partner pass to random gates. React quickly, control through the correct gate, and reset for the next ball."
        case "Switch Play Pass":
            return "\(opening) Strike a long diagonal pass across the field to switch play, focusing on weight and accuracy over power."
        case "Through Ball Timing":
            return "\(opening) Play a firm pass into the space ahead of a moving target, timing the pass so it arrives just as they reach it."
        case "Backheel Pass":
            return "\(opening) Let the ball roll to your heel and pass it backward without turning your body. Keep the touch firm and accurate."
        case "Disguised Pass":
            return "\(opening) Look one way and pass the other. Keep your body shape neutral until the last moment to disguise your intention."
        case "Quick Combination Pass":
            return "\(opening) Play rapid one-twos with a wall or partner, keeping every touch quick and accurate under growing tempo."
        case "Rebound Control Saves":
            return "\(opening) Parry the first shot away from danger, then react immediately to smother or catch the rebound."
        case "Low Drive Parry":
            return "\(opening) Get low early and parry firm, driven shots away to the side rather than trying to catch them."
        case "Command the Box":
            return "\(opening) Call loudly, attack crosses at the highest point you can safely reach, and claim the ball with confidence."
        case "One-on-One Recovery":
            return "\(opening) Make the first save, then scramble back to your feet instantly to cover a follow-up shot."
        case "Show Inside Press":
            return "\(opening) Press the attacker from an angle that forces them onto their weaker foot and inside, away from space."
        case "Double Team Recovery":
            return "\(opening) Delay the attacker alone until a second defender arrives, then recover to cover the space they leave."
        case "Last Man Cover":
            return "\(opening) Stay goal-side of the attacker at all times, matching their pace while showing them away from goal."
        case "Zonal Shuffle":
            return "\(opening) Shuffle between marked zones, staying compact and resetting your stance each time the ball changes side."
        case "Overload Finishing Circuit":
            return "\(opening) Combine a dribble, a one-two off a wall, and a first-time finish in one continuous sequence. Reset fully between reps."
        case "Press Trigger Circuit":
            return "\(opening) Sprint to press a cone the instant an imaginary pass is played to it, then recover into shape before the next trigger."
        case "Box to Box Circuit":
            return "\(opening) Sprint from your own box to the opposite box, finish on goal, then jog back to recover. Repeat at a steady, match-realistic pace."
        case "Quick Combination Finish":
            return "\(opening) Play a one-two with a wall, take one touch to set, and finish quickly before you lose momentum."
        case "Game Speed Possession":
            return "\(opening) Keep the ball moving with one- and two-touch passes against a wall at match tempo, resetting instantly after any mistake."
        case "Laces Drive Finish":
            return "\(opening) Strike through the ball's center with the laces of your boot for maximum power while keeping your shot on target."
        case "Inside Foot Placement":
            return "\(opening) Use the inside of your foot for accuracy over power, placing the ball just inside the post rather than blasting it."
        case "Outside Foot Finish":
            return "\(opening) Strike with the outside of your foot to curl the ball away from the keeper without opening your hips."
        case "Rising Drive Finish":
            return "\(opening) Strike slightly under the ball's center to lift a powerful, rising shot toward the top corner."
        case "Across the Body Finish":
            return "\(opening) Approach at an angle and strike across your body into the far corner, keeping your standing foot planted firmly."
        case "Set Piece Free Kick":
            return "\(opening) Set the ball, take a measured run-up, and strike over or around an imaginary wall into the target corner."
        case "Penalty Spot Finish":
            return "\(opening) Pick your corner before you approach the ball, stay composed, and strike confidently from the penalty spot."
        case "Matthews Fake":
            return "\(opening) Shift your weight and touch the ball as if going one way, then push it the opposite direction with the outside of your foot and accelerate."
        case "Rainbow Flick":
            return "\(opening) Trap the ball between your feet, flick it up and over your head with your back foot, and control it as it comes down."
        case "Nutmeg Attempt":
            return "\(opening) Approach a cone gap straight on and push the ball cleanly through it, sprinting around to collect it on the other side."
        case "Chop and Burst":
            return "\(opening) Plant your standing foot, chop the ball sharply inside with the inside of your foot, and burst away at full speed."
        case "Inside Hook Turn":
            return "\(opening) Hook the ball behind your standing leg with the inside of your foot, turning your whole body before accelerating away."
        case "Sprint and Shield":
            return "\(opening) Sprint with the ball under control, then shield it from an imaginary challenger by turning your body side-on before continuing."
        case "Rivelino Flick":
            return "\(opening) Roll the sole of your foot over the top of the ball to disguise direction, then push it past a cone with the same foot."
        case "Volley Cushion":
            return "\(opening) Cushion a ball out of the air with a soft, relaxed foot so it drops dead at your feet instead of bouncing away."
        case "Spin and Pass Control":
            return "\(opening) Control the ball while spinning away from pressure, then immediately play an accurate pass without an extra touch."
        case "Receive Under Pressure":
            return "\(opening) Have a partner close you down as the ball arrives. Shield it with your body and take a touch into open space."
        case "Wall Rebound Control":
            return "\(opening) Pass firmly against a wall at an angle and control the rebound with your first touch, keeping it close enough to move immediately."
        case "Low Driven Cushion":
            return "\(opening) Cushion a firm, low pass dead with the inside of your foot, absorbing the pace so the ball doesn't bounce away."
        case "Open Body Control":
            return "\(opening) Receive side-on with an open body shape so your first touch sets you facing forward, ready to play or dribble."
        case "Two Touch Mastery":
            return "\(opening) Use exactly two touches every time: one to control into space, one to pass or shoot. Keep both touches crisp and purposeful."
        case "Driven Diagonal Pass":
            return "\(opening) Strike a firm diagonal pass across the field with your laces, focusing on accuracy to a specific target."
        case "Blind Side Pass":
            return "\(opening) Without looking directly at the target, use your peripheral vision to play an accurate pass to a cone beside you."
        case "Overlap Pass and Run":
            return "\(opening) Pass the ball forward, then sprint past it on the overlap to receive a return pass in stride."
        case "Angled Wall Pass":
            return "\(opening) Pass against a wall from an angle so the rebound comes back at a different angle. Control and repeat from varying positions."
        case "Third Man Pass":
            return "\(opening) Play a pass to one target with the intention of a quick lay-off to a third target, practicing quick combination thinking."
        case "Short Side Pass":
            return "\(opening) Play crisp, short passes to a close target, prioritizing a quick release over power."
        case "Weighted Pass Gates":
            return "\(opening) Pass the ball through a narrow cone gate so it arrives with just enough pace for a partner to control easily."
        case "High Press Sweeper":
            return "\(opening) Stay alert off your line, rush out to clear long balls played in behind, and recover quickly to your goal."
        case "Deflection Saves":
            return "\(opening) React to a shot that's deflected off a cone or partner's foot, adjusting your body late to still make the save."
        case "One Hand Parry":
            return "\(opening) Push wide shots away with one strong hand when a shot is too far to catch with both, staying balanced on landing."
        case "Short Corner Command":
            return "\(opening) Organize an imaginary wall, communicate loudly, and attack any short corner service with confidence."
        case "Breakaway Saves":
            return "\(opening) Start on your line, read the moment to rush out as the attacker breaks through, and make yourself big to smother the shot."
        case "Footwork Reset Saves":
            return "\(opening) After every save, reset your feet into a balanced ready position immediately before the next shot arrives."
        case "Channel Press":
            return "\(opening) Force the attacker into a wide channel by angling your run, then close down to limit their passing options."
        case "Shoulder Block Tackle":
            return "\(opening) Time a fair shoulder-to-shoulder challenge as the attacker dribbles past, staying balanced rather than lunging."
        case "Slide Tackle Timing":
            return "\(opening) Practice sliding in only when the ball is clearly winnable, leading with the correct foot and getting up quickly after."
        case "Overlap Tracking":
            return "\(opening) Track a runner making an overlapping run, staying goal-side and communicating before handing off or following."
        case "Compact Line Shuffle":
            return "\(opening) Shuffle sideways in a straight line with a partner, staying level to simulate holding a compact defensive line."
        case "Aerial Duel Timing":
            return "\(opening) Time your jump against a tossed ball, leading with your body to win the header safely and cleanly."
        case "Attacking Third Combination":
            return "\(opening) Combine a pass, an overlapping run, and a cutback cross finished first time. Reset fully and repeat at match tempo."
        case "High Press Counter Circuit":
            return "\(opening) Press a cone immediately after an imaginary turnover, win it, then sprint forward in support of a quick counter-attack finish."
        case "Finish Under Fatigue":
            return "\(opening) Sprint a short shuttle first, then immediately receive and finish on goal while your legs are tired. Technique matters more as fatigue builds."
        case "Possession Under Pressure Circuit":
            return "\(opening) Keep the ball moving one-touch against a wall while a partner closes down from behind, forcing quick decisions."
        case "Full Speed Skill Combo":
            return "\(opening) Chain two skill moves back to back at full speed — for example a scissors into a chop — without slowing down between them."
        case "Half Space Finish":
            return "\(opening) Receive and finish from the half-space between the wing and the center, opening your body early to see the goal."
        case "Driven Near Post Finish":
            return "\(opening) Attack the near post with a driven, low finish, getting there before the ball to beat the keeper's angle."
        case "Dipping Volley Finish":
            return "\(opening) Strike a dropping ball on the volley with a short, compact swing so it dips sharply under the crossbar."
        case "One v One Finish":
            return "\(opening) Take on a cone as the last defender, create half a yard of space, and finish calmly rather than rushing the shot."
        case "Backpost Tap In":
            return "\(opening) Time a run to the back post to arrive just as a cross comes in, finishing with a simple touch across the line."
        case "Knuckleball Finish":
            return "\(opening) Strike the center of the ball with minimal spin using a stiff ankle and short follow-through so the shot moves unpredictably."
        case "Snap Shot Finish":
            return "\(opening) Get your shot away as quickly as possible after receiving, prioritizing a rapid release over a big backswing."
        case "Double Scissors":
            return "\(opening) Perform two scissor moves back to back over the ball, keeping your hips low and the ball glued to your feet, then burst away."
        case "Fake Shot Dribble":
            return "\(opening) Wind up as if shooting, let the ball run under your foot untouched, then push it past a cone in the opposite direction."
        case "Cut Inside Burst":
            return "\(opening) Dribble down the line, then cut sharply inside with your lead foot and accelerate into the space you've created."
        case "La Croqueta":
            return "\(opening) Push the ball quickly from one foot to the other across your body to shift direction and escape an imaginary defender."
        case "Okocha Shoulder Drop":
            return "\(opening) Drop your shoulder one way while touching the ball the other, selling the fake with your upper body before accelerating away."
        case "Sombrero Flick":
            return "\(opening) Flick the ball up and over an imaginary defender with one foot, then chase it down and bring it under control."
        case "Heel to Heel Roll":
            return "\(opening) Roll the ball from heel to heel behind your standing leg, keeping your touches light and close together."
        case "Thigh to Foot Control":
            return "\(opening) Cushion a tossed ball on your thigh, let it drop, and take the second touch cleanly with your foot into space."
        case "Spin Out of Pressure":
            return "\(opening) As the ball arrives, spin your whole body away from an imaginary defender in one motion, shielding the ball throughout."
        case "First Touch Direction Change":
            return "\(opening) Use your first touch to send the ball into a completely new direction rather than the way it arrived."
        case "Juggle and Volley Control":
            return "\(opening) Juggle a few touches, then let the ball drop and control it out of the air with a soft first touch."
        case "Low Ball Cushion":
            return "\(opening) Cushion a firm, low rolling pass dead with the sole or inside of your foot, keeping it within a half step of your body."
        case "Receive Behind the Line":
            return "\(opening) Check back to receive behind a marked line, then release forward quickly with your first touch."
        case "Two Foot Juggling":
            return "\(opening) Juggle using only alternating feet, never letting the same foot touch twice in a row."
        case "Curved Wall Pass":
            return "\(opening) Strike the ball with curve off a wall so it returns at an angle, controlling it smoothly on the way back."
        case "One Touch Wall Combination":
            return "\(opening) Play rapid one-touch passes against a wall, moving your position slightly after every pass to vary the angle."
        case "Reverse Pass":
            return "\(opening) Disguise your body shape to suggest one direction, then play the pass behind you or across your body instead."
        case "Driven Target Pass":
            return "\(opening) Strike a firm, flat pass at a specific target with your laces, prioritizing accuracy over distance."
        case "Chip Over Gate":
            return "\(opening) Strike underneath the ball to chip it cleanly over a low cone gate and onto a target beyond it."
        case "Wide to Center Pass":
            return "\(opening) Receive out wide and play an accurate pass infield to a central target, opening your body before the ball arrives."
        case "Pass Under Pressure":
            return "\(opening) Have a partner close you down as you receive. Keep your first touch away from them and release the pass quickly and accurately."
        case "Tip Over the Bar":
            return "\(opening) Get your fingertips to high shots and guide them up and over an imaginary crossbar rather than trying to catch them."
        case "Low Spring Save":
            return "\(opening) Explode low and sideways from a standing position to reach shots aimed at the corners of the goal."
        case "Punch Clearance":
            return "\(opening) When a catch isn't safe under pressure, punch crosses away firmly with both fists toward open space."
        case "Set and React Saves":
            return "\(opening) Get into your set position just before each shot, then react explosively rather than guessing early."
        case "Narrow the Angle Sprint":
            return "\(opening) Sprint off your line to narrow the shooting angle the instant an attacker breaks clear, then set your feet."
        case "Double Save Reaction":
            return "\(opening) Make an initial save, then immediately reset to react to a quick follow-up effort from a rebound."
        case "Press and Recover":
            return "\(opening) Press the ball carrier with controlled aggression, and if you're beaten, recover at full speed to regain your position."
        case "Mark Tight Shadow":
            return "\(opening) Stay close enough to an attacker to touch their shoulder, matching every movement without committing to a tackle."
        case "Intercept and Clear":
            return "\(opening) Step in front of a passing lane to intercept, then clear the ball safely and quickly to open space."
        case "Hold the Line":
            return "\(opening) Stay level with a partner acting as the defensive line, stepping up together rather than individually."
        case "Recovery Sprint Angle":
            return "\(opening) Sprint back on a curved angle that cuts off the attacker's path to goal rather than chasing in a straight line."
        case "Read the Pass":
            return "\(opening) Watch the passer's body shape to anticipate where the ball is going, then step in early to intercept."
        case "Scan Before Touch":
            return "\(opening) Check over both shoulders before the ball arrives, then control into the space you saw. Scan before every single touch."
        case "Third Man Movement":
            return "\(opening) Play a pass to one target with the intention of supporting a third player, reading where the next pass should go before you receive the ball."
        case "Quick Decision Gates":
            return "\(opening) Set up 3 cone gates in different directions. As the ball arrives, call out loud which gate you're playing through, then execute instantly."
        case "Press Trigger Recognition":
            return "\(opening) Watch for a heavy touch or a pass played with the receiver's back turned, and the instant you see it, explode into a press. Reset and repeat."
        case "Switch of Play Reading":
            return "\(opening) Practice recognizing when one side of the field is overloaded, then execute a long switching pass to the open side."
        case "1v1 Goalkeeper":
            return "\(opening) Make a small goal and work with a partner playing the attacker. Start on your line, move forward under control as they approach, stay tall and balanced, then set your feet just before the shot. Complete 10 rounds and switch roles."
        case "Angle Positioning":
            return "\(opening) Set one cone in the goal center and three shooting cones in an arc. Move from the center toward the ball's angle each time, staying on the line between the ball and the center of the goal. Reset after every rep."
        case "Collapse Dive":
            return "\(opening) Start on your knees a short step from a partner. Have them roll the ball just out of reach to either side and collapse sideways onto it, leading with your hands and landing softly on your hip, not your elbow."
        case "Cross Collection":
            return "\(opening) Work with a partner serving gentle high tosses from the side. Call for the ball, step into its path, take off from one leg, and catch it at the highest safe point before bringing it into your chest."
        case "Distribution Accuracy":
            return "\(opening) Set three targets at short, medium, and long range. Practice rolling, throwing, and kicking the ball out to each one, stepping toward the target and following through for accuracy over distance."
        case "Foot Saves":
            return "\(opening) Stand in a ready stance and have a partner roll low shots just wide of you. Step across and block with the sole or side of your foot, staying balanced rather than lunging or overreaching."
        case "Goalkeeper Footwork":
            return "\(opening) Set four cones in a small square. Stay in your ready position and shuffle around the square with quick, controlled side steps, never crossing your feet. Reset in the center after every lap."
        case "High Ball Catch":
            return "\(opening) Have a partner toss the ball above your head from a few steps away. Call for it, take off from one leg, catch it at the highest safe point, and bring it straight into your chest on landing."
        case "Low Diving Saves":
            return "\(opening) Work on a soft surface. Start on your knees as a partner gently rolls the ball a step to either side. Push off with your lower hand, reach with both hands, and land on your side to secure it."
        case "Near Post Saves":
            return "\(opening) Have a partner shoot firmly at your near post from a tight angle. Stay big, get your body behind the ball where possible, and push wide shots away rather than parrying into danger."
        case "Quick Hands":
            return "\(opening) Stand close to a partner who feeds quick, firm service at chest height. Keep your hands soft but ready, catch cleanly, and release the ball back immediately to keep the rhythm fast."
        case "Reaction Saves":
            return "\(opening) Stand a few steps from a partner in your ready position. Have them point left or right just before rolling the ball that way. React to the point, get both hands behind the ball, and secure it."
        case "Scoop Saves":
            return "\(opening) Have a partner roll firm ground balls directly at you. Get your body behind the ball, scoop it up with soft hands and bent knees, and bring it into your chest without letting it bobble."
        case "Set Position Saves":
            return "\(opening) Stand with feet shoulder-width apart, knees bent, weight forward, and hands ready. Reset into this stance before each of a partner's gentle rolls or passes, then catch securely into your chest."
        case "Throw Distribution":
            return "\(opening) Set targets at short, medium, and long distance. Practice underarm rolls to the short target, sidearm throws to the medium one, and overarm throws to the long one, stepping toward each target."
        case "1v1 Shadow":
            return "\(opening) Work with a partner in a small cone box. They move the ball without trying to beat you; stay goal-side, mirror every turn with small side steps, and keep your eyes on the ball, not their feet."
        case "Backpedal and Turn":
            return "\(opening) Start facing a cone, backpedal to it under control, then turn quickly over one shoulder and sprint to a second cone further on. Alternate which shoulder you turn over each rep."
        case "Block and Clear":
            return "\(opening) Stand a few steps from a cone acting as the attacker. Close the space under control, get your body behind an imaginary shot to block it, then clear the loose ball firmly toward open space."
        case "Clear and Recover":
            return "\(opening) Step in front of a cone to clear an imaginary cross or shot, then immediately recover into your defensive stance facing the ball again before the next rep begins."
        case "Close Down":
            return "\(opening) Place a cone 10 steps away as the attacker. Sprint to close the distance, then brake under control a couple of steps out so you arrive balanced and sideways, not lunging in."
        case "Cover Shadow":
            return "\(opening) Work with a partner who plays the attacker against a teammate. Stay a few steps behind and to the side, ready to step in if the attacker gets past the first defender, without ball-watching."
        case "Defensive Shuffle":
            return "\(opening) Set three cones in a line. Shuffle quickly from the middle cone to one outside cone, touch it, shuffle back through the middle to the other side, and repeat, staying low throughout."
        case "Delay the Attacker":
            return "\(opening) Face a cone acting as the attacker a few steps away. Approach under control without committing to a tackle, staying patient and balanced so you buy time for support to arrive."
        case "Interception Steps":
            return "\(opening) Stand off a passing lane between two cones. Read the angle, step in sharply the instant an imaginary pass is played, and clear or control it before resetting to your starting spot."
        case "Jockeying":
            return "\(opening) Face a cone dribbling toward you. Stay on the balls of your feet in a low stance, back-pedal and shuffle to match its pace without diving in, and keep your body shape side-on."
        case "Recovery Run":
            return "\(opening) Start facing away from the goal. Sprint to a cone 15 steps behind you the instant you turn, then jog back into a defensive position. Repeat, alternating which way you turn to start."
        case "Tackle Timing":
            return "\(opening) Face a cone dribbling past you at a steady pace. Stay patient, show it onto your preferred side, and time a clean challenge for the moment the ball is slightly away from the cone."
        case "Wide Channel Defense":
            return "\(opening) Stand in a marked wide channel. Shuffle to stay goal-side of a cone moving down the line, forcing it toward the touchline rather than inside, and recover quickly if it accelerates."
        case "Abs Circuit":
            return "\(opening) Complete three rounds of 10 crunches, a 20-second plank, 10 bicycle crunches on each side, and 10 slow leg raises. Rest 20 seconds between rounds and keep your lower back pressed down and controlled."
        case "Agility Sprints":
            return "\(opening) Place two cones 10 steps apart. Sprint to the second cone, decelerate under control, and walk back to recover. Repeat 8 times, resting 20 seconds between sprints."
        case "Arm Strength":
            return "\(opening) Complete three rounds of 8 push-ups, 10 chair triceps dips, and a 20-second high plank hold. Use knee push-ups if needed and keep a straight line from head to knees or heels throughout."
        case "Balance Circuit":
            return "\(opening) Hold a single-leg balance for 20 seconds on each leg, then repeat with your eyes closed if it feels stable. Move with control, keep your knees soft, and rest briefly whenever your form starts to drop."
        case "Chest Workout":
            return "\(opening) Complete three rounds of 8 regular push-ups, 6 wide push-ups, and a 20-second push-up hold at the top. Use your knees when needed and keep your body in a straight line throughout."
        case "Core Stability":
            return "\(opening) Hold a 20-second front plank, a 15-second side plank on each side, and 10 slow dead bugs. Keep your hips level and your lower back flat against the floor on every rep."
        case "Full Body Workout":
            return "\(opening) Complete three rounds of 10 squats, 8 push-ups, 10 mountain climbers on each side, 8 reverse lunges on each leg, and a 20-second plank. Rest 30 seconds between rounds."
        case "Lateral Hops":
            return "\(opening) Hop side to side over an imaginary line or small marker for 20 seconds, landing softly on both feet each time. Rest 20 seconds and repeat for 4 rounds, keeping your knees soft on landing."
        case "Leg Strength":
            return "\(opening) Complete three rounds of 12 squats, 8 reverse lunges on each leg, 12 calf raises, and a 20-second wall sit. Keep your knees lined up over your toes and move with control throughout."
        case "Mobility Flow":
            return "\(opening) Move slowly through hip circles, leg swings, walking lunges with a twist, and shoulder rolls. Spend about 30 seconds on each movement, breathing steadily and never forcing a stretch."
        case "Quick Feet":
            return "\(opening) Stay light on your toes and tap your feet as quickly as possible in place for 20 seconds, keeping your knees soft and your upper body relaxed. Rest 20 seconds and repeat for 4 rounds."
        case "Recovery Stretch":
            return "\(opening) Move gently through calf, quadriceps, hamstring, hip, chest, and shoulder stretches. Hold each stretch for 20 seconds per side without bouncing, breathing slowly and never stretching into pain."
        case "Running":
            return "\(opening) Warm up by walking for 1 minute. Run at a comfortable, steady pace, then walk for the final minute to cool down. Keep your shoulders relaxed, breathe steadily, and stop if you feel pain."
        case "Shuttle Runs":
            return "\(opening) Place two cones 10 steps apart. Sprint to the far cone, touch the ground, and sprint back to the start. Complete 8 shuttles with 20 seconds of rest between each one."
        case "Single Leg Strength":
            return "\(opening) Complete three rounds of 8 single-leg squats and 10 single-leg calf raises on each leg, holding onto something light for balance if needed. Move slowly and keep your standing knee stable."
        case "Body Feint":
            return "\(opening) Dribble toward a cone. Shift your weight and upper body sharply one way without touching the ball, then push it the other way with the outside of your foot and accelerate past."
        case "Box Dribble":
            return "\(opening) Use four cones to make a box about 6 steps wide and 6 steps long. Dribble anywhere inside the box, keeping the ball close with small touches, using both feet, and practicing sharp turns without letting it leave the box."
        case "Change of Pace":
            return "\(opening) Set two cones 12 steps apart. Dribble slowly for the first half of the distance, then push the ball forward and sprint the rest of the way. Turn at the cone and repeat in the other direction."
        case "Cone Weave":
            return "\(opening) Place 8 to 10 cones in a line a yard apart. Dribble through them as quickly as you can using small touches with both feet, keeping the ball close enough to change direction at every cone."
        case "Cruyff Turn":
            return "\(opening) Dribble toward a cone, fake a pass or shot, then drag the ball behind your standing leg with the inside of the opposite foot. Turn your whole body and accelerate away in the new direction."
        case "Double Touch":
            return "\(opening) Dribble at a cone. Push the ball firmly past it with the inside of one foot, then use the outside of the same foot to touch it again and accelerate away before the cone can react."
        case "Drag Push":
            return "\(opening) Dribble toward a cone. Drag the ball back and across your body with the sole of one foot, then push it forward with the inside of the same foot and burst away at an angle."
        case "Figure Eight":
            return "\(opening) Place two cones about 4 steps apart. Dribble in a tight figure-eight pattern around them using both feet, keeping the ball close and your head up between turns."
        case "L-Drag Turn":
            return "\(opening) Place one cone and start about 4 steps away with the ball. Dribble toward it, drag the ball backward with the sole of one foot just before reaching it, then push it sideways with the inside of the same foot to make an L-shaped turn and accelerate away."
        case "Pullback Turn":
            return "\(opening) Place one cone and start about 5 steps away with the ball. Dribble toward the cone, place your sole on top of the ball just before reaching it, pull it backward while turning your body, and accelerate back the way you came."
        case "Scissors Move":
            return "\(opening) Dribble toward a cone. Circle one foot around the outside of the ball without touching it, then push the ball away in the opposite direction with the outside of your other foot."
        case "Shield and Turn":
            return "\(opening) Use a cone as a defender. Position your body between the cone and the ball, hold it under control for two seconds, then spin away using the sole or outside of your foot."
        case "Slalom Control":
            return "\(opening) Place 5 to 6 cones in a gentle zigzag line. Dribble through them under close control, favoring small touches over speed, and focus on keeping the ball glued to your feet through every turn."
        case "Speed Dribble":
            return "\(opening) Set up two cones far apart. Push the ball firmly ahead of you and sprint to close the gap, using longer touches in open space and smaller ones as you approach each cone."
        case "Step Over Exit":
            return "\(opening) Dribble toward a cone. Step over the ball with one foot without touching it, plant that foot, then push the ball away in the opposite direction with the outside of your other foot and accelerate out."
        case "Stop and Go":
            return "\(opening) Place two cones about 10 steps apart. Dribble quickly toward the second cone, then stop the ball dead with the sole of your foot, pause for one second, and explode back into a sprint."
        case "V-Cut Dribble":
            return "\(opening) Dribble forward, then cut the ball sharply backward and to the side with the inside of your foot to make a V shape, changing direction completely before accelerating away."
        case "Zigzag Sprint":
            return "\(opening) Set up 8 cones in a zigzag pattern. Dribble through them at speed, cutting sharply at every cone with your lead foot, then walk back to the start and repeat."
        case "Aerial Control":
            return "\(opening) Toss the ball above waist height, let it drop, and cushion it with the top of your foot so it stops within one step. Alternate feet and reset your position after each rep."
        case "Bounce Control":
            return "\(opening) Drop the ball and let it bounce once, then cushion it dead with the inside or top of your foot as it comes down. Keep your ankle relaxed to absorb the pace on contact."
        case "Box Ball Mastery":
            return "\(opening) Use four cones to mark a small box. Stay inside it while rotating through toe taps, sole rolls, and inside-outside touches, keeping every touch tight enough that the ball never leaves the box."
        case "Chest Control":
            return "\(opening) Gently toss the ball above chest height. Lean back slightly, let your chest give on contact to cushion the ball downward, and control the drop with your foot before it bounces away."
        case "Cushion Touch":
            return "\(opening) Pass the ball firmly against a wall. As it returns, pull your receiving foot back on contact to absorb the pace so the ball stops dead close to your body instead of bouncing off."
        case "Directional First Touch":
            return "\(opening) Pass against a wall at an angle. As the ball returns, use your first touch to redirect it into open space in a new direction rather than stopping it or playing it straight back."
        case "Foundation Touches":
            return "\(opening) Use a soft ball in a clear, safe space. Rotate slowly through toe taps, sole rolls, and inside touches, focusing on keeping every touch light, close, and fully under control before adding speed."
        case "Half Turn Control":
            return "\(opening) Receive a pass with your back to the target. Take your first touch across your body to turn half-way toward open space, then look up before your next move."
        case "High Ball Settle":
            return "\(opening) Have a ball tossed or dropped from above. Cushion it out of the air with your foot, thigh, or chest so it lands dead at your feet instead of bouncing away, and reset between reps."
        case "Inside-Outside Touches":
            return "\(opening) Place two cones about 8 steps apart. Using one foot, touch the ball across your body with the inside, then push it back out with the outside of the same foot, moving steadily toward the cone."
        case "Juggling":
            return "\(opening) Keep the ball up using your feet, thighs, and head, letting it drop no further than your knee between touches. Try to alternate feet and beat your best streak from your last attempt."
        case "Outside Foot Control":
            return "\(opening) Pass against a wall. As it returns, receive with the outside of your foot and guide the ball across your body into open space with a single smooth touch."
        case "Small Space Weave":
            return "\(opening) Use a soft ball in a clear indoor space. Weave the ball between your feet in tight figure-eight touches without any markers, staying light on your feet and keeping every touch close."
        case "Sole Cushion":
            return "\(opening) Pass the ball firmly against a wall. As it returns, trap it dead under the sole of your foot the instant it arrives, keeping your ankle locked and your weight balanced over the ball."
        case "Sole Roll and Push":
            return "\(opening) Place two cones about 8 steps apart. Roll the ball sideways across your body with the sole of one foot, then immediately push it forward with the inside of your other foot and follow it toward the cone."
        case "Sole Tap Rhythm":
            return "\(opening) Tap the top of the ball lightly with alternating soles, keeping it almost still beneath you. Build a steady rhythm first, then gradually speed up without losing control of the ball."
        case "Turn on First Touch":
            return "\(opening) Receive a pass facing away from where you want to go. Use your first touch to turn the ball into open space in one movement rather than controlling it dead and turning separately."
        case "Wall Control":
            return "\(opening) Make a small square box on the ground with four cones, positioned slightly away from a wall. Pass against the wall at an angle so it pops up on the return, then cushion and trap it inside the box."
        case "Wall Touch Challenge":
            return "\(opening) Pass against a wall and control every return with a different part of your foot in turn — inside, outside, sole, and laces — keeping the ball inside a small marked space."
        case "Driven Wall Pass":
            return "\(opening) Mark a target on a wall. Plant your standing foot beside the ball and drive a firm, flat pass with your laces through the target, controlling the return before the next rep."
        case "First Time Pass":
            return "\(opening) Have a ball played or rebounded to you from a wall. Pass it first time without taking a touch, keeping your standing foot pointed at the target and striking through the middle of the ball."
        case "Give and Go":
            return "\(opening) Pass the ball against a wall, then immediately sprint past it as if overlapping a teammate, and take the rebound in stride without breaking speed."
        case "Lofted Pass":
            return "\(opening) Strike underneath the ball with a stabbing motion to lift it over a short obstacle or gap to a target beyond. Focus on a soft, accurate landing rather than distance."
        case "Long Passing":
            return "\(opening) Place a target 20 steps away. Strike underneath the ball with your laces to drive it toward the target with enough loft to clear the distance, focusing on direction before power."
        case "One Touch Passing":
            return "\(opening) Stand a few steps from a wall. Pass the ball against it and return every ball with one touch, without stopping it first. Stay light on your toes to adjust to each return."
        case "Outside Foot Pass":
            return "\(opening) Pass against a wall or to a partner using only the outside of your foot. Keep your ankle firm and follow through toward the target so the ball travels straight rather than curling off line."
        case "Pass and Turn":
            return "\(opening) Pass the ball against a wall, and as it returns, take a touch that turns your body away from the wall into open space before resetting for the next pass."
        case "Passing Gates":
            return "\(opening) Set up two cones a foot apart as a gate. Pass the ball through the gate to a wall or partner, focusing on weight and accuracy rather than power, and reset after every pass."
        case "Triangle Passing":
            return "\(opening) Set three cones in a triangle a few steps apart. Pass to one corner, follow your pass, receive at the next corner with an open first touch, and keep rotating around the triangle."
        case "Two Touch Passing":
            return "\(opening) Stand near a wall. Use your first touch to control the return across your body, then your second touch to pass it back. Alternate feet and keep both touches crisp."
        case "Wall Passing":
            return "\(opening) Stand a few steps from a wall and mark your spot with a cone. Pass the ball firmly against the wall, control the return, and play the next pass, alternating feet evenly."
        case "Weak Foot Passing":
            return "\(opening) Stand a few steps from a wall and use only your weaker foot. Point your standing foot at the target, lock your ankle, and strike through the middle of the ball with the inside of your foot."
        case "Cutback Finish":
            return "\(opening) Have a ball played or dribbled toward the byline, then cut it back to a spot near the penalty mark. Meet the cutback with a first-time strike, keeping your shot low and on target."
        case "Dribble and Shoot":
            return "\(opening) Set up 8 cones in a line leading toward the goal. Dribble around every cone with small, controlled touches, then shoot as soon as you clear the last one, alternating your finishing foot."
        case "Far Post Finish":
            return "\(opening) Start from a wide angle and time a run across the box toward the far post. Meet an imaginary cross with a firm first-time strike aimed low inside the far post."
        case "First Touch Finish":
            return "\(opening) Pass the ball against a wall, move toward the return, take one touch to set yourself up, then shoot with your second touch before the ball gets away from you."
        case "Low Driven Finish":
            return "\(opening) Strike through the top half of the ball with your laces so the shot stays low and skids along the ground, keeping your knee over the ball as you make contact."
        case "Near Post Finish":
            return "\(opening) Attack the near post with a short, sharp run, arriving just ahead of an imaginary cross or pass and finishing with a firm, low strike before the keeper can set."
        case "One Touch Finish":
            return "\(opening) Have a ball rolled to you from a different angle each time. Call your target corner before it arrives, then strike it first time toward that corner, prioritizing accuracy over power."
        case "Power Shots":
            return "\(opening) Place the ball just outside the penalty area. Approach at an angle, plant your standing foot beside the ball, lock your ankle, and strike through the center with your laces for maximum power on target."
        case "Practice Shooting":
            return "\(opening) Place the ball just outside the penalty area and pick your corner before each attempt. Approach at a slight angle, plant your standing foot beside the ball, and strike through it with the inside or laces of your foot."
        case "Quick Shot":
            return "\(opening) Set up a cone or pole as a defender. Touch the ball past it to one side and shoot immediately, prioritizing a fast release over a big back-swing."
        case "Rebound Finish":
            return "\(opening) Take an initial shot against a wall or rebound surface, then react instantly to the loose ball and finish it with a sharp, first-time strike."
        case "Target Corners":
            return "\(opening) Mark the four corners of the goal as targets. Call your target out loud before each shot, then strike for accuracy over power, alternating feet between attempts."
        case "Turn and Shoot":
            return "\(opening) Start with your back to goal beside a cone. Roll the ball forward, turn quickly around the cone using one touch, and shoot as soon as you're facing goal."
        case "Volley Finish":
            return "\(opening) Gently toss the ball in front of yourself, let it bounce once, and strike it out of the air toward goal before the second bounce, keeping your knee over the ball."
        case "Weak Foot Finishing":
            return "\(opening) Set the ball near the penalty spot and use only your weaker foot. Keep your ankle locked and aim low into alternating corners, prioritizing control over power."
        case "Agility Gate Sprint":
            return "\(opening) Set up two small cone gates a few steps apart. Sprint through the first gate, change direction sharply, and explode through the second, keeping your steps short and quick through each gate."
        case "Full Field Sprint Finish":
            return "\(opening) Sprint the length of the area at full effort, then settle your touch and finish on goal with a composed strike despite your tired legs."
        case "Rapid Fire Finishing":
            return "\(opening) Have a partner feed a quick series of balls to you one after another. Finish each one first time or in two touches, resetting your feet instantly between shots."
        case "Speed Finishing Ladder":
            return "\(opening) Sprint a short distance, then immediately receive a pass and finish on goal. Each rep, add a few extra steps to the sprint so the finish gets progressively harder to set up for."
        case "First Touch Gates":
            return "\(opening) Set up three small cone gates around you. Receive a pass, choose a gate based on where you want to go, and guide your first touch cleanly through it in one movement."
        case "Thigh Control":
            return "\(opening) Toss the ball toward your thigh, relax your leg on contact to cushion it downward, and let it drop to your feet under control. Alternate thighs evenly between reps."
        case "Advanced Ball Mastery":
            return "\(opening) Chain toe taps, sole rolls, inside-outside touches, and pullbacks together without stopping, moving through a small space at a quicker tempo than the basic version."
        case "Around the World":
            return "\(opening) Juggle the ball and, between touches, swing one foot fully around the ball without letting it touch the ground. Reset after every attempt and track how many clean circles you complete."
        case "Beat the Cone":
            return "\(opening) Dribble at a cone acting as a defender. Use a change of pace or a skill move to beat it cleanly on either side, then accelerate away at full speed."
        case "Complete Midfielder Circuit":
            return "\(opening) Combine a short pass, a turn under pressure, and a longer switching pass in one continuous sequence, resetting fully and repeating at a brisk, match-like tempo."
        case "Crossbar Challenge":
            return "\(opening) Place the ball just outside the penalty area and try to strike the crossbar with each shot. Focus on a clean connection and a rising trajectory rather than pure power."
        case "Elite Finishing Circuit":
            return "\(opening) Combine a first touch, a quick turn, and a first-time finish in one flowing sequence. Reset completely between reps and keep your technique sharp as the pace increases."
        case "Elite Touch and Turn":
            return "\(opening) Receive the ball under pressure, take a tight first touch away from an imaginary defender, and turn into space in one continuous motion before accelerating away."
        case "Explosive Dribble":
            return "\(opening) Start from a standing position and explode into a sprint dribble on your first touch, pushing the ball just far enough ahead to run onto at full speed."
        case "First Touch Under Pressure":
            return "\(opening) Have a partner close you down as the ball arrives. Shield it with your body, take a touch away from the pressure, and keep the ball under control as they approach."
        case "Juggling Ladder":
            return "\(opening) Juggle the ball, trying to beat your previous best streak each attempt. Add a challenge each round — alternating feet, including your thighs, or using only your weaker foot."
        case "Match Speed Control":
            return "\(opening) Receive passes at match tempo and control them cleanly with one touch, immediately setting up your next pass or shot rather than taking an extra settling touch."
        case "One Touch Wonder":
            return "\(opening) Play every pass and shot in this session with a single touch — no controlling the ball first. Stay light on your feet so you can adjust your body before each ball arrives."
        case "Perfect Pass Streak":
            return "\(opening) Pass against a wall or to a partner, counting consecutive accurate passes without a miscontrol. If you miss, restart your streak from zero and try to beat your best run."
        case "Precision Cross Finish":
            return "\(opening) Have crosses served into the box from the side. Time your run to meet the ball at its highest accurate point and direct a first-time header or volley on target."
        case "Pressure Cooker Finishing":
            return "\(opening) Have a partner closely defend you as you try to finish chances created from a pass or dribble, forcing you to shoot under realistic time pressure."
        case "Pressure Passing":
            return "\(opening) Have a partner close you down the instant you receive the ball. Keep your first touch away from them and release an accurate pass quickly before they arrive."
        case "Rapid Fire Volleys":
            return "\(opening) Have a partner toss a quick series of balls for you to volley, resetting your body and striking each one cleanly before the next arrives."
        case "Skill Move Combo":
            return "\(opening) Chain two skill moves together without stopping the ball — for example a step over into a scissors — keeping your touches tight and accelerating away after the second move."
        case "Striker Movement Circuit":
            return "\(opening) Practice checking away from goal, then spinning sharply back toward it to receive and finish, timing your run so you arrive onside and at full speed."
        case "Target Practice Circuit":
            return "\(opening) Rotate through shots at each corner of the goal in sequence, calling your target before every attempt and resetting your stance fully between shots."
        case "Technical Mastery Circuit":
            return "\(opening) Combine close control, a turn, and a pass or shot into one flowing sequence, slowing down any part that breaks down before building back up to full speed."
        case "Weak Foot Hero":
            return "\(opening) Complete every touch, pass, and shot in this session using only your weaker foot, moving slower than usual until the technique feels controlled and confident."
        case "Decision Under Pressure":
            return "\(opening) Have a partner close you down as you receive the ball. Scan before it arrives, then decide instantly whether to pass, turn, or shield based on where the pressure comes from."
        case "Field Awareness Circuit":
            return "\(opening) Before each touch, check over both shoulders to picture where open space and imaginary teammates are, then play your next action based on what you saw rather than habit."
        case "Game Speed Scanning":
            return "\(opening) Check over your shoulders every couple of seconds while moving with or without the ball, calling out loud what you see each time to build the habit under fatigue."
        case "Numbers Up Counter":
            return "\(opening) Picture a 2-vs-1 breaking forward. Decide out loud whether you'd pass or dribble based on where an imaginary defender is standing, then execute that choice with the ball."
        case "Read and React Passing":
            return "\(opening) Have a partner call a direction just as they pass to you. React immediately, controlling your first touch toward the called side without pausing to think."
        case "Finishing Clock":
            return "\(opening) Have a partner feed balls in quick succession from just outside the box. Finish as many clean shots on target as you can, resetting your feet after every attempt and never pausing to admire one."
        case "Pressure Finish Gauntlet":
            return "\(opening) Have a partner close you down the instant you receive the ball. Take one touch away from the pressure and finish quickly before they can block the shot — the tighter the pressure, the better the rep."
        case "Dribble Gauntlet":
            return "\(opening) Place 8 to 10 cones in a tight line. Weave through them as many times as you can, counting only clean reps where the ball never leaves your close control."
        case "Chain Move Challenge":
            return "\(opening) Dribble at a cone and chain two different moves back to back without slowing down — for example a step over into a scissors — before accelerating away at full speed."
        case "Control Gauntlet":
            return "\(opening) Pass against a wall and cushion every return dead with a single touch, counting how many clean traps in a row you can land before a touch gets away from you."
        case "Pressure Touch Challenge":
            return "\(opening) Have a partner serve balls quickly from different heights and angles while closing you down. Control each one away from the pressure with a single touch before playing it out."
        case "Passing Gauntlet":
            return "\(opening) Pass against a wall as fast and accurately as you can, counting every clean pass that returns under control. Reset your count if a pass gets away from you."
        case "Rapid Switch Challenge":
            return "\(opening) Alternate short, sharp passes with long switching passes to a target, changing which type you play every few reps without warning yourself in advance."
        default:
            break
        }

        switch category {
        case "Shooting":
            return "\(opening) Alternate feet when possible, choose a target before each shot, and focus on accuracy before power."
        case "Dribbling":
            return "\(opening) Keep the ball close, use both feet, and stay under control when you change direction."
        case "Passing":
            return "\(opening) Count your accurate passes, alternate feet, and use a wall or partner if available."
        case "Control":
            return "\(opening) Count every clean control that keeps the ball close enough for your next move."
        case "Goalkeeping":
            return "\(opening) Work safely with gentle service, get set before each attempt, and count your clean saves."
        case "Defense":
            return "\(opening) Stay balanced, move with control, and reset your stance after every repetition."
        case "Plus Training":
            return "\(opening) Work at match speed while keeping clean technique. Slow down briefly if control drops, then build the speed again."
        case "Technique":
            return "\(opening) Go slowly at first to groove the movement, then build to full speed once it feels smooth and controlled."
        case "Speed & Finishing":
            return "\(opening) Sprint at full effort between touches, then settle and finish with a clear, composed strike."
        case "First Touch":
            return "\(opening) Prioritize a soft, controlling first touch over speed — a clean touch sets up everything that follows."
        case "Soccer IQ":
            return "\(opening) Stay switched on, scan the field before every touch, and talk through your decision out loud as you train."
        default:
            return "\(opening) Use good form, rest briefly when needed, drink water, and stop if you feel pain."
        }
    }

    private var sessionInstructions: String {
        Self.instructions(forDrill: drill.name, minutes: drillDuration / 60)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                ZStack(alignment: .bottom) {
                    Image(DrillPresentation.imageName(for: drill.name, category: drillCategory))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .overlay {
                            // Only a handful of stock photos ship with the app, so tint
                            // each drill's shared photo with its own stable hue.
                            Color(hue: DrillPresentation.photoHue(for: drill.name), saturation: 0.6, brightness: 0.9)
                                .opacity(0.4)
                                .blendMode(.hue)
                        }
                        .clipped()

                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(spacing: 6) {
                        Image(systemName: "figure.soccer")
                            .font(.system(size: 34, weight: .bold))
                        Text(drillCategory.uppercased())
                            .font(.headline)
                            .fontWeight(.black)
                    }
                    .padding(.bottom, 14)
                }
                .frame(height: 180)
                .foregroundStyle(.white)
                .overlay(alignment: .topTrailing) {
                    if DrillPresentation.isIndoor(drill.name) {
                        Label("Indoor", systemImage: "house.fill")
                            .font(.caption.weight(.heavy))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white, in: .capsule)
                            .foregroundStyle(Color.soccerAccent)
                            .padding(12)
                    }
                }

                Text(drill.name)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Picker("Difficulty", selection: $trainingDifficulty) {
                    ForEach(DrillDifficulty.allCases) { difficulty in
                        Text(difficulty.rawValue)
                            .tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .disabled(timerActive || shootingStarted || calloutsActive)
                .onChange(of: trainingDifficulty) { _, _ in
                    guard !timerActive, !shootingStarted, !calloutsActive else { return }
                    timeLeft = drillDuration
                    shootingCooldown = drillDuration
                }

                HStack(spacing: 10) {
                    sessionFact(
                        title: "DURATION",
                        value: Self.formattedDuration(drillDuration),
                        icon: "clock.fill"
                    )
                    sessionFact(
                        title: "LEVEL \(PlayerProgress(xp: playerXP).level)",
                        value: PlayerProgress(xp: playerXP).levelTitle,
                        icon: "chart.bar.fill"
                    )
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 14) {
                    Label(DrillPresentation.focus(for: drillCategory), systemImage: "scope")
                    Label(
                        DrillPresentation.equipment(for: drill.name, category: drillCategory),
                        systemImage: "shippingbox.fill"
                    )
                    Label("Quality first: slow down if your technique breaks.", systemImage: "lightbulb.fill")
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 18))
                .padding(.horizontal, 20)

                Text("Reward: \(pointsAward) points")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.soccerAccent)

            if isPassAndTurnDrill {
                Text(Self.passAndTurnText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(24)
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.soccerAccent.opacity(0.3), lineWidth: 2)
                    }
                    .padding(.horizontal, 20)

                Text(
                    "Next call every \(Int(trainingDifficulty.calloutInterval)) seconds • Reward: \(pointsAward) points"
                )
                .font(.headline)

                if calloutsActive || calloutCount > 0 {
                    Text(
                        currentCone > 0
                            ? "Cone \(currentCone)"
                            : readyCountdown > 0 ? "Ready in \(readyCountdown)" : "Get ready"
                    )
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                    Text("Callout \(calloutCount) of 10")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                if !isCompleted {
                    Button(calloutsActive ? "Stop" : "Start") {
                        if calloutsActive {
                            stopPassAndTurn()
                        } else {
                            startPassAndTurn()
                        }
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(calloutsActive ? Color.red : Color.soccerAccent)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 40)
                }
            } else if isUntimedDrill {
                Text(sessionInstructions)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(24)
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.soccerAccent.opacity(0.3), lineWidth: 2)
                    }
                    .padding(.horizontal, 20)

                if !shootingStarted {
                    Button("Start") {
                        goalsScored = ""
                        leftFootGoals = ""
                        rightFootGoals = ""
                        controlBoxSize = ""
                        successfulTraps = ""
                        attemptsCompleted = ""
                        successfulAttempts = ""
                        showThankYou = false
                        isCompleted = false
                        didRecordProgress = false
                        shootingStarted = true
                        shootingCooldown = drillDuration
                        timer?.invalidate()
                        // Count down against an end date so the timer stays correct
                        // while the phone is locked and the app is suspended.
                        let endDate = Date().addingTimeInterval(TimeInterval(drillDuration))
                        DrillTimerLiveActivity.shared.start(
                            drillName: drill.name,
                            category: drillCategory,
                            duration: drillDuration
                        )
                        let newTimer = Timer(timeInterval: 1, repeats: true) { timer in
                            let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
                            if remaining > 0 {
                                shootingCooldown = remaining
                            } else {
                                shootingCooldown = 0
                                timer.invalidate()
                                DrillTimerLiveActivity.shared.finish()
                            }
                        }
                        // Scheduling in the .common run loop mode keeps this firing
                        // every second while this screen's ScrollView is being dragged,
                        // instead of pausing and then skipping a displayed second.
                        RunLoop.main.add(newTimer, forMode: .common)
                        timer = newTimer
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.soccerAccent)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 40)
                } else {
                    Text(
                        shootingCooldown > 0
                            ? "Done available in \(shootingCooldown) seconds"
                            : "You can finish the drill now"
                    )
                    .font(.headline)

                    Button("Done") {
                        finishWithoutScoreQuestion()
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(shootingCooldown == 0 ? Color.soccerAccent : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 40)
                    .disabled(shootingCooldown > 0)
                }
            } else {
                Group {
                    Text(sessionInstructions)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(24)
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.soccerAccent.opacity(0.3), lineWidth: 2)
                        }
                        .padding(.horizontal, 20)
                }

                Text(formattedTime)
                    .font(.system(size: 64, weight: .bold, design: .rounded))

                Button(timerActive ? "Stop" : "Start") {
                    if timerActive {
                        timer?.invalidate()
                        timerActive = false
                        DrillTimerLiveActivity.shared.cancel()
                    } else {
                        timerActive = true
                        goalsScored = ""
                        attemptsCompleted = ""
                        successfulAttempts = ""
                        showThankYou = false
                        isCompleted = false
                        didRecordProgress = false
                        timeLeft = drillDuration
                        // Count down against an end date so the timer stays correct
                        // while the phone is locked and the app is suspended.
                        let endDate = Date().addingTimeInterval(TimeInterval(drillDuration))
                        DrillTimerLiveActivity.shared.start(
                            drillName: drill.name,
                            category: drillCategory,
                            duration: drillDuration
                        )
                        let newTimer = Timer(timeInterval: 1, repeats: true) { timer in
                            let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
                            if remaining > 0 {
                                timeLeft = remaining
                            } else {
                                timeLeft = 0
                                timer.invalidate()
                                timerActive = false
                                DrillTimerLiveActivity.shared.finish()
                                finishTimedDrill()
                            }
                        }
                        // Scheduling in the .common run loop mode keeps this firing
                        // every second while this screen's ScrollView is being dragged,
                        // instead of pausing and then skipping a displayed second.
                        RunLoop.main.add(newTimer, forMode: .common)
                        timer = newTimer
                    }
                }
                .font(.title2)
                .padding()
                .background(timerActive ? Color.red : Color.soccerAccent)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 12))
            }

            if showThankYou {
                Text("Good job, keep it up!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soccerAccent)

                if let practiceRecommendation {
                    Text(practiceRecommendation)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 14))
                        .padding(.horizontal, 20)
                }
            }

            if canComplete {
                if isCompleted || weeklyTaskAlreadyCompleted {
                    Text("Completed! +\(awardedPoints) points • +\(awardedXP) XP")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.soccerAccent)
                } else {
                    Button("Complete") {
                        completeDrill()
                    }
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.soccerAccent)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 40)
                }
            }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 104)
        }
        .foregroundStyle(Color.soccerText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.soccerBackground.ignoresSafeArea())
        .onDisappear {
            if timerActive || (shootingStarted && shootingCooldown > 0) {
                timerActive = false
                DrillTimerLiveActivity.shared.cancel()
            }
            timer?.invalidate()
            passTurnStartTask?.cancel()
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func sessionFact(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.soccerAccent)
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(10)
        .background(Color.soccerSurface)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var scoreEntrySheet: some View {
        VStack(spacing: 24) {
            Text(scoreQuestion)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            if isShootingDrill {
                TextField("Left-foot goals out of 10", text: $leftFootGoals)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .primary)
                    .textFieldStyle(.roundedBorder)
                TextField("Right-foot goals out of 10", text: $rightFootGoals)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .secondary)
                    .textFieldStyle(.roundedBorder)
            } else if isBallControlDrill {
                TextField("Control attempts", text: $attemptsCompleted)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .primary)
                    .textFieldStyle(.roundedBorder)
                TextField("Successful controls", text: $successfulTraps)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .secondary)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(attemptLabel, text: $attemptsCompleted)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .primary)
                    .textFieldStyle(.roundedBorder)
                TextField(successLabel, text: $successfulAttempts)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .secondary)
                    .textFieldStyle(.roundedBorder)
            }

            Text("Points stay fixed. XP is calculated from your successful results and \(drillMinutes) minutes of training.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Save Results") {
                focusedScoreField = nil
                showScoreQuestion = false
                showThankYou = true
            }
            .font(.title2)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(hasValidScore ? Color.soccerAccent : Color.gray)
            .foregroundStyle(Color.white)
            .clipShape(.rect(cornerRadius: 14))
            .disabled(!hasValidScore)
        }
        .padding(32)
        .foregroundStyle(Color.soccerText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.soccerBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedScoreField = nil
                }
            }
        }
        .onAppear {
            Task { @MainActor in
                await Task.yield()
                focusedScoreField = .primary
            }
        }
    }

    private func finishTimedDrill() {
        if isWorkoutDrill {
            attemptsCompleted = "1"
            successfulAttempts = "1"
            showThankYou = true
        } else {
            finishWithoutScoreQuestion()
        }
    }

    private func finishWithoutScoreQuestion() {
        focusedScoreField = nil
        showThankYou = true
    }

    private func startPassAndTurn() {
        timer?.invalidate()
        passTurnStartTask?.cancel()
        speechSynthesizer.stopSpeaking(at: .immediate)

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? audioSession.setActive(true)
        calloutCount = 0
        currentCone = 0
        readyCountdown = 5
        isCompleted = false
        didRecordProgress = false
        showThankYou = false
        calloutsActive = true

        passTurnStartTask = Task { @MainActor in
            for seconds in stride(from: 5, through: 1, by: -1) {
                guard calloutsActive else { return }
                readyCountdown = seconds

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }

            guard calloutsActive else { return }
            readyCountdown = 0
            makeConeCallout()

            timer = Timer.scheduledTimer(
                withTimeInterval: trainingDifficulty.calloutInterval,
                repeats: true
            ) { timer in
                if calloutCount < 10 {
                    makeConeCallout()
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    private func stopPassAndTurn() {
        timer?.invalidate()
        passTurnStartTask?.cancel()
        speechSynthesizer.stopSpeaking(at: .immediate)
        readyCountdown = 0
        calloutsActive = false
    }

    private func makeConeCallout() {
        guard calloutsActive, calloutCount < 10 else { return }

        let availableCones = (1...3).filter { $0 != currentCone }
        let cone = availableCones.randomElement() ?? 1
        currentCone = cone
        calloutCount += 1

        let utterance = AVSpeechUtterance(string: "Pass, then cone \(cone)")
        utterance.voice = AVSpeechSynthesisVoice.speechVoices().first {
            $0.language == "en-US" && $0.name.localizedCaseInsensitiveContains("Samantha")
        } ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.15
        utterance.volume = 1
        speechSynthesizer.speak(utterance)

        if calloutCount == 10 {
            timer?.invalidate()
            calloutsActive = false
            showThankYou = true
            completeDrill()
        }
    }

    private func completeDrill() {
        if let weeklyTaskID, let weeklyDay {
            var taskIDs = completedWeeklyTaskIDs
            guard !taskIDs.contains(weeklyTaskID) else {
                isCompleted = true
                return
            }

            taskIDs.insert(weeklyTaskID)
            completedWeeklyTasks = taskIDs.sorted().joined(separator: "|")
            recordProgress()

            let completedTasksForDay = taskIDs.filter {
                $0.hasPrefix("\(weeklyDay)-")
            }.count
            var completedDays = completedWeeklyDayNames

            if completedTasksForDay >= 3 && !completedDays.contains(weeklyDay) {
                completedDays.insert(weeklyDay)
                completedWeeklyDays = completedDays.sorted().joined(separator: "|")
            }
        } else {
            recordProgress()
        }

        isCompleted = true
    }

    private func recordProgress() {
        guard !didRecordProgress else { return }
        didRecordProgress = true

        let previousXP = playerXP
        awardedPoints = pointsAward
        awardedXP = xpAward
        totalPoints += pointsAward
        playerXP += xpAward
        let minutesTrained = drillMinutes
        totalTrainingMinutes += minutesTrained
        totalSessions += 1

        // Every category earns XP and training minutes uniformly, keyed by name
        // in a single dictionary-backed store, rather than needing its own named
        // @AppStorage property (that approach silently left newer categories like
        // Goalkeeping/Defense/Plus Training earning no category-specific XP).
        var progress = CategoryProgress(xpText: categoryXPText, minutesText: categoryMinutesText)
        progress.addXP(xpAward, to: drillCategory)
        progress.addMinutes(minutesTrained, to: drillCategory)
        categoryXPText = progress.xpText
        categoryMinutesText = progress.minutesText

        switch drillCategory {
        case "Shooting":
            totalGoals += recordedSuccesses
            totalShots += recordedAttempts
        case "Dribbling":
            totalDribblingAttempts += recordedAttempts
        case "Passing":
            totalPasses += recordedSuccesses
        case "Control", "First Touch":
            totalControls += recordedSuccesses
        default:
            break
        }

        updateTrainingStreak()

        let levelsGained = PlayerProgress.levelsGained(fromXP: previousXP, toXP: playerXP)
        if levelsGained > 0 {
            rewardBoxes += levelsGained
        }

        TrainingLog.record(drillName: drill.name, skill: drillCategory, minutes: minutesTrained, xp: xpAward)
        onCompleted?()
    }

    private func updateTrainingStreak() {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"

        let today = formatter.string(from: Date())
        guard lastTrainingDate != today else { return }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        trainingStreak = lastTrainingDate == formatter.string(from: yesterday)
            ? trainingStreak + 1
            : 1
        lastTrainingDate = today
    }
}

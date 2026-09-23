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
    @Binding var totalPoints: Int
    @AppStorage("completedWeeklyTasks") private var completedWeeklyTasks = ""
    @AppStorage("completedWeeklyDays") private var completedWeeklyDays = ""
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0
    @AppStorage("playerXP") private var playerXP = 0
    @AppStorage("shootingXP") private var shootingXP = 0
    @AppStorage("dribblingXP") private var dribblingXP = 0
    @AppStorage("passingXP") private var passingXP = 0
    @AppStorage("controlXP") private var controlXP = 0
    @AppStorage("fitnessXP") private var fitnessXP = 0
    @AppStorage("totalGoals") private var totalGoals = 0
    @AppStorage("totalShots") private var totalShots = 0
    @AppStorage("totalPasses") private var totalPasses = 0
    @AppStorage("totalDribblingAttempts") private var totalDribblingAttempts = 0
    @AppStorage("totalControls") private var totalControls = 0
    @AppStorage("totalSessions") private var totalSessions = 0
    @AppStorage("trainingStreak") private var trainingStreak = 0
    @AppStorage("lastTrainingDate") private var lastTrainingDate = ""
    @AppStorage("rewardBoxes") private var rewardBoxes = 0
    @AppStorage("isProMember") private var isProMember = false
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
    @State private var trainingDifficulty = PassTurnDifficulty.easy
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
        weeklyDay: String? = nil
    ) {
        self.drill = drill
        self.weeklyTaskID = weeklyTaskID
        self.weeklyDay = weeklyDay
        _totalPoints = totalPoints
        _timeLeft = State(initialValue: Self.duration(for: drill.name))
    }

    static func duration(for drillName: String) -> Int {
        switch drillName {
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
        let minutes = duration(for: drillName) / 60
        let isWorkout = DrillPresentation.category(for: drillName) == "Workout"
        return minutes * (isWorkout ? 30 : 35) + (isWorkout ? 150 : 0)
    }

    private var drillDuration: Int {
        let baseMinutes = Double(Self.duration(for: drill.name)) / 60
        let adjustedMinutes = max(
            2,
            Int((baseMinutes * trainingDifficulty.durationMultiplier).rounded())
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

    private var basePointsAward: Int {
        let timePoints = (drillDuration / 60) * (isWorkoutDrill ? 30 : 35)
        let workoutBonus = isWorkoutDrill ? 150 : 0
        let standardPoints = timePoints
            + workoutBonus
            + trainingDifficulty.reward
            + (weeklyTaskID == nil ? 0 : 25)
        return isProMember ? standardPoints * 5 / 4 : standardPoints
    }

    private var pointsAward: Int {
        basePointsAward
    }

    private var xpAward: Int {
        (drillDuration / 60) * 10 + recordedSuccesses * 2
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

    private var passAndTurnInstructions: LocalizedStringResource {
        "Stand at your starting point facing away from the wall. Take 5 steps to your left and place Cone 1. Return to the starting point, take 7 steps straight ahead, and place Cone 2. Return again, take 5 steps to your right, and place Cone 3. Stand near a wall with the ball. Press Start and pass the ball firmly against the wall. As the ball returns, listen for the spoken cone number. Receive the ball, turn quickly toward that cone, and dribble to it using small, controlled touches. Return to the starting point and get ready for the next call. Complete all 10 calls to finish the drill and earn points. Choose a difficulty that gives you enough time to return before the next call."
    }

    private var sessionInstructions: String {
        let minutes = drillDuration / 60
        let opening = "Complete the \(drill.name) drill for \(minutes) minutes. Do as many quality repetitions as you can before time ends."

        switch drill.name {
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
        default:
            break
        }

        switch drillCategory {
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
        default:
            return "\(opening) Use good form, rest briefly when needed, drink water, and stop if you feel pain."
        }
    }

    private var untimedDrillInstructions: LocalizedStringResource {
        switch drill.name {
        case "Weak Foot Passing":
            "Stand a few steps away from a wall and mark your starting spot with a cone. Use only your weaker foot for this drill. Point your standing foot toward the target, keep it beside the ball, lock the ankle of your passing foot, and strike through the middle of the ball with the inside of your foot. Aim for the same spot on the wall each time. Control the return when needed, reset your body, and complete 50 accurate passes with your weaker foot."
        case "One Touch Passing":
            "Stand a few steps from a wall with enough space to move safely. Pass the ball against the wall and return it with one touch without stopping it first. Keep your standing foot pointed toward the target, lock your ankle, and use the inside of your foot for accuracy. Stay light on your toes so you can adjust to every return. Complete 25 one-touch passes with your right foot, then 25 with your left foot."
        case "Wall Passing":
            "Stand a few steps from a wall and mark your starting spot with a cone. Pass the ball firmly against the wall, control the return, and play the next pass. Keep your standing foot beside the ball, lock your ankle, and aim for the same spot on the wall each time. Complete 25 passes with your right foot and 25 passes with your left foot."
        case "Wall Control":
            "Make a square control box on the ground using four cones. Choose a box size that challenges you. Stand inside the box with a wall slightly to your side. Pass the ball against the wall at an angle so it returns and pops up. As it comes back, cushion the ball with your foot and trap it inside the box. Keep your ankle firm, stay balanced, and try to stop the ball close to you. Complete 20 passes and count every successful trap that stays inside the box."
        case "Quick Shot":
            "Set up a pole or cone. Tap the ball to the right or left, and shoot. Take 20 shots in total: 10 with your right foot and 10 with your left foot."
        case "Dribble and Shoot":
            "Set up 8 cones in a line leading toward the goal. Start with the ball at the first cone, dribble around every cone using small, controlled touches, and then shoot when you reach the end. Reset the ball and repeat for 20 shots: 10 with your right foot and 10 with your left foot."
        default:
            "Take 20 shots in total: 10 with your right foot and 10 with your left foot. Place the ball just outside the penalty area and choose the corner you want to hit before each attempt. Approach the ball at a slight angle, plant your standing foot beside it, lock your ankle, keep your head steady, and strike through the ball. Focus on accuracy before power. Reset after every shot and alternate feet until you finish all 20."
        }
    }

    private var timedDrillInstructions: LocalizedStringResource? {
        switch drill.name {
        case "Speed Dribble":
            "Set up two cones far apart. Dribble to each cone quickly using small touches. Do this for 2 minutes."
        case "Cone Weave":
            "Place 8–10 cones in a line and dribble around them as fast as possible. Do this for 2 minutes."
        case "Box Dribble":
            "Use four cones to make a box about 6 steps wide and 6 steps long. Dribble anywhere inside the box for 2 minutes. Keep the ball close with small touches, use both feet, and change direction often. Practice sharp turns, quick stops, and bursts of speed without letting the ball leave the box."
        case "L-Drag Turn":
            "Place one cone and start about 4 steps away with the ball. Dribble toward the cone under control. Just before reaching it, put the sole of one foot on top of the ball and drag it backward. Turn your hips, then use the inside of the same foot to push the ball sideways, making an L shape around the cone. Accelerate away in the new direction. Reset, alternate feet, and repeat for 2 minutes."
        case "Stop and Go":
            "Place two cones about 10 steps apart. Dribble quickly toward the second cone using small touches. Halfway there, stop the ball completely with the sole of your foot, pause for one second, then push the ball forward and explode into a fast dribble. Turn at the cone and repeat in the other direction. Alternate the foot you use to stop and restart the ball for 2 minutes."
        case "Pullback Turn":
            "Place one cone and start about 5 steps away with the ball. Dribble toward the cone, then place the sole of one foot on top of the ball just before you reach it. Pull the ball backward while turning your body, take it away with the same foot, and accelerate back toward your starting point. Keep the ball close and look up after the turn. Alternate feet and repeat for 2 minutes."
        case "Wall Passing":
            "Find a wall and pass the ball against it for 5 minutes. Alternate between your right and left foot."
        case "Juggling":
            "Juggle as much as you can for 10 minutes. Try to alternate feet, keep your foot locked in, and try each day to get a better record."
        case "Inside-Outside Touches":
            "Place two cones about 8 steps apart. Dribble toward the second cone using only one foot: touch the ball across your body with the inside of the foot, then push it back outside with the outside of the same foot. Keep alternating inside and outside touches while moving forward. Turn at the cone, switch feet, and continue for 2 minutes. Stay light on your toes and keep every touch close."
        case "Sole Roll and Push":
            "Place two cones about 8 steps apart. Put the sole of one foot on the ball and roll it sideways across your body. Immediately use the inside of your other foot to push the ball forward. Follow the ball, then repeat the roll and push while moving toward the cone. Turn around, switch the rolling foot, and continue for 2 minutes. Keep your knees bent and the ball close."
        case "First Touch Finish":
            "Pass the ball against a wall, move toward the return, take one touch into space, and shoot with your second touch. Complete 10 shots with each foot."
        case "Target Corners":
            "Mark the four corners of the goal as targets. Take 20 controlled shots, calling your target before every shot. Aim for accuracy and alternate feet."
        case "Power Shots":
            "Place the ball outside the penalty area. Approach at an angle, plant beside the ball, lock your ankle, and strike through the center with your laces. Take 10 shots with each foot."
        case "Weak Foot Finishing":
            "Set the ball near the penalty spot and use only your weaker foot. Take 20 shots, aiming low into alternating corners while keeping your ankle firm."
        case "Turn and Shoot":
            "Start with your back to goal beside a cone. Roll the ball forward, turn around the cone with one touch, and shoot quickly. Complete 10 turns each way."
        case "Volley Finish":
            "Gently toss the ball in front of you, let it bounce once, then strike it toward a goal before the second bounce. Complete 10 volleys with each foot."
        case "Figure Eight":
            "Place two cones 4 steps apart. Dribble in a figure-eight pattern using both feet, keeping the ball close and looking up between turns for 2 minutes."
        case "Zigzag Sprint":
            "Set up 8 cones in a zigzag. Dribble through them at speed, cut sharply at every cone, walk back, and repeat for 2 minutes."
        case "Scissors Move":
            "Dribble toward a cone, circle one foot around the front of the ball, then push away with the outside of the other foot. Alternate sides for 2 minutes."
        case "Change of Pace":
            "Set two cones 12 steps apart. Dribble slowly for the first half, then push the ball forward and sprint to the second cone. Turn and repeat for 2 minutes."
        case "Shield and Turn":
            "Use a cone as a defender. Keep your body between the cone and ball, hold the ball for two seconds, then turn away with the sole or outside of your foot. Alternate sides for 2 minutes."
        case "Cruyff Turn":
            "Dribble toward a cone, fake a pass, then pull the ball behind your standing leg with the inside of your foot. Turn and accelerate away. Complete 10 each side."
        case "Long Passing":
            "Place a target 20 steps away. Strike under the ball with your laces to reach the target. Complete 10 long passes with each foot, focusing on direction before power."
        case "Two Touch Passing":
            "Stand near a wall. Use your first touch to control the return across your body and your second touch to pass. Complete 25 repetitions with each foot."
        case "Driven Wall Pass":
            "Mark a target on a wall. Plant beside the ball and drive a firm pass with your laces through the target. Control the return and complete 20 passes with each foot."
        case "Aerial Control":
            "Toss the ball above waist height, cushion it with your foot, and stop it within one step. Complete 10 controls with each foot."
        case "First Touch Gates":
            "Make three cone gates around you. Pass against a wall, choose a gate, and guide your first touch through it. Complete 20 controlled first touches."
        case "Thigh Control":
            "Toss the ball toward your thigh, relax your leg to cushion it downward, then control it with your foot. Complete 20 clean controls, alternating thighs."
        case "Chest Control":
            "Gently toss the ball above chest height. Lean back slightly, cushion it down with your chest, and control it with your foot. Complete 15 safe repetitions."
        case "Cushion Touch":
            "Pass firmly against a wall. As the ball returns, pull your receiving foot backward on contact so the ball stops close to you. Complete 20 touches with each foot."
        case "Outside Foot Control":
            "Pass against a wall, receive with the outside of your foot, and guide the ball across your body into space. Complete 20 controls with each foot."
        case "Set Position Saves":
            "Stand with feet shoulder-width apart, knees bent, weight forward, and hands ready. Have a partner gently roll or pass 20 balls toward you. Get set before each ball, catch securely, and bring it into your chest."
        case "Low Diving Saves":
            "Use soft grass or a padded mat. Start on your knees while a partner gently rolls the ball one step to either side. Move your hands first, land on your side instead of your elbow, secure the ball, and complete 10 safe saves each way."
        case "Goalkeeper Footwork":
            "Place four cones in a small square. Stay in your ready position and move around the square using quick side steps without crossing your feet. Reset in the center after every lap and continue for 2 minutes."
        case "Angle Positioning":
            "Set one cone in the goal center and three shooting cones in an arc. Move from the center toward each cone, staying between the ball and goal. Get set, hold for two seconds, then recover. Complete 5 rounds."
        case "Throw Distribution":
            "Set three cone targets at short, medium, and long distances. Practice 10 underarm rolls, 10 sidearm throws, and 10 overarm throws. Step toward the target and focus on accuracy."
        case "Cross Collection":
            "Work with a partner using gentle high tosses. Call for the ball, step forward, jump from one leg, raise the other knee for protection, and catch at the highest safe point. Complete 12 controlled catches."
        case "Reaction Saves":
            "Stand 3 steps from a partner in your ready position. Have them point left or right before gently rolling the ball that way. React quickly, get both hands behind the ball, and complete 20 saves."
        case "1v1 Goalkeeper":
            "Make a small goal and work with a partner. Start on your line, move forward under control as the attacker approaches, stay tall and balanced, then set before the shot. Complete 10 turns and switch roles."
        case "High Ball Catch":
            "Have a partner gently toss the ball above your head. Call for the ball, jump from one leg, catch it at the highest safe point, and secure it to your chest. Complete 15 catches."
        case "Jockeying":
            "Place two cones 8 steps apart. Face forward in a low defensive stance, stay on your toes, and shuffle between the cones without crossing your feet. Keep your body slightly sideways and repeat for 2 minutes."
        case "Defensive Shuffle":
            "Set three cones in a straight line. Shuffle quickly from the middle cone to each outside cone, touch it, and return to the middle. Stay low and balanced for 2 minutes."
        case "Close Down":
            "Place a cone 10 steps away as the attacker. Sprint toward it, then slow down 2 steps before the cone. Arrive sideways, balanced, and ready to block. Reset and repeat 12 times."
        case "Recovery Run":
            "Place one cone at the starting line and another 15 steps behind you. Begin in a defensive stance, turn quickly, sprint to the back cone, then recover into position. Complete 10 runs on each turning side."
        case "Block and Clear":
            "Place a cone as the attacker and stand 5 steps away. Close the space, plant firmly, block an imaginary shot, then clear the ball safely toward a wide target. Complete 10 clearances with each foot."
        case "1v1 Shadow":
            "Work with a partner in a small cone box. The attacker moves without tackling while the defender stays goal-side and mirrors every turn. Switch roles after 45 seconds and complete three rounds each."
        case "Backpedal and Turn":
            "Backpedal from the first cone to the second, turn over one shoulder, and sprint to the third cone. Alternate turning sides for 12 repetitions."
        case "Running":
            "Warm up by walking for 1 minute. Run at a comfortable, steady pace for 8 minutes, then walk for the final minute. Keep your shoulders relaxed, breathe steadily, and stop if you feel pain."
        case "Abs Circuit":
            "Complete three rounds: 10 crunches, a 20-second plank, 10 bicycle crunches on each side, and 10 slow leg raises. Rest for 20 seconds between rounds and keep your lower back controlled."
        case "Arm Strength":
            "Complete three rounds of 8 push-ups, 10 chair triceps dips, and a 20-second high plank. Use knee push-ups if needed and keep a straight line from your head to your knees or heels."
        case "Leg Strength":
            "Complete three rounds of 12 squats, 8 reverse lunges on each leg, 12 calf raises, and a 20-second wall sit. Keep your knees lined up with your toes and move with control."
        case "Chest Workout":
            "Complete three rounds of 8 regular push-ups, 6 wide push-ups, and a 20-second push-up hold at the top. Use your knees when needed and keep your body straight."
        case "Full Body Workout":
            "Complete three rounds of 10 squats, 8 push-ups, 10 mountain climbers on each side, 8 reverse lunges on each leg, and a 20-second plank. Rest for 30 seconds between rounds."
        case "Agility Sprints":
            "Place two cones 10 steps apart. Sprint to the second cone, slow down under control, and walk back. Repeat 8 times, resting for 20 seconds between sprints."
        case "Recovery Stretch":
            "Move gently through calf, quadriceps, hamstring, hip, chest, and shoulder stretches. Hold each stretch for 20 seconds per side without bouncing, breathe slowly, and never stretch into pain."
        case "Shuttle Runs":
            "Place two cones 10 steps apart. Sprint to the far cone, touch the ground, and sprint back. Complete 8 shuttles with 20 seconds of rest between rounds."
        case "Near Post Finish", "Cutback Finish":
            "Use a ball, a safe goal, and one marker. Focus on a controlled setup touch and accurate finishing."
        case "V-Cut Dribble", "Double Touch":
            "Use a ball and two markers. Repeat the move with both feet while keeping the ball close."
        case "Triangle Passing", "Outside Foot Pass":
            "Use a wall or partner and nearby markers. Focus on clean technique and accurate passes."
        case "Bounce Control", "Half Turn Control":
            "Use a ball and a safe space. Cushion every touch and move the ball into space under control."
        case "Foundation Touches", "Small Space Weave":
            "Use a soft ball in a clear indoor space. Stay light on your feet and keep every touch close."
        case "Scoop Saves", "Quick Hands":
            "Work with a partner using gentle service. Get set before each ball and secure it safely."
        case "Interception Steps", "Clear and Recover":
            "Use markers to practice reading the pass, stepping in under control, and recovering your position."
        case "Balance Circuit", "Quick Feet":
            "Move with control, keep your knees soft, and rest briefly whenever your form starts to drop."
        default:
            nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 64, weight: .bold))
                    Text(drillCategory.uppercased())
                        .font(.headline)
                        .fontWeight(.black)
                }
                .foregroundStyle(Color.soccerNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .background(
                    LinearGradient(
                        colors: [Color.soccerLime, Color.soccerGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Text(drill.name)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Picker("Difficulty", selection: $trainingDifficulty) {
                    ForEach(PassTurnDifficulty.allCases) { difficulty in
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
                        title: "LEVEL",
                        value: "DEVELOPING",
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
                .foregroundStyle(Color.soccerGreen)

                Label(
                    "Keep your device on and unlocked during the drill so the screen does not turn off.",
                    systemImage: "iphone.gen3.radiowaves.left.and.right"
                )
                .font(.headline)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.soccerGold.opacity(0.18))
                .clipShape(.rect(cornerRadius: 14))
                .padding(.horizontal, 20)

            if isPassAndTurnDrill {
                Text(passAndTurnInstructions)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(24)
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.black, lineWidth: 3)
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
                    .background(calloutsActive ? Color.red : Color.black)
                    .foregroundStyle(Color.soccerCream)
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
                            .stroke(.black, lineWidth: 3)
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
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                            let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
                            if remaining > 0 {
                                shootingCooldown = remaining
                            } else {
                                shootingCooldown = 0
                                timer.invalidate()
                                DrillTimerLiveActivity.shared.finish()
                            }
                        }
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.soccerGreen)
                    .foregroundStyle(Color.soccerCream)
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
                    .background(shootingCooldown == 0 ? Color.soccerGreen : Color.gray)
                    .foregroundStyle(Color.soccerCream)
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
                                .stroke(.black, lineWidth: 3)
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
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
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
                    }
                }
                .font(.title2)
                .padding()
                .background(timerActive ? Color.red : Color.black)
                .foregroundStyle(Color.soccerCream)
                .clipShape(.rect(cornerRadius: 12))
            }

            if showThankYou {
                Text("Good job, keep it up!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soccerGreen)

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
                        .foregroundStyle(Color.soccerGreen)
                } else {
                    Button("Complete") {
                        completeDrill()
                    }
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.soccerGreen)
                    .foregroundStyle(Color.soccerCream)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 40)
                }
            }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 104)
        }
        .foregroundStyle(Color.soccerCream)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.soccerNavy.ignoresSafeArea())
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
                .foregroundStyle(Color.soccerLime)
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

            Text("Points stay fixed. XP is calculated from your successful results and \(drillDuration / 60) minutes of training.")
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
            .background(hasValidScore ? Color.soccerGreen : Color.gray)
            .foregroundStyle(Color.white)
            .clipShape(.rect(cornerRadius: 14))
            .disabled(!hasValidScore)
        }
        .padding(32)
        .foregroundStyle(Color.soccerCream)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.soccerNavy.ignoresSafeArea())
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

        let previousLevel = playerXP / 500 + 1
        awardedPoints = pointsAward
        awardedXP = xpAward
        totalPoints += pointsAward
        playerXP += xpAward
        totalTrainingMinutes += drillDuration / 60
        totalSessions += 1

        switch drillCategory {
        case "Shooting":
            shootingXP += xpAward
            totalGoals += recordedSuccesses
            totalShots += recordedAttempts
        case "Dribbling":
            dribblingXP += xpAward
            totalDribblingAttempts += recordedAttempts
        case "Passing":
            passingXP += xpAward
            totalPasses += recordedSuccesses
        case "Control":
            controlXP += xpAward
            totalControls += recordedSuccesses
        case "Workout":
            fitnessXP += xpAward
        default:
            break
        }

        updateTrainingStreak()

        let newLevel = playerXP / 500 + 1
        if newLevel > previousLevel {
            let levelsGained = newLevel - previousLevel
            rewardBoxes += levelsGained
        }
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

// DrillCoaching.swift
// Coaching guidance shown on each drill's detail page: setup, coaching points,
// common mistakes, progressions, and regressions. Written per skill, so every
// drill in a skill gets consistent, relevant advice, and the setup line is
// built from that drill's own equipment and space.

import Foundation

struct DrillCoaching {
    let setup: [String]
    let coachingPoints: [String]
    let commonMistakes: [String]
    let progressions: [String]
    let regressions: [String]

    static func forDrill(_ info: DrillInfo) -> DrillCoaching {
        let skill = skillContent(for: info.skill)
        let space = info.isIndoor
            ? "A small, clear indoor space with a safe wall or floor"
            : (info.playerCount == .solo ? "About a 10 x 10 m area" : "About a 15 x 15 m area")
        let players: String
        switch info.playerCount {
        case .solo: players = "Works solo, no partner needed"
        case .partner: players = "Needs a partner or training buddy"
        case .group: players = "Needs three or more players"
        }

        return DrillCoaching(
            setup: [
                "Equipment: 1 ball" + (info.equipmentText.isEmpty ? "" : ", \(info.equipmentText)"),
                "Space: \(space)",
                players,
            ],
            coachingPoints: skill.points,
            commonMistakes: skill.mistakes,
            progressions: skill.progressions,
            regressions: skill.regressions
        )
    }

    private struct SkillContent {
        let points: [String]
        let mistakes: [String]
        let progressions: [String]
        let regressions: [String]
    }

    private static func skillContent(for skill: String) -> SkillContent {
        switch skill {
        case "Shooting":
            SkillContent(
                points: [
                    "Plant your standing foot beside the ball, not behind it",
                    "Pick a specific target before every strike",
                    "Keep your head still and your eyes on the ball at contact",
                    "Follow through toward the target",
                ],
                mistakes: [
                    "Leaning back and skying the ball",
                    "Aiming at the keeper instead of a target corner",
                    "Rushing the strike before the technique is set",
                    "Using only your stronger foot",
                ],
                progressions: [
                    "Add a moving pass or a defender before the shot",
                    "Shorten your approach so you have less time to set up",
                    "Shoot after a first touch rather than from a standing ball",
                ],
                regressions: [
                    "Shoot from a stationary ball at a closer distance",
                    "Use a bigger target, such as a full goal",
                    "Take a slow run-up and focus on clean contact",
                ]
            )
        case "Dribbling":
            SkillContent(
                points: [
                    "Keep the ball within one step of your body",
                    "Change direction with your body, not just your feet",
                    "Use the inside and outside of both feet",
                    "Accelerate away after the move, not during it",
                ],
                mistakes: [
                    "Pushing the ball too far ahead of you",
                    "Looking down at the ball the whole time",
                    "Slowing down before the feint",
                    "Using only one foot",
                ],
                progressions: [
                    "Add a passive defender to react to",
                    "Chain two moves together without stopping",
                    "Finish each rep with a shot on goal",
                ],
                regressions: [
                    "Slow the pace and walk through each move",
                    "Widen the gaps between cones",
                    "Use one move per rep until it feels natural",
                ]
            )
        case "Passing":
            SkillContent(
                points: [
                    "Open your hips and use the inside of your foot for accuracy",
                    "Strike through the middle of the ball",
                    "Keep your standing foot beside the ball",
                    "Match the weight of the pass to the distance",
                ],
                mistakes: [
                    "Passing with a locked ankle or the toe",
                    "Looking up only after the pass is already gone",
                    "Hitting every pass with the same power",
                    "Standing still while the ball is moving",
                ],
                progressions: [
                    "Limit yourself to one or two touches",
                    "Pass on the move to a target",
                    "Increase the rhythm, then pass with your weaker foot",
                ],
                regressions: [
                    "Pass to a closer target",
                    "Let the ball stop before you pass",
                    "Use a larger target gate",
                ]
            )
        case "Control", "First Touch":
            SkillContent(
                points: [
                    "Set your first touch into the space you want to go",
                    "Cushion the ball softly, with relaxed joints",
                    "Keep the ball within reach for your next touch",
                    "Watch the ball all the way onto your surface",
                ],
                mistakes: [
                    "Stiff contact that bounces the ball away",
                    "Watching the ball too late",
                    "Reaching for the ball instead of moving your feet",
                    "Taking the first touch too far from your body",
                ],
                progressions: [
                    "Receive higher or faster passes",
                    "Add a turn or a pass straight after the touch",
                    "Receive under light pressure from a defender",
                ],
                regressions: [
                    "Use a slower feed or a rolled ball",
                    "Stay still and only cushion the ball",
                    "Use a bigger target area",
                ]
            )
        case "Technique":
            SkillContent(
                points: [
                    "Go slowly at first to groove the movement",
                    "Keep the ball close throughout the skill",
                    "Sell the fake with your head and shoulders",
                    "Accelerate out of the move, not into it",
                ],
                mistakes: [
                    "Rushing the move before it is controlled",
                    "Losing the ball during the spin",
                    "Telegraphing the move with a big set-up",
                    "Getting stuck in the move instead of exploding out",
                ],
                progressions: [
                    "Perform the move at game speed",
                    "Chain it with a second move",
                    "Finish with a pass or a shot",
                ],
                regressions: [
                    "Walk through each step",
                    "Use a stationary ball",
                    "Use wider gaps between cones",
                ]
            )
        case "Speed & Finishing":
            SkillContent(
                points: [
                    "Sprint with full effort, then settle the touch",
                    "Look up before the final touch to see the target",
                    "Stay balanced and composed on the strike",
                    "Breathe between reps to keep your technique",
                ],
                mistakes: [
                    "Hurrying the finish and sending it wide",
                    "Losing your shape when you get tired",
                    "Carrying the ball too far ahead of you",
                    "Skipping the settle touch",
                ],
                progressions: [
                    "Add a defender or a keeper",
                    "Finish with your weaker foot",
                    "Reduce the rest between reps",
                ],
                regressions: [
                    "Jog to the ball and finish slowly",
                    "Allow a second touch before the shot",
                    "Shorten the sprint distance",
                ]
            )
        case "Soccer IQ":
            SkillContent(
                points: [
                    "Scan over both shoulders before the ball arrives",
                    "Say your decision out loud as you make it",
                    "Choose the first option that is safe and forward",
                    "Move to create an option before you receive",
                ],
                mistakes: [
                    "Looking down at the ball when it arrives",
                    "Choosing the first pass without checking",
                    "Waiting for the ball instead of moving",
                    "Making the same decision on every rep",
                ],
                progressions: [
                    "Add more visual cues to read",
                    "Make each decision faster",
                    "Add a defender who reacts to you",
                ],
                regressions: [
                    "Use one visual cue at a time",
                    "Slow the tempo down",
                    "Reduce the number of options",
                ]
            )
        case "Goalkeeping":
            SkillContent(
                points: [
                    "Set your feet and stay on your toes before each shot",
                    "Move your feet to get behind the ball",
                    "Use your hands to smother or parry, not just reach",
                    "Get back on your feet quickly for the rebound",
                ],
                mistakes: [
                    "Diving too early and letting the shot go over you",
                    "Standing flat-footed when the shot comes",
                    "Parrying the ball toward danger",
                    "Forgetting to call and communicate",
                ],
                progressions: [
                    "Increase the shot speed and the angles",
                    "Add a rebound you have to win",
                    "React to a visual cue before the shot",
                ],
                regressions: [
                    "Use slower, closer shots",
                    "Start from a stationary, set position",
                    "Catch rather than parry",
                ]
            )
        case "Defense":
            SkillContent(
                points: [
                    "Stay on your toes and keep the attacker in front of you",
                    "Show the attacker away from goal",
                    "Time the tackle for when the ball is away from their feet",
                    "Recover quickly after every duel",
                ],
                mistakes: [
                    "Diving in too early",
                    "Standing upright and getting beaten",
                    "Crossing your feet and losing your balance",
                    "Chasing without cutting off the angle",
                ],
                progressions: [
                    "Add a live attacker who is dribbling the ball",
                    "Add a second defender to cover",
                    "Add a recovery sprint after each duel",
                ],
                regressions: [
                    "Slow the attacker down to a walk",
                    "Use a wider space",
                    "Start from a stationary stance",
                ]
            )
        case "Plus Training":
            SkillContent(
                points: [
                    "Keep clean technique at match speed",
                    "Slow down briefly if control drops, then rebuild the speed",
                    "Talk yourself through each rep",
                    "Rest fully between sets to keep quality high",
                ],
                mistakes: [
                    "Speeding up before the technique is secure",
                    "Skipping the rest between rounds",
                    "Losing shape late in the circuit",
                    "Trying every rep too hard",
                ],
                progressions: [
                    "Shorten the rest periods",
                    "Add a defender or a time limit",
                    "Add reps or link it to a second drill",
                ],
                regressions: [
                    "Slow down the tempo",
                    "Reduce the number of reps",
                    "Remove the time limit",
                ]
            )
        case "Workout":
            SkillContent(
                points: [
                    "Breathe steadily and keep your core braced",
                    "Land softly with your knees over your toes",
                    "Keep your posture upright through each rep",
                    "Rest and drink water between efforts",
                ],
                mistakes: [
                    "Holding your breath during effort",
                    "Letting the knees collapse inward on landing",
                    "Rushing reps and losing form",
                    "Skipping the warm-up",
                ],
                progressions: [
                    "Add reps or hold times",
                    "Increase the speed or add a jump",
                    "Reduce the rest between sets",
                ],
                regressions: [
                    "Reduce the range of motion or the reps",
                    "Slow the tempo",
                    "Take more rest between sets",
                ]
            )
        default:
            SkillContent(
                points: [
                    "Use good form on every rep",
                    "Rest briefly when you need to",
                    "Keep the quality high before adding speed",
                ],
                mistakes: [
                    "Rushing before the technique is controlled",
                    "Ignoring fatigue that breaks your form",
                ],
                progressions: [
                    "Add speed or reps once the form is consistent",
                ],
                regressions: [
                    "Slow the tempo and reduce the reps",
                ]
            )
        }
    }
}

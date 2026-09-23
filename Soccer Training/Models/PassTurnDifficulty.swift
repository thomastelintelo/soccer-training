// PassTurnDifficulty.swift
// Difficulty levels for the Pass and Turn drill, and their effect on
// callout pace, reward, and overall drill duration.

import Foundation

enum PassTurnDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var calloutInterval: TimeInterval {
        switch self {
        case .easy:
            12
        case .medium:
            8
        case .hard:
            5
        }
    }

    var reward: Int {
        switch self {
        case .easy:
            0
        case .medium:
            10
        case .hard:
            20
        }
    }

    var durationMultiplier: Double {
        switch self {
        case .easy: 0.7
        case .medium: 1
        case .hard: 1.3
        }
    }
}

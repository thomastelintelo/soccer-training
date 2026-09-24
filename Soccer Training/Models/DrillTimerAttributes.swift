//
//  DrillTimerAttributes.swift
//  Soccer Training
//
//  Shared shape of the drill timer Live Activity.
//  A matching copy lives in SoccerTrainingWidget/DrillTimerLiveActivity.swift.
//  Keep the two definitions identical, or the widget won't be able to decode the activity.
//

import ActivityKit
import Foundation
import SwiftUI

nonisolated struct DrillTimerColorComponents: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

/// Snapshot of the app's team-based theme, captured when the activity starts
/// since the widget extension can't read the app's favorite-team setting itself.
nonisolated struct DrillTimerTheme: Codable, Hashable {
    var accent: DrillTimerColorComponents
    var background: DrillTimerColorComponents
    var surface: DrillTimerColorComponents
}

nonisolated struct DrillTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isFinished: Bool
    }

    var drillName: String
    var category: String
    var startDate: Date
    var endDate: Date
    var theme: DrillTimerTheme
}

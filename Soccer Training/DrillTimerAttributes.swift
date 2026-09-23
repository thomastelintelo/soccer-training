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

nonisolated struct DrillTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isFinished: Bool
    }

    var drillName: String
    var category: String
    var startDate: Date
    var endDate: Date
}

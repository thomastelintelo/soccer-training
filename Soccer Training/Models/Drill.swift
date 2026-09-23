// Drill.swift
// The basic drill and training-schedule model types.

import Foundation

struct Drill: Identifiable {
    let id = UUID()
    let name: String
}

struct Topic: Identifiable {
    let id = UUID()
    let name: String
    let drills: [Drill]
}

struct ScheduleItem: Identifiable {
    let id: Int
    let focus: String
    let drillName: String
}

struct ScheduleDay: Identifiable {
    let day: String
    let drills: [ScheduleItem]

    var id: String {
        day
    }
}

// Drill.swift
// The basic drill and training-schedule model types.

import Foundation

struct Drill: Identifiable {
    let name: String

    // A stable id derived from the name, not a fresh UUID(). `topics` is
    // rebuilt (with all-new Drill/Topic values) on every ContentView
    // re-render, which happens often — e.g. whenever totalPoints changes
    // from finishing a drill. A random id would change on every rebuild,
    // desyncing NavigationLink identity from what's on screen and making
    // taps resolve to the wrong drill (or appear to do nothing).
    var id: String { name }
}

struct Topic: Identifiable {
    let name: String
    let drills: [Drill]

    var id: String { name }
}

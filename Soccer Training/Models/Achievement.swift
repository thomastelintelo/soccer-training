// Achievement.swift
// A single unlockable milestone, shown on the Profile tab. Generalizes what
// used to be a private type inside ProfileView so it can grow without that
// view's achievement list staying a one-off.

import Foundation

struct Achievement: Identifiable {
    let title: String
    let detail: String
    let systemImage: String
    let isUnlocked: Bool

    var id: String { title }
}

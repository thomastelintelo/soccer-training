// ProfilePlayerCardView.swift
// Wraps PlayerCardShell for the signed-in user: their own photo, position,
// training level, and skill ratings in place of a catalog SoccerPlayer.

import SwiftUI
import UIKit

struct ProfilePlayerCardView: View {
    let name: String
    let position: String
    let level: Int
    let overall: Int
    let photo: UIImage?
    let stats: [PlayerCardStat]

    var body: some View {
        PlayerCardShell(
            name: name,
            position: position,
            overall: overall,
            badgeText: "LVL \(level)",
            stats: stats
        ) {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.soccerCream.opacity(0.7))
                    .padding(PlayerCardLayout.photoSize.width * 0.22)
            }
        }
    }
}

// AvatarView.swift
// A circular avatar: a photo if there is one, otherwise initials over a
// deterministic gradient (stable across launches, so the same name always
// gets the same colors). Used for the signed-in player and leaderboard bots.

import SwiftUI
import UIKit

struct AvatarView: View {
    let name: String
    var photo: UIImage? = nil
    let size: CGFloat

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    private var palette: (light: Color, dark: Color) {
        swatches[StableHash.value(name) % swatches.count]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: [palette.light, palette.dark], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            }
        }
        .frame(width: size, height: size)
    }

    private let swatches: [(light: Color, dark: Color)] = [
        (Color(red: 0.98, green: 0.36, blue: 0.36), Color(red: 0.70, green: 0.08, blue: 0.14)),
        (Color(red: 0.27, green: 0.62, blue: 0.98), Color(red: 0.06, green: 0.24, blue: 0.58)),
        (Color(red: 0.98, green: 0.73, blue: 0.20), Color(red: 0.74, green: 0.45, blue: 0.03)),
        (Color(red: 0.42, green: 0.84, blue: 0.56), Color(red: 0.05, green: 0.42, blue: 0.27)),
        (Color(red: 0.72, green: 0.45, blue: 0.98), Color(red: 0.35, green: 0.12, blue: 0.62)),
        (Color(red: 0.98, green: 0.52, blue: 0.75), Color(red: 0.64, green: 0.11, blue: 0.38)),
        (Color(red: 0.33, green: 0.85, blue: 0.85), Color(red: 0.04, green: 0.42, blue: 0.46)),
        (Color(red: 0.98, green: 0.58, blue: 0.30), Color(red: 0.68, green: 0.26, blue: 0.03)),
    ]
}

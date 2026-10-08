// PlayerCardShell.swift
// An Ultimate-Team-style player card shell: the signature tapered shield
// outline, a wide photo that fades into the card instead of sitting in a
// circle, tiered foil background, and six derived sub-stats. Wrapped by
// ProfilePlayerCardView for the signed-in user.

import SwiftUI

enum PlayerCardTier {
    case special
    case gold
    case silver
    case bronze

    static func tier(for overall: Int) -> PlayerCardTier {
        switch overall {
        case 90...: .special
        case 80..<90: .gold
        case 65..<80: .silver
        default: .bronze
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .special: [Color.black, Color(red: 0.08, green: 0.08, blue: 0.1), Color(red: 0.05, green: 0.07, blue: 0.12)]
        case .gold: [Color(red: 1.0, green: 0.88, blue: 0.5), Color(red: 0.93, green: 0.72, blue: 0.22), Color(red: 0.64, green: 0.45, blue: 0.06)]
        case .silver: [Color(white: 0.96), Color(white: 0.8), Color(white: 0.55)]
        case .bronze: [Color(red: 0.87, green: 0.65, blue: 0.42), Color(red: 0.72, green: 0.48, blue: 0.26), Color(red: 0.45, green: 0.28, blue: 0.13)]
        }
    }

    var foreground: Color {
        switch self {
        case .special: .white
        case .gold, .silver, .bronze: Color.soccerText
        }
    }

    var highlight: Color {
        switch self {
        case .special: Color.soccerAccentLight
        case .gold, .silver, .bronze: Color.soccerText.opacity(0.65)
        }
    }
}

/// The tapered shield/crest silhouette every Ultimate-Team-style card is
/// instantly recognized by: a flat, rounded top that narrows through the
/// lower third to a single point at the bottom center.
private struct PlayerCardSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let topRadius = w * 0.12
        let taperStart = h * 0.88

        var path = Path()
        path.move(to: CGPoint(x: 0, y: topRadius))
        path.addArc(
            center: CGPoint(x: topRadius, y: topRadius),
            radius: topRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: w - topRadius, y: 0))
        path.addArc(
            center: CGPoint(x: w - topRadius, y: topRadius),
            radius: topRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: w, y: taperStart))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 0.86, y: h * 0.96)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: taperStart),
            control: CGPoint(x: w * 0.14, y: h * 0.96)
        )
        path.closeSubpath()
        return path
    }
}

enum PlayerCardLayout {
    static let photoDiameter: CGFloat = 128
}

struct PlayerCardShell<Photo: View>: View {
    let name: String
    let position: String
    let overall: Int
    let badgeText: String?
    let stats: [PlayerCardStat]
    @ViewBuilder let photo: () -> Photo

    private var tier: PlayerCardTier { .tier(for: overall) }

    private let statColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(overall)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                    Text(position)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                }

                Spacer()

                if let badgeText {
                    Text(badgeText)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tier.foreground.opacity(0.15), in: .capsule)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            photo()
                .frame(width: PlayerCardLayout.photoDiameter, height: PlayerCardLayout.photoDiameter)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(tier.highlight, lineWidth: 2)
                }
                .padding(.top, 6)

            Text(name.uppercased())
                .font(.system(size: 14, weight: .heavy))
                .tracking(1.4)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 12)
                .padding(.top, 2)

            Rectangle()
                .fill(tier.highlight.opacity(0.6))
                .frame(height: 1)
                .padding(.horizontal, 32)
                .padding(.top, 6)

            LazyVGrid(columns: statColumns, spacing: 4) {
                ForEach(stats) { stat in
                    HStack(spacing: 6) {
                        Text("\(stat.value)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .frame(width: 24, alignment: .trailing)
                        Text(stat.label)
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                            .opacity(0.75)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .foregroundStyle(tier.foreground)
        .frame(width: 220, height: 300)
        .background {
            ZStack {
                LinearGradient(
                    colors: tier.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                // A diagonal foil sheen, like the light-catching finish on a
                // real card, strongest on the rarest tier.
                LinearGradient(
                    colors: [.white.opacity(tier == .special ? 0.16 : 0.1), .clear, .white.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipShape(PlayerCardSilhouette())
        .overlay {
            PlayerCardSilhouette()
                .stroke(tier.highlight, lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
    }
}

// Color+Soccer.swift
// App-wide palette and field-inspired background.

import SwiftUI

extension Color {
    static let soccerBackground = Color(red: 0.04, green: 0.04, blue: 0.045)
    static let soccerSurface = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let soccerSurfaceStrong = Color(red: 0.17, green: 0.16, blue: 0.14)
    static let soccerText = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let soccerAccent = Color(red: 0.93, green: 0.72, blue: 0.16)
    static let soccerAccentLight = Color(red: 1.00, green: 0.84, blue: 0.40)
    static let soccerGold = Color(red: 1.00, green: 0.76, blue: 0.20)
}

struct SoccerBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.055),
                    Color(red: 0.03, green: 0.03, blue: 0.03),
                    Color(red: 0.07, green: 0.06, blue: 0.04),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.soccerAccent.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 320
            )

            GeometryReader { proxy in
                let size = proxy.size

                Path { path in
                    let inset: CGFloat = 24
                    let field = CGRect(
                        x: inset,
                        y: inset,
                        width: max(0, size.width - inset * 2),
                        height: max(0, size.height - inset * 2)
                    )

                    path.addRoundedRect(in: field, cornerSize: CGSize(width: 24, height: 24))
                    path.move(to: CGPoint(x: field.minX, y: field.midY))
                    path.addLine(to: CGPoint(x: field.maxX, y: field.midY))
                    path.addEllipse(
                        in: CGRect(
                            x: field.midX - 46,
                            y: field.midY - 46,
                            width: 92,
                            height: 92
                        )
                    )
                }
                .stroke(Color.soccerAccent.opacity(0.08), lineWidth: 2)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

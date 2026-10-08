// Color+Soccer.swift
// App-wide palette and field-inspired background.

import SwiftUI

extension Color {
    static let soccerBackground = Color(red: 0.96, green: 0.98, blue: 1.00)
    static let soccerSurface = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let soccerSurfaceStrong = Color(red: 0.90, green: 0.92, blue: 0.95)
    static let soccerText = Color(red: 0.08, green: 0.10, blue: 0.14)
    static let soccerAccent = Color(red: 0.07, green: 0.42, blue: 0.93)
    static let soccerAccentLight = Color(red: 0.38, green: 0.64, blue: 0.98)
    static let soccerGold = Color(red: 1.00, green: 0.76, blue: 0.20)
}

struct SoccerBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.98, blue: 1.00),
                    Color(red: 0.93, green: 0.98, blue: 0.96),
                    Color(red: 0.97, green: 0.98, blue: 1.00),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.soccerAccent.opacity(0.10), .clear],
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
                .stroke(Color.soccerAccent.opacity(0.055), lineWidth: 2)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

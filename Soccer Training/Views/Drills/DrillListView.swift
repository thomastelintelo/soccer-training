// DrillListView.swift
// Lists every drill in a chosen topic, with duration and point preview.

import SwiftUI

struct DrillListView: View {
    let topic: String
    let drills: [Drill]
    @Binding var totalPoints: Int
    @AppStorage("isProMember") private var isProMember = false

    private func displayedPoints(for drillName: String) -> Int {
        let basePoints = DrillTimerView.minimumPoints(for: drillName)
        return isProMember ? basePoints * 5 / 4 : basePoints
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(drills) { drill in
                    NavigationLink {
                        DrillTimerView(drill: drill, totalPoints: $totalPoints)
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Image(systemName: "figure.soccer")
                                    .font(.system(size: 42, weight: .bold))
                                Spacer()
                                Text(topic.uppercased())
                                    .font(.caption)
                                    .fontWeight(.black)
                            }
                            .foregroundStyle(Color.soccerNavy)
                            .padding(18)
                            .background(
                                LinearGradient(
                                    colors: [Color.soccerLime, Color.soccerGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                            VStack(alignment: .leading, spacing: 10) {
                                Text(drill.name)
                                    .font(.title2)
                                    .fontWeight(.heavy)

                                HStack(spacing: 16) {
                                    Label("\(DrillTimerView.duration(for: drill.name) / 60) min", systemImage: "clock.fill")
                                    Label("+\(displayedPoints(for: drill.name)) pts", systemImage: "star.fill")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.soccerLime)

                                Text(DrillPresentation.focus(for: topic))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.soccerCream.opacity(0.75))

                                HStack {
                                    Label("View full session", systemImage: "list.bullet.clipboard.fill")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.soccerLime)
                                }
                            }
                            .padding(16)
                        }
                        .foregroundStyle(Color.soccerCream)
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.soccerGreen.opacity(0.8), lineWidth: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color.soccerNavy)
        .foregroundStyle(Color.soccerCream)
        .navigationTitle(topic)
        .safeAreaPadding(.bottom, 72)
    }
}

// AllDrillsView.swift
// The Drills tab: grid of drill categories, with Plus Training gated
// behind the subscription.

import SwiftUI

struct AllDrillsView: View {
    let topics: [Topic]
    @Binding var totalPoints: Int
    @AppStorage("isProMember") private var isProMember = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.soccerNavy, Color.soccerSurface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    DrillsHeaderView(
                        totalDrills: topics.reduce(0) { $0 + $1.drills.count },
                        totalPoints: totalPoints
                    )

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(topics) { topic in
                            if topic.name == "Plus Training" && !isProMember {
                                DrillCategoryCard(
                                    name: topic.name,
                                    drillCount: topic.drills.count
                                )
                                .opacity(0.62)
                                .overlay(alignment: .topTrailing) {
                                    Label("PLUS LOCKED", systemImage: "lock.fill")
                                        .font(.caption2.weight(.heavy))
                                        .foregroundStyle(Color.soccerNavy)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color.soccerLime, in: Capsule())
                                        .padding(8)
                                }
                                .accessibilityLabel("Plus Training locked. Subscribe to Futbol Trainnier Plus in the shop.")
                            } else {
                                NavigationLink {
                                    DrillListView(
                                        topic: topic.name,
                                        drills: topic.drills,
                                        totalPoints: $totalPoints
                                    )
                                } label: {
                                    DrillCategoryCard(
                                        name: topic.name,
                                        drillCount: topic.drills.count
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .foregroundStyle(Color.soccerCream)
        .navigationTitle("Plus Training Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DrillsHeaderView: View {
    let totalDrills: Int
    let totalPoints: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "figure.soccer")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.soccerLime)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Build Your Game")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                    Text("Choose a skill and start training")
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerCream.opacity(0.72))
                }
            }

            HStack(spacing: 12) {
                Label("\(totalDrills) drills", systemImage: "list.bullet.clipboard.fill")
                Spacer()
                Label("\(totalPoints) points", systemImage: "star.fill")
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(Color.soccerLime)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [Color.soccerGreen, Color.soccerGreen.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.soccerLime.opacity(0.7), lineWidth: 2)
        }
    }
}

private struct DrillCategoryCard: View {
    let name: String
    let drillCount: Int

    private var icon: String {
        switch name {
        case "Shooting": "scope"
        case "Dribbling": "figure.soccer"
        case "Passing": "arrow.left.arrow.right"
        case "Control": "circle.grid.cross.fill"
        case "Goalkeeping": "hand.raised.fill"
        case "Defense": "shield.fill"
        default: "figure.run"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(DrillPresentation.imageName(for: name))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            LinearGradient(
                colors: [.clear, Color.soccerNavy.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Image(systemName: icon)
                    Text(name.uppercased())
                    Spacer()
                    Image(systemName: "arrow.up.right.circle.fill")
                }
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerLime)

                Text("\(drillCount) training sessions")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text(DrillPresentation.focus(for: name))
                    .font(.caption2)
                    .foregroundStyle(Color.soccerCream.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .leading)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.soccerCream.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 8, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(drillCount) drills")
    }
}

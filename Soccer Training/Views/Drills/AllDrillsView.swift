// AllDrillsView.swift
// The Drills tab: grid of drill categories, with Plus Training gated
// behind the subscription.

import SwiftUI

struct AllDrillsView: View {
    @Environment(PlusPurchaseStore.self) private var plusStore
    let topics: [Topic]
    @Binding var totalPoints: Int
    @State private var searchText = ""
    @State private var showingPlus = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    private var filteredTopics: [Topic] {
        guard !searchText.isEmpty else { return topics }
        return topics.compactMap { topic in
            let matches = topic.drills.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            guard topic.name.localizedCaseInsensitiveContains(searchText) || !matches.isEmpty else {
                return nil
            }
            return topic
        }
    }

    var body: some View {
        ZStack {
            SoccerBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    DrillsHeaderView(
                        totalDrills: topics.reduce(0) { $0 + $1.drills.count },
                        totalPoints: totalPoints
                    )

                    if !searchText.isEmpty && filteredTopics.isEmpty {
                        Text("No drills match “\(searchText)”.")
                            .font(.subheadline)
                            .foregroundStyle(Color.soccerText.opacity(0.6))
                            .padding(.top, 20)
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filteredTopics) { topic in
                            if topic.name == "Plus Training" && !plusStore.isUnlocked {
                                Button {
                                    showingPlus = true
                                } label: {
                                    DrillCategoryCard(
                                        name: topic.name,
                                        drillCount: topic.drills.count,
                                        isLocked: true
                                    )
                                }
                                .buttonStyle(.plain)
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
                                    drillCount: topic.drills.count,
                                    isLocked: false
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
        .foregroundStyle(Color.soccerText)
        .navigationTitle("Training Center")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search drills or categories")
        .sheet(isPresented: $showingPlus) {
            FutbolElitePlusView()
        }
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
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Build Your Game")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                    Text("Choose a skill and start training")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            HStack(spacing: 12) {
                Label("\(totalDrills) drills", systemImage: "list.bullet.clipboard.fill")
                Spacer()
                Label("\(totalPoints) points", systemImage: "star.fill")
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(.white)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [Color.soccerAccent, Color.soccerAccentLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(.rect(cornerRadius: 22))
    }
}

private struct DrillCategoryCard: View {
    let name: String
    let drillCount: Int
    let isLocked: Bool

    private var icon: String {
        DrillPresentation.icon(for: name)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(DrillPresentation.imageName(for: name))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .overlay {
                    // Several categories share the same handful of stock
                    // photos, so tint each category's shared photo with its
                    // own stable hue — the same trick used for individual
                    // drills — so no two category cards look identical.
                    Color(hue: DrillPresentation.photoHue(for: name), saturation: 0.55, brightness: 0.9)
                        .opacity(0.35)
                        .blendMode(.hue)
                }

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Image(systemName: icon)
                    Text(name.uppercased())
                    Spacer()
                    Image(systemName: isLocked ? "lock.fill" : "arrow.up.right.circle.fill")
                }
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundStyle(.white)

                Text(isLocked ? "PLUS • \(drillCount) elite drills" : "\(drillCount) training sessions")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(DrillPresentation.focus(for: name))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .leading)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.22), radius: 8, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(drillCount) drills")
    }
}

// SessionsView.swift
// The Sessions tab: jump straight into a guided warm-up → drills → cool-down
// session for any category, without browsing the full drill list first.
// Each category offers a Mixed Session (randomized) plus several hand-picked
// themed sessions, so there's more than one way to train the same skill.

import SwiftUI

struct SessionsView: View {
    let topics: [Topic]
    @Binding var totalPoints: Int

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            SoccerBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    header

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(topics) { topic in
                            NavigationLink {
                                SessionCategoryView(topic: topic, totalPoints: $totalPoints)
                            } label: {
                                SessionCategoryCard(name: topic.name)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
        }
        .foregroundStyle(Color.soccerText)
        .navigationTitle("Sessions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Guided Sessions")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                    Text("Pick a focus and go: warm-up, drills, cool-down.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
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

private struct SessionCategoryCard: View {
    let name: String

    private var icon: String {
        DrillPresentation.icon(for: name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                Image(DrillPresentation.imageName(for: name))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 82)
                    .frame(maxWidth: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
            }
            .frame(height: 82)
            .clipShape(.rect(cornerRadius: 12))

            Text(name)
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(DrillPresentation.focus(for: name))
                .font(.caption)
                .foregroundStyle(Color.soccerText.opacity(0.6))
                .lineLimit(2)

            Spacer(minLength: 0)

            Label("\(1 + SessionTemplateCatalog.templates(for: name).count) sessions", systemImage: "arrow.right.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.soccerAccent)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
        .background(Color.soccerSurface)
        .clipShape(.rect(cornerRadius: 18))
    }
}

/// Lists every way to train one category: the always-available Mixed
/// Session (a random 4 drills from the category) plus any hand-picked
/// SessionTemplates for it.
private struct SessionCategoryView: View {
    let topic: Topic
    @Binding var totalPoints: Int

    private var templates: [SessionTemplate] {
        SessionTemplateCatalog.templates(for: topic.name)
    }

    var body: some View {
        List {
            Section {
                Text(DrillPresentation.focus(for: topic.name))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Sessions") {
                NavigationLink {
                    SessionView(
                        title: "Mixed \(topic.name) Session",
                        category: topic.name,
                        drills: topic.drills,
                        totalPoints: $totalPoints
                    )
                } label: {
                    sessionRow(
                        name: "Mixed Session",
                        detail: "4 random \(topic.name.lowercased()) drills — a different mix every time",
                        icon: "shuffle",
                        imageName: DrillPresentation.imageName(for: topic.name)
                    )
                }

                ForEach(templates) { template in
                    NavigationLink {
                        SessionView(
                            title: template.name,
                            category: topic.name,
                            drills: topic.drills,
                            fixedDrillNames: template.drillNames,
                            totalPoints: $totalPoints
                        )
                    } label: {
                        sessionRow(
                            name: template.name,
                            detail: template.detail,
                            icon: "list.bullet.clipboard.fill",
                            imageName: DrillPresentation.imageName(
                                for: template.drillNames.first ?? topic.name,
                                category: topic.name
                            )
                        )
                    }
                }
            }
        }
        .navigationTitle(topic.name)
    }

    private func sessionRow(name: String, detail: String, icon: String, imageName: String) -> some View {
        HStack(spacing: 14) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 74, height: 62)
                .clipped()
                .clipShape(.rect(cornerRadius: 10))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .padding(5)
                        .background(Color.soccerAccent, in: Circle())
                        .foregroundStyle(.white)
                        .padding(4)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

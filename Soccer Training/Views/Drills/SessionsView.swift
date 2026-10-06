// SessionsView.swift
// The Train tab: the AI coach, a session you can resume, and guided sessions for
// each category, so you can jump straight into a warm-up → drills → cool-down.
// Each category offers a Mixed Session (randomized) plus several hand-picked
// themed sessions, so there's more than one way to train the same skill.

import SwiftUI

struct SessionsView: View {
    let topics: [Topic]
    @Binding var totalPoints: Int
    @AppStorage(ActiveSessionStore.storageKey) private var activeSessionJSON = ""
    @State private var isShowingCoach = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            Color.soccerBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    if let session = ActiveSessionStore.load() {
                        continueCard(for: session)
                    }

                    coachCard

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
        .navigationTitle("Train")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingCoach) {
            CoachView(totalPoints: $totalPoints)
        }
    }

    private var coachCard: some View {
        Button {
            Haptics.tap()
            isShowingCoach = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Color.soccerAccent)
                    .frame(width: 52, height: 52)
                    .background(.white, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("AI Coach")
                        .font(.title3)
                        .fontWeight(.heavy)
                    Text("Tell me your age, time, and gear. I'll build the session.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(.white)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color.soccerAccent, Color.soccerAccentLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22)
            )
            .shadow(color: Color.soccerAccent.opacity(0.25), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func continueCard(for session: ActiveSession) -> some View {
        NavigationLink {
            SessionRunnerView(session: session, totalPoints: $totalPoints)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Continue training", systemImage: "arrow.clockwise.circle.fill")
                        .font(.headline)
                        .fontWeight(.heavy)
                    Spacer()
                    Text("\(session.completedCount) of \(session.steps.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                Text(session.title)
                    .font(.title3)
                    .fontWeight(.bold)
                LinearProgressBar(fraction: session.progress, tint: .white)
            }
            .foregroundStyle(.white)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.soccerText, in: RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
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
            Image(systemName: icon)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.soccerAccent)

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
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
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
                        icon: "shuffle"
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
                        sessionRow(name: template.name, detail: template.detail, icon: "list.bullet.clipboard.fill")
                    }
                }
            }
        }
        .navigationTitle(topic.name)
    }

    private func sessionRow(name: String, detail: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.soccerAccent)
                .frame(width: 28)

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

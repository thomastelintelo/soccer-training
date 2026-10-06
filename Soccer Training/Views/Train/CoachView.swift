// CoachView.swift
// The AI coach. Describe yourself and what you want to work on, and it builds a
// full session from the drills in your library. It shows how it understood the
// request, explains each pick, and hands the plan to the session runner.

import SwiftUI

struct CoachView: View {
    @Binding var totalPoints: Int
    @AppStorage(FavoriteDrills.storageKey) private var favoritesText = ""
    @AppStorage(PlayerPrefKey.revision) private var preferencesRevision = 0
    @AppStorage(TrainingLog.versionKey) private var logVersion = 0
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEditing: Bool

    @State private var requestText = ""
    @State private var result: CoachResult?

    private struct CoachResult {
        let request: CoachRequest
        let plan: CoachPlan
    }

    private let examples = [
        "I'm a 14-year-old winger. I have 30 minutes, one ball and four cones. I want to improve my dribbling and weak foot.",
        "60 minutes as a goalkeeper with gloves and a partner. Focus on handling and reactions.",
        "20 minutes in a small indoor space. First touch and close control.",
        "I'm a striker, 45 minutes, a wall and a goal. Finishing and passing.",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    intro
                    requestBox
                    exampleList
                    buildButton

                    if let result {
                        resultView(result)
                    }
                }
                .padding()
            }
            .background(Color.soccerBackground)
            .foregroundStyle(Color.soccerText)
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - Input

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Your personal session builder", systemImage: "sparkles")
                .font(.title3)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerAccent)
            Text("Tell me your age, position, time, equipment, and goals. I'll build a session from the drills in your library and explain every pick.")
                .font(.subheadline)
                .foregroundStyle(Color.soccerText.opacity(0.7))
        }
    }

    private var requestBox: some View {
        ZStack(alignment: .topLeading) {
            if requestText.isEmpty {
                Text("Describe your session…")
                    .font(.body)
                    .foregroundStyle(Color.soccerText.opacity(0.35))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $requestText)
                .focused($isEditing)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 120)
        }
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var exampleList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try an example")
                .font(.caption)
                .fontWeight(.black)
                .foregroundStyle(Color.soccerText.opacity(0.55))
            ForEach(examples, id: \.self) { example in
                Button {
                    Haptics.tap()
                    requestText = example
                } label: {
                    Text(example)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var buildButton: some View {
        Button {
            isEditing = false
            build()
        } label: {
            Label(
                requestText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Build from my profile"
                    : "Build my session",
                systemImage: "wand.and.stars"
            )
            .font(.headline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.soccerAccent, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
            .shadow(color: Color.soccerAccent.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Result

    @ViewBuilder
    private func resultView(_ result: CoachResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            understood(result.request)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.plan.title)
                    .font(.title2)
                    .fontWeight(.heavy)
                Text("\(result.plan.totalMinutes) min · \(result.plan.drills.count) drills · \(result.plan.focus.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundStyle(Color.soccerText.opacity(0.65))
            }

            ForEach(Array(result.plan.notes.enumerated()), id: \.offset) { _, note in
                Label(note, systemImage: "info.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.soccerText.opacity(0.8))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.soccerGold.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 10) {
                planRow(role: "Warm-Up", name: CoachPlanner.warmUpName, reason: "Get the body moving before the ball work.")
                ForEach(Array(result.plan.drills.enumerated()), id: \.element.id) { index, drill in
                    planRow(
                        role: "Drill \(index + 1)",
                        name: drill.name,
                        reason: result.plan.reasons[drill.name] ?? ""
                    )
                }
                planRow(role: "Cool-Down", name: CoachPlanner.coolDownName, reason: "Bring your heart rate down and stretch.")
            }

            NavigationLink {
                SessionRunnerView(session: result.plan.session, totalPoints: $totalPoints)
            } label: {
                Label("Start Session", systemImage: "play.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.soccerAccent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .padding(18)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    /// How the coach read the request, so the player can see what it understood.
    private func understood(_ request: CoachRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("I understood")
                .font(.caption)
                .fontWeight(.black)
                .foregroundStyle(Color.soccerText.opacity(0.55))
            FlowTags(tags: understoodTags(request))
        }
    }

    private func understoodTags(_ request: CoachRequest) -> [(String, String)] {
        var tags: [(String, String)] = [("\(request.minutes) min", "clock.fill")]
        if let age = request.age {
            tags.append(("Age \(age)", "person.fill"))
        }
        if let position = request.position {
            tags.append((position, "figure.soccer"))
        }
        tags.append((request.level.rawValue, "gauge.with.dots.needle.50percent"))
        for skill in request.skills.prefix(3) {
            tags.append((skill, DrillPresentation.icon(for: skill)))
        }
        if request.weakFoot {
            tags.append(("Weak foot", "figure.walk"))
        }
        if request.indoorOnly {
            tags.append(("Indoor", "house.fill"))
        }
        let labels = request.equipment.labels
        tags.append((labels.isEmpty ? "Ball only" : "Ball + " + labels.joined(separator: ", "), "shippingbox.fill"))
        return tags
    }

    private func planRow(role: String, name: String, reason: String) -> some View {
        let info = DrillCatalog.info(for: name)
        return HStack(alignment: .top, spacing: 12) {
            DrillArtwork(drillName: name, height: 56)
                .frame(width: 56)
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(role.uppercased())
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundStyle(Color.soccerAccent)
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("\(info.minutes) min" + (reason.isEmpty ? "" : " · \(reason)"))
                    .font(.caption)
                    .foregroundStyle(Color.soccerText.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.soccerBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Actions

    private func build() {
        let preferences = PlayerPreferences.load()
        let text = requestText.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = text.isEmpty
            ? CoachPlanner.defaultRequest(for: preferences)
            : CoachPlanner.request(from: text, preferences: preferences)
        let plan = CoachPlanner.plan(
            for: request,
            history: TrainingLog.entries(),
            favorites: FavoriteDrills.set(from: favoritesText)
        )
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            result = CoachResult(request: request, plan: plan)
        }
    }
}

/// Wrapping tags with an icon each, used to show how the coach read a request.
private struct FlowTags: View {
    let tags: [(String, String)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8, alignment: .leading)], alignment: .leading, spacing: 8) {
            ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                Label(tag.0, systemImage: tag.1)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.soccerBackground, in: Capsule())
                    .overlay {
                        Capsule().stroke(Color.soccerText.opacity(0.08), lineWidth: 1)
                    }
            }
        }
    }
}

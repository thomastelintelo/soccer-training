// SessionView.swift
// A complete workout for one category or session template: its total duration,
// difficulty, and the skills it develops, with the warm-up, drills, and cool-down
// laid out in order. Start Session runs the whole thing with progress tracking.

import SwiftUI

struct SessionView: View {
    let title: String
    let category: String
    let drills: [Drill]
    var fixedDrillNames: [String]? = nil
    @Binding var totalPoints: Int
    @State private var steps: [SessionStep] = []

    private var drillSteps: [SessionStep] {
        steps.filter { $0.role.hasPrefix("Drill") }
    }

    private var totalMinutes: Int {
        steps.reduce(0) { $0 + DrillTimerView.duration(for: $1.drillName) / 60 }
    }

    /// Average of the drills' levels, so a session of mostly intermediate drills reads as Intermediate.
    private var difficultyLabel: String {
        let ranks = drillSteps.map { DrillCatalog.info(for: $0.drillName).level.rank }
        guard !ranks.isEmpty else { return DrillLevel.beginner.rawValue }
        let average = Double(ranks.reduce(0, +)) / Double(ranks.count)
        switch average {
        case ..<0.67: return DrillLevel.beginner.rawValue
        case ..<1.34: return DrillLevel.intermediate.rawValue
        default: return DrillLevel.advanced.rawValue
        }
    }

    private var skillsLabel: String {
        var seen: [String] = []
        for step in drillSteps {
            let skill = DrillCatalog.skill(for: step.drillName)
            if !seen.contains(skill) { seen.append(skill) }
        }
        return seen.joined(separator: " • ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summary

                NavigationLink {
                    SessionRunnerView(
                        session: ActiveSession(title: title, steps: steps),
                        totalPoints: $totalPoints
                    )
                } label: {
                    Label("Start Session", systemImage: "play.fill")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.soccerAccent, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                        .shadow(color: Color.soccerAccent.opacity(0.3), radius: 8, y: 4)
                }
                .disabled(steps.isEmpty)

                if fixedDrillNames == nil {
                    Button {
                        Haptics.tap()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            steps = SessionBuilder.steps(category: category, drills: drills)
                        }
                    } label: {
                        Label("Shuffle drills", systemImage: "shuffle")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                SectionHeader(title: "The plan", subtitle: "Tap any drill to read its full instructions.")

                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    NavigationLink {
                        DrillDetailView(drillName: step.drillName, totalPoints: $totalPoints)
                    } label: {
                        stepRow(step, number: index + 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color.soccerBackground)
        .foregroundStyle(Color.soccerText)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if steps.isEmpty {
                if let fixedDrillNames {
                    steps = SessionBuilder.steps(fixedDrillNames: fixedDrillNames)
                } else {
                    steps = SessionBuilder.steps(category: category, drills: drills)
                }
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(DrillPresentation.focus(for: category))
                .font(.subheadline)
                .foregroundStyle(Color.soccerText.opacity(0.65))

            HStack(spacing: 10) {
                summaryTile(value: "\(totalMinutes) min", title: "TOTAL", icon: "timer")
                summaryTile(value: "\(drillSteps.count)", title: "DRILLS", icon: "figure.soccer")
                summaryTile(value: difficultyLabel, title: "DIFFICULTY", icon: "gauge.with.dots.needle.50percent")
            }

            Label(skillsLabel, systemImage: "scope")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color.soccerText.opacity(0.75))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func summaryTile(value: String, title: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(Color.soccerAccent)
            Text(value)
                .font(.subheadline)
                .fontWeight(.heavy)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .fontWeight(.black)
                .foregroundStyle(Color.soccerText.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.soccerBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    private func stepRow(_ step: SessionStep, number: Int) -> some View {
        HStack(spacing: 14) {
            DrillArtwork(drillName: step.drillName, height: 56)
                .frame(width: 56)
                .clipShape(.rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(step.role.uppercased())
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundStyle(Color.soccerAccent)
                Text(step.drillName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                Text("\(DrillTimerView.duration(for: step.drillName) / 60) min · \(DrillCatalog.skill(for: step.drillName))")
                    .font(.caption)
                    .foregroundStyle(Color.soccerText.opacity(0.6))
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.soccerText.opacity(0.35))
        }
        .padding(12)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

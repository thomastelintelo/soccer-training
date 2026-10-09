// ProgressDashboardView.swift
// Progress dashboard: weekly improvement, accuracy, completed drills,
// personal bests, and player-set weekly goals.

import Charts
import SwiftUI

struct ProgressDashboardLink: View {
    var body: some View {
        NavigationLink {
            ProgressDashboardView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.soccerAccent, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress Dashboard").font(.title3.bold())
                    Text("Weekly gains, accuracy, goals and bests")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Color.soccerAccent)
            }
            .padding()
            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

struct ProgressDashboardView: View {
    @AppStorage("weeklyLog") private var weeklyLogText = ""
    @AppStorage("totalSessions") private var totalSessions = 0
    @AppStorage("totalGoals") private var totalGoals = 0
    @AppStorage("totalShots") private var totalShots = 0
    @AppStorage("totalPasses") private var totalPasses = 0
    @AppStorage("totalControls") private var totalControls = 0
    @AppStorage("totalDribblingAttempts") private var totalDribblingAttempts = 0
    @AppStorage("soccerTestBests") private var testBestsText = ""
    @AppStorage("drillBests") private var drillBestsText = ""
    @AppStorage("personalBestCount") private var personalBestCount = 0
    @AppStorage("goalDrills") private var goalDrills = 10
    @AppStorage("goalMinutes") private var goalMinutes = 120
    @AppStorage("goalAccuracy") private var goalAccuracy = 70

    private var log: [String: WeekRecord] { WeeklyLog.decode(weeklyLogText) }
    private var thisWeek: WeekRecord { log[WeeklyLog.key(weeksAgo: 0)] ?? WeekRecord() }
    private var lastWeek: WeekRecord { log[WeeklyLog.key(weeksAgo: 1)] ?? WeekRecord() }
    private var testBests: [String: Double] { SoccerTestResults.decode(testBestsText) }

    private var recentWeeks: [(label: String, record: WeekRecord)] {
        (0..<6).reversed().map { ago in
            let key = WeeklyLog.key(weeksAgo: ago)
            return (ago == 0 ? "Now" : "-\(ago)w", log[key] ?? WeekRecord())
        }
    }

    private var lifetimeAccuracy: Double? {
        let log = log.values
        let attempts = log.reduce(0) { $0 + $1.attempts }
        guard attempts > 0 else { return nil }
        return min(1, Double(log.reduce(0) { $0 + $1.successes }) / Double(attempts))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                thisWeekCard
                goalsCard
                trendCard
                accuracyCard
                bestsCard
            }
            .padding()
        }
        .background(SoccerBackgroundView())
        .foregroundStyle(Color.soccerText)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var thisWeekCard: some View {
        card("This Week vs Last Week", systemImage: "arrow.up.right") {
            HStack(spacing: 10) {
                comparison("Drills", now: thisWeek.drills, before: lastWeek.drills, unit: "")
                comparison("Minutes", now: thisWeek.minutes, before: lastWeek.minutes, unit: "m")
                comparison("XP", now: thisWeek.xp, before: lastWeek.xp, unit: "")
            }
            if let now = thisWeek.accuracy {
                let delta = lastWeek.accuracy.map { Int((now - $0) * 100) }
                Text("Accuracy \(Int(now * 100))%" + (delta.map { " (\($0 >= 0 ? "+" : "")\($0) pts vs last week)" } ?? ""))
                    .font(.subheadline)
                    .foregroundStyle(Color.soccerAccent)
            }
        }
    }

    private var goalsCard: some View {
        card("Weekly Goals", systemImage: "flag.checkered") {
            goalRow("Complete drills", value: thisWeek.drills, goal: $goalDrills, step: 1, range: 1...100, unit: "")
            goalRow("Train minutes", value: thisWeek.minutes, goal: $goalMinutes, step: 10, range: 10...1_000, unit: "m")
            goalRow(
                "Accuracy",
                value: thisWeek.accuracy.map { Int($0 * 100) } ?? 0,
                goal: $goalAccuracy, step: 5, range: 5...100, unit: "%"
            )
        }
    }

    private var trendCard: some View {
        card("Last 6 Weeks", systemImage: "chart.bar.fill") {
            Chart {
                ForEach(recentWeeks, id: \.label) { week in
                    BarMark(x: .value("Week", week.label), y: .value("Minutes", week.record.minutes))
                        .foregroundStyle(Color.soccerAccent)
                }
            }
            .frame(height: 140)
            Text("Training minutes per week")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var accuracyCard: some View {
        card("Accuracy & Completed Drills", systemImage: "scope") {
            HStack(spacing: 10) {
                stat("\(totalSessions)", "Drills done")
                stat(lifetimeAccuracy.map { "\(Int($0 * 100))%" } ?? "--", "Accuracy")
            }
            HStack(spacing: 10) {
                stat("\(totalGoals)/\(totalShots)", "Goals/Shots")
                stat("\(totalPasses)", "Passes")
                stat("\(totalControls)", "Controls")
            }
        }
    }

    private var bestsCard: some View {
        let tests = SoccerTestCatalog.all.filter { testBests[$0.id] != nil }
        let drills = DrillBests.decode(drillBestsText).filter { $0.value > 0 }.sorted { $0.value > $1.value }.prefix(5)

        return card("Personal Bests", systemImage: "trophy.fill") {
            Text("\(personalBestCount) records broken")
                .font(.subheadline)
                .foregroundStyle(Color.soccerAccent)
            if tests.isEmpty && drills.isEmpty {
                Text("Complete a Soccer Test or drill to set a personal best.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(tests) { test in
                if let best = testBests[test.id] {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(test.name).fontWeight(.bold)
                            Spacer()
                            Text(SoccerTestResults.formatted(best, unit: test.unit))
                                .foregroundStyle(Color.soccerAccent)
                        }
                        .font(.subheadline)
                        ProgressView(value: TestProgression.score(test, best: best))
                            .tint(Color.soccerAccent)
                    }
                }
            }
            ForEach(Array(drills), id: \.key) { name, best in
                HStack {
                    Text(name).fontWeight(.bold)
                    Spacer()
                    Text("\(best) best").foregroundStyle(Color.soccerAccent)
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Pieces

    private func card<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.title3)
                .fontWeight(.heavy)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.soccerSurface)
        .clipShape(.rect(cornerRadius: 16))
    }

    private func comparison(_ title: String, now: Int, before: Int, unit: String) -> some View {
        let delta = now - before
        return VStack(spacing: 4) {
            Text("\(now)\(unit)")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerAccent)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Label("\(abs(delta))\(unit)", systemImage: delta >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(delta >= 0 ? Color.green : Color.red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.soccerSurfaceStrong, in: RoundedRectangle(cornerRadius: 12))
    }

    private func stat(_ value: String, _ title: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).fontWeight(.heavy).foregroundStyle(Color.soccerAccent)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.soccerSurfaceStrong, in: RoundedRectangle(cornerRadius: 12))
    }

    private func goalRow(
        _ title: String,
        value: Int,
        goal: Binding<Int>,
        step: Int,
        range: ClosedRange<Int>,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).fontWeight(.bold)
                Spacer()
                Text("\(value)\(unit) / \(goal.wrappedValue)\(unit)")
                    .foregroundStyle(value >= goal.wrappedValue ? Color.green : Color.soccerAccent)
                    .fontWeight(.bold)
                Stepper("", value: goal, in: range, step: step)
                    .labelsHidden()
                    .fixedSize()
            }
            .font(.subheadline)
            ProgressView(value: min(1, Double(value) / Double(max(1, goal.wrappedValue))))
                .tint(value >= goal.wrappedValue ? Color.green : Color.soccerAccent)
        }
    }
}

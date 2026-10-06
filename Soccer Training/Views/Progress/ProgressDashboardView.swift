// ProgressDashboardView.swift
// The Progress tab: level and XP, sessions and drills completed, total training
// time, streak, a weekly activity chart, this week's challenge, personal goals,
// skills trained, and badges.

import Charts
import SwiftUI

struct ProgressDashboardView: View {
    @AppStorage("playerXP") private var playerXP = 0
    @AppStorage("totalSessions") private var drillsCompleted = 0
    @AppStorage("sessionsCompleted") private var sessionsCompleted = 0
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0
    @AppStorage("trainingStreak") private var trainingStreak = 0
    @AppStorage("lastTrainingDate") private var lastTrainingDate = ""
    @AppStorage("categoryXP") private var categoryXPText = ""
    @AppStorage("categoryMinutes") private var categoryMinutesText = ""
    @AppStorage("totalGoals") private var totalGoals = 0
    @AppStorage("totalPoints") private var totalPoints = 0
    /// Read so the dashboard redraws when preferences or the log change.
    @AppStorage(PlayerPrefKey.revision) private var preferencesRevision = 0
    @AppStorage(TrainingLog.versionKey) private var logVersion = 0

    private var progress: PlayerProgress {
        PlayerProgress(xp: playerXP)
    }

    private var preferences: PlayerPreferences {
        PlayerPreferences.load()
    }

    private var entries: [TrainingEntry] {
        TrainingLog.entries()
    }

    private var categories: CategoryProgress {
        CategoryProgress(xpText: categoryXPText, minutesText: categoryMinutesText)
    }

    private var streak: Int {
        TrainingStreak.current(stored: trainingStreak, lastDay: lastTrainingDate)
    }

    private var thisWeek: [TrainingEntry] {
        TrainingLog.thisWeek(entries)
    }

    private var weekMinutes: Int {
        thisWeek.reduce(0) { $0 + $1.minutes }
    }

    private var weekTrainingDays: Int {
        TrainingLog.trainedDays(thisWeek).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                statGrid
                weeklyChart
                challengeCard
                goalsSection
                skillsSection
                badgesSection
            }
            .padding()
        }
        .background(Color.soccerBackground)
        .foregroundStyle(Color.soccerText)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: progress.progressToNextLevel, lineWidth: 10)
                VStack(spacing: 0) {
                    Text("LVL")
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(progress.level)")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 96, height: 96)

            VStack(alignment: .leading, spacing: 6) {
                Text(progress.levelTitle)
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundStyle(.white)
                Text("\(progress.xpUntilNextLevel) XP to level \(progress.level + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                Label("\(totalPoints.formatted()) points", systemImage: "star.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.soccerAccentLight, Color.soccerAccent], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }

    // MARK: - Totals

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statTile(value: "\(sessionsCompleted)", title: "Sessions completed", icon: "list.bullet.clipboard.fill")
            statTile(value: "\(drillsCompleted)", title: "Drills completed", icon: "figure.soccer")
            statTile(value: formattedDuration(totalTrainingMinutes), title: "Training time", icon: "timer")
            statTile(value: streak > 0 ? "\(streak) days" : "Not yet", title: "Current streak", icon: "flame.fill", tint: .orange)
        }
    }

    private func statTile(value: String, title: String, icon: String, tint: Color = .soccerAccent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.title2)
                .fontWeight(.heavy)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.soccerText.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func formattedDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) m"
    }

    // MARK: - Weekly activity

    private var weeklyChart: some View {
        let days = TrainingLog.dailyMinutes(entries, days: 7)
        let target = preferences.trainingMinutes

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "This week", subtitle: "\(weekMinutes) min across \(weekTrainingDays) of \(preferences.trainingDays) planned days")

            Chart {
                ForEach(days, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day, unit: .day),
                        y: .value("Minutes", item.minutes)
                    )
                    .foregroundStyle(item.minutes > 0 ? Color.soccerAccent.gradient : Color.soccerText.opacity(0.1).gradient)
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Target", target))
                    .foregroundStyle(Color.soccerGold)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Target \(target) min")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.soccerText.opacity(0.7))
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: days.map(\.minutes))
        }
        .padding(18)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Challenge and goals

    private var challengeCard: some View {
        let challenge = WeeklyChallenge.current(entries: entries)
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: challenge.systemImage)
                .font(.title2)
                .foregroundStyle(challenge.isComplete ? Color.soccerGold : Color.soccerAccent)
                .frame(width: 44, height: 44)
                .background(Color.soccerBackground, in: Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("WEEKLY CHALLENGE")
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundStyle(Color.soccerText.opacity(0.55))
                    Spacer()
                    if challenge.isComplete {
                        Label("Complete", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.soccerAccent)
                    }
                }
                Text(challenge.title)
                    .font(.headline)
                    .fontWeight(.heavy)
                Text(challenge.detail)
                    .font(.caption)
                    .foregroundStyle(Color.soccerText.opacity(0.65))
                LinearProgressBar(fraction: challenge.fraction, tint: challenge.isComplete ? .soccerGold : .soccerAccent)
                Text("\(min(challenge.progress, challenge.target)) of \(challenge.target)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.soccerText.opacity(0.6))
            }
        }
        .padding(18)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var goalsSection: some View {
        let prefs = preferences
        let weeklyTarget = prefs.trainingMinutes * prefs.trainingDays
        let skillGoals = prefs.goals.prefix(3).map { skill -> (title: String, fraction: Double, detail: String) in
            let minutes = thisWeek.filter { $0.skill == skill }.reduce(0) { $0 + $1.minutes }
            let target = 60
            return (
                title: "Train \(skill)",
                fraction: min(Double(minutes) / Double(target), 1),
                detail: "\(minutes) of \(target) min this week"
            )
        }

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Personal goals", subtitle: "Set in your preferences")

            goalRow(
                title: "Train \(prefs.trainingDays) days this week",
                fraction: Double(weekTrainingDays) / Double(max(prefs.trainingDays, 1)),
                detail: "\(weekTrainingDays) of \(prefs.trainingDays) days"
            )
            goalRow(
                title: "Reach \(weeklyTarget) minutes",
                fraction: Double(weekMinutes) / Double(max(weeklyTarget, 1)),
                detail: "\(weekMinutes) of \(weeklyTarget) min"
            )
            ForEach(Array(skillGoals.enumerated()), id: \.offset) { _, goal in
                goalRow(title: goal.title, fraction: goal.fraction, detail: goal.detail)
            }

            if prefs.goals.isEmpty {
                Text("Add skill goals in Profile to track them here.")
                    .font(.caption)
                    .foregroundStyle(Color.soccerText.opacity(0.6))
            }
        }
        .padding(18)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func goalRow(title: String, fraction: Double, detail: String) -> some View {
        let done = fraction >= 1
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: done ? "checkmark.circle.fill" : "circle.dashed")
                    .foregroundStyle(done ? Color.soccerAccent : Color.soccerText.opacity(0.35))
            }
            LinearProgressBar(fraction: fraction, tint: done ? .soccerAccent : .soccerAccentLight)
            Text(detail)
                .font(.caption)
                .foregroundStyle(Color.soccerText.opacity(0.6))
        }
    }

    // MARK: - Skills

    private var skillsSection: some View {
        let rows = categories.minutesByCategory
        let maxMinutes = max(rows.first?.minutes ?? 1, 1)

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Skills trained", subtitle: "Minutes and XP by skill")

            if rows.isEmpty {
                Text("Complete a drill to start building skill data.")
                    .font(.subheadline)
                    .foregroundStyle(Color.soccerText.opacity(0.6))
            }

            ForEach(rows, id: \.skill) { row in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(row.skill, systemImage: DrillPresentation.icon(for: row.skill))
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(row.minutes) min · \(row.xp) XP")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.soccerText.opacity(0.6))
                    }
                    LinearProgressBar(fraction: Double(row.minutes) / Double(maxMinutes), tint: .soccerAccent)
                }
            }
        }
        .padding(18)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Badges

    private var badgesSection: some View {
        let badges = Achievement.catalog(
            totalGoals: totalGoals,
            totalSessions: drillsCompleted,
            sessionsCompleted: sessionsCompleted,
            trainingStreak: streak,
            totalPoints: totalPoints,
            level: progress.level,
            soccerIQXP: categories.xp(for: "Soccer IQ")
        )
        let unlocked = badges.filter(\.isUnlocked).count

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Badges", subtitle: "\(unlocked) of \(badges.count) unlocked")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(badges) { badge in
                    HStack(spacing: 12) {
                        Image(systemName: badge.isUnlocked ? badge.systemImage : "lock.fill")
                            .font(.title3)
                            .foregroundStyle(badge.isUnlocked ? Color.soccerGold : Color.soccerText.opacity(0.35))
                            .frame(width: 40, height: 40)
                            .background(Color.soccerBackground, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(badge.title)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            Text(badge.detail)
                                .font(.caption2)
                                .foregroundStyle(Color.soccerText.opacity(0.6))
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.soccerBackground, in: RoundedRectangle(cornerRadius: 14))
                    .opacity(badge.isUnlocked ? 1 : 0.6)
                }
            }
        }
        .padding(18)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 20))
    }
}

private extension CategoryProgress {
    /// Skills the player has trained, most minutes first.
    var minutesByCategory: [(skill: String, minutes: Int, xp: Int)] {
        minutes.keys
            .map { (skill: $0, minutes: minutes(for: $0), xp: xp(for: $0)) }
            .filter { $0.minutes > 0 }
            .sorted { $0.minutes > $1.minutes }
    }
}

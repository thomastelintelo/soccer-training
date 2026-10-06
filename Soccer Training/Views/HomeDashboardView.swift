// HomeDashboardView.swift
// The Home tab: today's training plan, daily challenge, and quick stats.

import SwiftUI

struct HomeDashboardView: View {
    let username: String
    let position: String
    let bestSkill: String
    let schedule: [ScheduleDay]
    @Binding var totalPoints: Int
    @AppStorage("completedWeeklyTasks") private var completedWeeklyTasks = ""
    @AppStorage("completedWeeklyDays") private var completedWeeklyDays = ""
    @AppStorage("weeklyProgressStart") private var weeklyProgressStart = 0.0
    @AppStorage("weeklyDrillSubstitutions") private var substitutionText = ""
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0
    @AppStorage("trainingStreak") private var trainingStreak = 0
    @AppStorage("lastTrainingDate") private var lastTrainingDate = ""
    @State private var hasAppeared = false

    private var trainedToday: Bool {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        return lastTrainingDate == formatter.string(from: Date())
    }

    private var isStreakAtRisk: Bool {
        trainingStreak > 0 && !trainedToday
    }

    private var completedTaskIDs: Set<String> {
        Set(completedWeeklyTasks.split(separator: "|").map(String.init))
    }

    private var substitutions: [String: String] {
        Dictionary(
            uniqueKeysWithValues: substitutionText.split(separator: "|").compactMap { entry in
                let parts = entry.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                return (String(parts[0]), String(parts[1]))
            }
        )
    }

    private var todayName: String? {
        switch Calendar.current.component(.weekday, from: Date()) {
        case 2: "Monday"
        case 3: "Tuesday"
        case 4: "Wednesday"
        case 5: "Thursday"
        case 6: "Friday"
        case 7: "Saturday"
        case 1: "Sunday"
        default: nil
        }
    }

    private let dailyChallengeChoices = [
        "Ball Mastery", "Wall Passing", "Cone Weave", "Juggling",
        "Toe Tap Challenge", "Quick Shot", "Tight Space Turns",
        "Scan Before Touch", "Snap Shot Finish", "First Touch Gates",
        "Jockeying", "Quick Feet",
    ]

    /// 3 daily challenges, each a different, deterministically-picked drill so
    /// every player sees the same 3 for a given date. The offsets spread the
    /// picks across the pool so they don't cluster next to each other.
    private var dailyChallengeDrills: [Drill] {
        let dayNumber = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        let count = dailyChallengeChoices.count
        return [0, 4, 8].map { offset in
            Drill(name: dailyChallengeChoices[(dayNumber + offset) % count])
        }
    }

    private func dailyChallengeID(index: Int) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        return "daily-\(index)-\(formatter.string(from: Date()))"
    }

    private func isDailyChallengeCompleted(index: Int) -> Bool {
        completedTaskIDs.contains(dailyChallengeID(index: index))
    }

    private func displayedDrillName(for item: ScheduleItem, taskID: String) -> String {
        substitutions[taskID] ?? item.drillName
    }

    private func drillThumbnail(drillName: String, size: CGFloat) -> some View {
        let category = DrillPresentation.category(for: drillName)
        return Image(DrillPresentation.imageName(for: drillName, category: category))
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipped()
            .overlay {
                // Only a handful of stock photos ship, so every drill tints its
                // shared photo with its own stable hue, same as the Drills tab.
                Color(hue: DrillPresentation.photoHue(for: drillName), saturation: 0.6, brightness: 0.9)
                    .opacity(0.4)
                    .blendMode(.hue)
            }
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.soccerText.opacity(0.1), lineWidth: 1)
            }
    }

    private func dashboardStat(
        title: LocalizedStringKey,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.soccerAccent)
            Text(value)
                .font(.headline)
                .fontWeight(.heavy)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.soccerText.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func substituteDrill(for item: ScheduleItem, taskID: String) {
        let replacement: String

        switch item.focus {
        case "Shooting":
            replacement = "Practice Shooting"
        case "Dribbling":
            replacement = "Inside-Outside Touches"
        case "Passing":
            replacement = "Wall Passing"
        case "Control":
            replacement = "Juggling"
        case "Goalkeeping":
            replacement = "Goalkeeper Footwork"
        case "Defense":
            replacement = "Jockeying"
        default:
            replacement = "Running"
        }

        var updatedSubstitutions = substitutions
        updatedSubstitutions[taskID] = replacement == item.drillName ? "Running" : replacement
        substitutionText = updatedSubstitutions
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: "|")
    }

    var body: some View {
        ZStack {
            Color.soccerBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("PRO TRAINING", systemImage: "figure.soccer")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundStyle(.white)

                            Spacer()

                            Text("NEW")
                                .font(.caption)
                                .fontWeight(.black)
                                .foregroundStyle(Color.soccerAccent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white, in: Capsule())
                        }

                        Text("Train with purpose.")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Longer sessions, coaching tips, equipment lists, and bigger rewards are ready in the Drills tab.")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.85))

                        HStack(spacing: 10) {
                            Label("\(totalTrainingMinutes) min trained", systemImage: "timer")
                            Label("More points", systemImage: "star.fill")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color.soccerAccentLight, Color.soccerAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 24)
                    )

                    Text("Points: \(totalPoints)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.soccerAccent)
                        .clipShape(.capsule)

                    Text("Welcome, \(username)!")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)

                    Text("\(position) • Best at \(bestSkill)")
                        .font(.headline)
                        .foregroundStyle(Color.soccerText.opacity(0.7))

                    HStack(spacing: 10) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(isStreakAtRisk ? Color.gray : Color.orange)
                            .symbolEffect(.bounce, value: trainingStreak)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(trainingStreak > 0 ? "\(trainingStreak)-day streak" : "Start your streak today")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(isStreakAtRisk ? "Train today to keep it alive" : "Train daily to keep it growing")
                                .font(.caption)
                                .foregroundStyle(Color.soccerText.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isStreakAtRisk ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 2)
                    }

                    HStack(spacing: 12) {
                        dashboardStat(
                            title: "Points",
                            value: totalPoints.formatted(),
                            systemImage: "star.fill"
                        )
                        dashboardStat(
                            title: "Minutes",
                            value: totalTrainingMinutes.formatted(),
                            systemImage: "timer"
                        )
                        dashboardStat(
                            title: "Completed",
                            value: completedTaskIDs.count.formatted(),
                            systemImage: "checkmark.circle.fill"
                        )
                    }

                    NavigationLink {
                        ProfileView(
                            username: username,
                            position: position,
                            bestSkill: bestSkill,
                            totalPoints: $totalPoints
                        )
                    } label: {
                        Label("View Player Profile", systemImage: "person.crop.circle.fill")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Daily Challenges", systemImage: "calendar.badge.checkmark")
                                .font(.title2)
                                .fontWeight(.heavy)
                            Spacer()
                            let doneCount = dailyChallengeDrills.indices.filter { isDailyChallengeCompleted(index: $0) }.count
                            Text("\(doneCount)/\(dailyChallengeDrills.count) DONE")
                                .font(.caption)
                                .fontWeight(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.soccerGold, in: Capsule())
                                .foregroundStyle(Color.soccerText)
                        }

                        Text("Each challenge earns the normal drill reward plus 25 bonus points. A new set appears every day.")
                            .font(.subheadline)
                            .foregroundStyle(Color.soccerText.opacity(0.65))

                        ForEach(Array(dailyChallengeDrills.enumerated()), id: \.offset) { index, drill in
                            let completed = isDailyChallengeCompleted(index: index)

                            HStack(spacing: 12) {
                                drillThumbnail(drillName: drill.name, size: 48)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(drill.name)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text(completed ? "Completed" : "+25 bonus points")
                                        .font(.caption)
                                        .foregroundStyle(Color.soccerText.opacity(0.6))
                                }

                                Spacer()

                                NavigationLink {
                                    DrillTimerView(
                                        drill: drill,
                                        totalPoints: $totalPoints,
                                        weeklyTaskID: dailyChallengeID(index: index),
                                        weeklyDay: dailyChallengeID(index: index)
                                    )
                                } label: {
                                    Image(systemName: completed ? "checkmark.circle.fill" : "play.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(Color.soccerAccent)
                                        .symbolEffect(.bounce, value: completed)
                                }
                                .disabled(completed)
                            }
                            .padding(10)
                            .background(Color.soccerSurfaceStrong, in: RoundedRectangle(cornerRadius: 12))
                            .animation(.spring(response: 0.45, dampingFraction: 0.65), value: completed)
                        }
                    }
                    .padding()
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Today's training plan. Complete drills to build XP, stats, and training time.")
                            .font(.subheadline)
                            .foregroundStyle(Color.soccerText.opacity(0.6))

                        ForEach(schedule.filter { $0.day == todayName }) { scheduleDay in
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(scheduleDay.drills) { item in
                                    let taskID = "\(scheduleDay.day)-\(item.id)"
                                    let isToday = scheduleDay.day == todayName
                                    let drillName = displayedDrillName(for: item, taskID: taskID)

                                    HStack(spacing: 8) {
                                        NavigationLink {
                                            DrillTimerView(
                                                drill: Drill(name: drillName),
                                                totalPoints: $totalPoints,
                                                weeklyTaskID: taskID,
                                                weeklyDay: scheduleDay.day
                                            )
                                        } label: {
                                            HStack {
                                                drillThumbnail(drillName: drillName, size: 48)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(drillName)
                                                        .font(.headline)
                                                        .fontWeight(.bold)
                                                    Text(isToday ? "Focus: \(item.focus)" : "Unlocks on \(scheduleDay.day)")
                                                        .font(.subheadline)
                                                }

                                                Spacer()

                                                Image(
                                                    systemName: completedTaskIDs.contains(taskID)
                                                        ? "checkmark.circle.fill"
                                                        : isToday ? "chevron.right" : "lock.fill"
                                                )
                                                .foregroundStyle(
                                                    completedTaskIDs.contains(taskID)
                                                        ? Color.soccerAccent
                                                        : (isToday ? .white : Color.soccerText)
                                                )
                                            }
                                            .contentShape(.rect)
                                        }
                                        .disabled(!isToday)
                                        .opacity(hasAppeared ? 1 : 0)
                                        .offset(x: hasAppeared ? 0 : -16)
                                        .animation(
                                            .spring(response: 0.4, dampingFraction: 0.7).delay(Double(item.id % 10) * 0.04),
                                            value: hasAppeared
                                        )

                                        Menu {
                                            Button {
                                                substituteDrill(for: item, taskID: taskID)
                                            } label: {
                                                Label("I don't have the equipment", systemImage: "shippingbox")
                                            }

                                            Button {
                                                substituteDrill(for: item, taskID: taskID)
                                            } label: {
                                                Label("I don't have a training partner", systemImage: "person.slash")
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis.circle.fill")
                                                .font(.title2)
                                                .padding(8)
                                        }
                                        .disabled(!isToday || completedTaskIDs.contains(taskID))
                                        .accessibilityLabel("More options for \(drillName)")
                                    }
                                    .foregroundStyle(isToday ? .white : Color.soccerText)
                                    .padding()
                                    .background(isToday ? Color.soccerAccent : Color.soccerSurfaceStrong)
                                    .clipShape(.rect(cornerRadius: 14))
                                    .opacity(isToday ? 1 : 0.8)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding()
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 18))

                }
                .padding()
            }
        }
        .foregroundStyle(Color.soccerText)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            resetWeeklyProgressIfNeeded()
            hasAppeared = true
        }
    }

    private func resetWeeklyProgressIfNeeded() {
        let now = Date().timeIntervalSince1970
        let week: TimeInterval = 7 * 24 * 60 * 60

        if weeklyProgressStart == 0 {
            weeklyProgressStart = now
        } else if now - weeklyProgressStart >= week {
            completedWeeklyTasks = ""
            completedWeeklyDays = ""
            substitutionText = ""
            weeklyProgressStart = now
        }
    }
}

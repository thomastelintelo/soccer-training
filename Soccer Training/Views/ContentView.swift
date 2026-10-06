// ContentView.swift
// The signed-in app's root tab view: Home, Drills, Train, Progress, Profile.

import SwiftUI

struct ContentView: View {
    @AppStorage("totalPoints") private var totalPoints = 0
    @AppStorage("playerUsername") private var playerUsername = ""
    @AppStorage("playerPosition") private var playerPosition = ""
    @AppStorage("playerBestSkill") private var playerBestSkill = ""

    let topics = DrillTopics.all

    private var schedule: [ScheduleDay] {
        let positionPriorities: [String]

        switch playerPosition {
        case "Goalkeeper":
            positionPriorities = ["Goalkeeping", "Control", "Passing", "Defense"]
        case "Defender":
            positionPriorities = ["Defense", "Passing", "Control", "Dribbling"]
        case "Midfielder":
            positionPriorities = ["Passing", "Control", "Dribbling", "Shooting"]
        case "Winger":
            positionPriorities = ["Dribbling", "Shooting", "Control", "Passing"]
        case "Striker":
            positionPriorities = ["Shooting", "Control", "Dribbling", "Passing"]
        default:
            positionPriorities = ["Control", "Passing", "Dribbling", "Shooting"]
        }

        let developmentSkills = positionPriorities.filter {
            playerBestSkill.isEmpty || $0 != playerBestSkill
        }
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        return days.enumerated().map { dayIndex, day in
            var dailyFocuses = (0..<4).map { offset in
                developmentSkills[(dayIndex + offset) % developmentSkills.count]
            }

            if positionPriorities.contains(playerBestSkill) && (dayIndex == 2 || dayIndex == 4) {
                dailyFocuses[2] = playerBestSkill
            }
            dailyFocuses.append("Workout")

            var drills = dailyFocuses.enumerated().map { drillIndex, focus in
                let scheduleIndex = (dayIndex * 7) + drillIndex + 1
                return ScheduleItem(
                    id: scheduleIndex,
                    focus: focus,
                    drillName: drillName(for: focus, index: scheduleIndex)
                )
            }

            // Every day's session bookends the skill work with a fixed
            // warm-up and cool-down, instead of jumping straight into drills.
            drills.insert(
                ScheduleItem(id: dayIndex * 7, focus: "Workout", drillName: "Dynamic Warm Up"),
                at: 0
            )
            drills.append(
                ScheduleItem(id: (dayIndex * 7) + 6, focus: "Workout", drillName: "Cool Down Stretch")
            )

            return ScheduleDay(day: day, drills: drills)
        }
    }

    private func drillName(for focus: String, index: Int) -> String {
        guard let drills = topics.first(where: { $0.name == focus })?.drills, !drills.isEmpty else {
            return "Juggling"
        }
        return drills[index % drills.count].name
    }

    var body: some View {
        TabView {
            NavigationStack {
                HomeDashboardView(
                    username: playerUsername,
                    position: playerPosition,
                    bestSkill: playerBestSkill,
                    schedule: schedule,
                    totalPoints: $totalPoints
                )
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                AllDrillsView(topics: topics, totalPoints: $totalPoints)
            }
            .tabItem {
                Label("Drills", systemImage: "figure.soccer")
            }

            NavigationStack {
                SessionsView(topics: topics, totalPoints: $totalPoints)
            }
            .tabItem {
                Label("Train", systemImage: "figure.run")
            }

            NavigationStack {
                ProgressDashboardView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                ProfileView(
                    username: playerUsername,
                    position: playerPosition,
                    bestSkill: playerBestSkill,
                    totalPoints: $totalPoints
                )
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(Color.soccerAccent)
        .overlay(alignment: .topTrailing) {
            // Stays on top across every tab while recording, since the
            // camera bubble shouldn't disappear just from navigating.
            CameraPreviewBubble()
        }
    }
}

#Preview {
    ContentView()
}

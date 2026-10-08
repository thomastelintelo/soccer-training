import SwiftUI

struct CoachScheduleView: View {
    @AppStorage("coachTeamCode") private var teamCode = ""
    @State private var store = TeamCloudKitStore()
    @State private var showingAddPractice = false

    private var sections: [CoachScheduleSection] {
        let schedule = store.workspace?.schedule ?? []
        return CoachWeekday.allCases.compactMap { day in
            let items = schedule
                .filter { $0.weekday == day.rawValue }
                .sorted { $0.startTime < $1.startTime }
            return items.isEmpty ? nil : CoachScheduleSection(day: day, items: items)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    CoachScheduleHeader(practiceCount: store.workspace?.schedule?.count ?? 0)

                    if teamCode.isEmpty {
                        ContentUnavailableView(
                            "Make a Team First",
                            systemImage: "calendar.badge.plus",
                            description: Text("Open the Team tab and make your team before creating a schedule.")
                        )
                    } else if store.isLoading && store.workspace == nil {
                        ProgressView("Loading schedule…")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                    } else if sections.isEmpty {
                        ContentUnavailableView(
                            "No Practices Scheduled",
                            systemImage: "calendar",
                            description: Text("Tap Add Practice to select drills and plan what the team will work on.")
                        )
                    } else {
                        ForEach(sections) { section in
                            CoachScheduleDaySection(
                                day: section.day.rawValue,
                                items: section.items,
                                onDelete: { itemID in
                                    Task { await store.removeScheduleItem(itemID) }
                                }
                            )
                        }
                    }

                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .background(SoccerBackgroundView())
            .navigationTitle("Team Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Practice", systemImage: "plus") {
                        showingAddPractice = true
                    }
                    .disabled(teamCode.isEmpty || store.workspace == nil)
                }
            }
            .task(id: teamCode) {
                if !teamCode.isEmpty { await store.loadTeam(code: teamCode) }
            }
            .refreshable {
                if !teamCode.isEmpty { await store.loadTeam(code: teamCode) }
            }
            .sheet(isPresented: $showingAddPractice) {
                AddCoachPracticeSheet(store: store)
            }
        }
        .tint(Color.soccerAccent)
    }
}

private struct CoachScheduleSection: Identifiable {
    let day: CoachWeekday
    let items: [CoachScheduleItem]
    var id: String { day.rawValue }
}

private enum CoachWeekday: String, CaseIterable, Identifiable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"

    var id: String { rawValue }
}

private struct CoachScheduleHeader: View {
    let practiceCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Weekly Training Plan", systemImage: "calendar.badge.clock")
                .font(.title2.bold())
            Text("Select drills, choose the training focus, and give every practice a clear plan.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Text("\(practiceCount) scheduled practices")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white, in: Capsule())
                .foregroundStyle(Color.soccerAccent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .foregroundStyle(.white)
        .background(Color.soccerAccent.gradient, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct CoachScheduleDaySection: View {
    let day: String
    let items: [CoachScheduleItem]
    let onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day)
                .font(.title2.bold())

            ForEach(items) { item in
                CoachScheduleRow(
                    startTime: item.startTime,
                    focus: item.focus,
                    drillName: item.drillName,
                    durationMinutes: item.durationMinutes,
                    onDelete: { onDelete(item.id) }
                )
            }
        }
    }
}

private struct CoachScheduleRow: View {
    let startTime: Date
    let focus: String
    let drillName: String
    let durationMinutes: Int
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack {
                Text(startTime, format: .dateTime.hour().minute())
                    .font(.headline)
                Text("\(durationMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 70)

            VStack(alignment: .leading, spacing: 5) {
                Text(focus.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(Color.soccerAccent)
                Text(drillName)
                    .font(.headline)
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AddCoachPracticeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let store: TeamCloudKitStore
    @State private var weekday = CoachWeekday.monday.rawValue
    @State private var startTime = Date.now
    @State private var focus = CoachDrillCategory.shooting.rawValue
    @State private var durationMinutes = 60
    @State private var selectedDrillID = CoachDrillLibrary.allDrills.first.map { "built-in-\($0.id)" } ?? ""

    private var options: [CoachDrillOption] {
        CoachDrillOption.options(customDrills: store.workspace?.customDrills ?? [])
    }

    private var selectedOption: CoachDrillOption? {
        options.first { $0.id == selectedDrillID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Practice time") {
                    Picker("Day", selection: $weekday) {
                        ForEach(CoachWeekday.allCases) { day in
                            Text(day.rawValue).tag(day.rawValue)
                        }
                    }
                    DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                    Stepper("Practice length: \(durationMinutes) minutes", value: $durationMinutes, in: 15...180, step: 5)
                }

                Section("What are you working on?") {
                    Picker("Training focus", selection: $focus) {
                        ForEach(CoachDrillCategory.allCases) { category in
                            Text(category.rawValue).tag(category.rawValue)
                        }
                    }
                }

                Section("Select a drill") {
                    NavigationLink {
                        CoachDrillOptionPicker(options: options, selection: $selectedDrillID)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedOption?.name ?? "Choose a drill")
                                .font(.headline)
                            Text(selectedOption?.category ?? "Browse the coaching library")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Practice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            guard let selectedOption else { return }
                            await store.addScheduleItem(
                                weekday: weekday,
                                startTime: startTime,
                                focus: focus,
                                drillName: selectedOption.name,
                                durationMinutes: durationMinutes
                            )
                            dismiss()
                        }
                    }
                    .disabled(selectedOption == nil)
                }
            }
        }
    }
}

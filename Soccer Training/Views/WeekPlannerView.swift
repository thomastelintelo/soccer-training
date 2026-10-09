// WeekPlannerView.swift
// Lets players build their own training week: pick what they want to
// improve, then choose up to 15 drills per day.

import SwiftUI

enum WeekPlan {
    static let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    static let maxDrillsPerDay = 15

    static func decode(_ text: String) -> [String: [String]] {
        guard let data = text.data(using: .utf8),
              let plan = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return [:] }
        return plan
    }

    static func encode(_ plan: [String: [String]]) -> String {
        guard let data = try? JSONEncoder().encode(plan),
              let text = String(data: data, encoding: .utf8)
        else { return "" }
        return text
    }

    static func taskID(day: String, drill: String) -> String {
        "\(day)-\(drill)"
    }
}

struct WeekPlannerView: View {
    let topics: [Topic]
    @AppStorage("customWeekPlan") private var planText = ""
    @AppStorage("customWeekFocus") private var focusText = ""
    @State private var selectedDay = "Monday"
    @State private var showingAutoFillPrompt = false
    @State private var autoFillCount = "5"

    private var plan: [String: [String]] { WeekPlan.decode(planText) }

    private var focusAreas: Set<String> {
        Set(focusText.split(separator: "|").map(String.init))
    }

    private var dayDrills: [String] { plan[selectedDay] ?? [] }

    private var availableDrills: [Drill] {
        topics
            .filter { focusAreas.contains($0.name) }
            .flatMap(\.drills)
            .filter { !dayDrills.contains($0.name) }
    }

    private func save(_ newPlan: [String: [String]]) {
        planText = WeekPlan.encode(newPlan)
    }

    private func toggleFocus(_ name: String) {
        var areas = focusAreas
        if areas.contains(name) { areas.remove(name) } else { areas.insert(name) }
        focusText = areas.sorted().joined(separator: "|")
    }

    private func add(_ drill: String) {
        var updated = plan
        var list = updated[selectedDay] ?? []
        guard list.count < WeekPlan.maxDrillsPerDay, !list.contains(drill) else { return }
        list.append(drill)
        updated[selectedDay] = list
        save(updated)
    }

    private func remove(at offsets: IndexSet) {
        var updated = plan
        var list = updated[selectedDay] ?? []
        list.remove(atOffsets: offsets)
        updated[selectedDay] = list
        save(updated)
    }

    private func remove(_ drill: String) {
        var updated = plan
        var list = updated[selectedDay] ?? []
        list.removeAll { $0 == drill }
        updated[selectedDay] = list
        save(updated)
    }

    /// Fills the selected day with an even mix of the chosen focus areas.
    private func autoFill(count requestedCount: Int) {
        let pools = topics.filter { focusAreas.contains($0.name) }.map { $0.drills.map(\.name).shuffled() }
        guard !pools.isEmpty else { return }
        let drillCount = min(max(requestedCount, 1), WeekPlan.maxDrillsPerDay)
        var list: [String] = []
        var round = 0
        while list.count < drillCount, pools.contains(where: { round < $0.count }) {
            for pool in pools where round < pool.count && list.count < drillCount {
                list.append(pool[round])
            }
            round += 1
        }
        var updated = plan
        updated[selectedDay] = list
        save(updated)
    }

    var body: some View {
        List {
            Section("What do you want to improve?") {
                FlowChips(items: topics.map(\.name), selected: focusAreas, onTap: toggleFocus)
            }

            Section("Day") {
                Picker("Day", selection: $selectedDay) {
                    ForEach(WeekPlan.days, id: \.self) { day in
                        Text(String(day.prefix(3))).tag(day)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                if dayDrills.isEmpty {
                    Text("No drills yet. Add some below.")
                        .foregroundStyle(.secondary)
                }
                ForEach(dayDrills, id: \.self) { name in
                    HStack {
                        Text(name)
                        Spacer()
                        Button(role: .destructive) {
                            remove(name)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Delete \(name)")
                    }
                }
                .onDelete(perform: remove)
            } header: {
                Text("\(selectedDay) · \(dayDrills.count)/\(WeekPlan.maxDrillsPerDay) drills")
            }

            if focusAreas.isEmpty {
                Section {
                    Text("Pick at least one area above to see drills.")
                        .foregroundStyle(.secondary)
                }
            } else if dayDrills.count >= WeekPlan.maxDrillsPerDay {
                Section {
                    Text("\(selectedDay) is full (\(WeekPlan.maxDrillsPerDay) drills max). Remove one to add another.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    Button("Auto-fill \(selectedDay)", systemImage: "wand.and.stars") {
                        autoFillCount = "5"
                        showingAutoFillPrompt = true
                    }
                    ForEach(availableDrills) { drill in
                        Button {
                            add(drill.name)
                        } label: {
                            HStack {
                                Text(drill.name)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
                } header: {
                    Text("Add drills")
                }
            }
        }
        .navigationTitle("Build My Week")
        .navigationBarTitleDisplayMode(.inline)
        .alert("How many drills?", isPresented: $showingAutoFillPrompt) {
            TextField("Number of drills", text: $autoFillCount)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { }
            Button("Auto-fill") {
                guard let count = Int(autoFillCount) else { return }
                autoFill(count: count)
            }
        } message: {
            Text("Choose from 1 to \(WeekPlan.maxDrillsPerDay) drills for \(selectedDay).")
        }
    }
}

private struct FlowChips: View {
    let items: [String]
    let selected: Set<String>
    let onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                let isOn = selected.contains(item)
                Button {
                    onTap(item)
                } label: {
                    Text(item)
                        .font(.caption)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isOn ? Color.soccerAccent : Color.soccerSurfaceStrong, in: Capsule())
                        .foregroundStyle(isOn ? Color.black : Color.soccerText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

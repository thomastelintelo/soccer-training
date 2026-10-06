// PreferencesView.swift
// Lets the player change what onboarding asked: position, strongest skill, age,
// level, goals, equipment, and training time. Changes are saved as they are made
// and feed the coach and Home recommendations the next time they're shown.

import SwiftUI

struct PreferencesView: View {
    @AppStorage("playerPosition") private var position = ""
    @AppStorage("playerBestSkill") private var bestSkill = ""
    @AppStorage(PlayerPrefKey.age) private var age = 0
    @AppStorage(PlayerPrefKey.skillLevel) private var skillLevel = DrillLevel.beginner.rawValue
    @AppStorage(PlayerPrefKey.goals) private var goalsText = ""
    @AppStorage(PlayerPrefKey.equipment) private var equipmentText = ""
    @AppStorage(PlayerPrefKey.indoorOnly) private var indoorOnly = false
    @AppStorage(PlayerPrefKey.trainingMinutes) private var trainingMinutes = 30
    @AppStorage(PlayerPrefKey.trainingDays) private var trainingDays = 4
    @AppStorage(PlayerPrefKey.revision) private var revision = 0

    private var goals: Binding<Set<String>> {
        Binding(
            get: { Set(PipeList.decode(goalsText)) },
            set: { goalsText = PipeList.encode($0) }
        )
    }

    private var equipmentLabels: Binding<Set<String>> {
        Binding(
            get: { EquipmentNeeds.labels(forTokens: PipeList.decode(equipmentText)) },
            set: { equipmentText = PipeList.encode(EquipmentNeeds.tokens(forLabels: $0)) }
        )
    }

    var body: some View {
        Form {
            Section("About you") {
                Picker("Position", selection: $position) {
                    Text("Not set").tag("")
                    ForEach(PlayerPreferences.positions, id: \.self) { Text($0).tag($0) }
                }

                Picker("Strongest skill", selection: $bestSkill) {
                    Text("Not set").tag("")
                    ForEach(PlayerPreferences.bestSkills, id: \.self) { Text($0).tag($0) }
                }

                Picker("Age", selection: $age) {
                    Text("Not set").tag(0)
                    ForEach(6...20, id: \.self) { Text($0 == 20 ? "20 or older" : "\($0)").tag($0) }
                }

                Picker("Skill level", selection: $skillLevel) {
                    ForEach(DrillLevel.allCases) { level in
                        Text(level.rawValue).tag(level.rawValue)
                    }
                }
            }

            Section {
                ChipSelector(options: DrillCatalog.skills, selection: goals)
                    .padding(.vertical, 4)
            } header: {
                Text("Goals")
            } footer: {
                Text("Your goals shape recommendations and the Progress tab.")
            }

            Section {
                ChipSelector(options: EquipmentNeeds.options.map(\.label), selection: equipmentLabels)
                    .padding(.vertical, 4)
                Toggle("I mostly train indoors", isOn: $indoorOnly)
                    .tint(Color.soccerAccent)
            } header: {
                Text("Equipment")
            } footer: {
                Text("A ball is always assumed. Coach suggestions only use equipment you pick.")
            }

            Section("Training time") {
                Picker("Minutes per session", selection: $trainingMinutes) {
                    ForEach(PlayerPreferences.trainingMinuteOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }

                Stepper("\(trainingDays) days a week", value: $trainingDays, in: 2...7)
            }
        }
        .navigationTitle("Training Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.soccerBackground)
        .onDisappear {
            // Tell the Home, Train, and Progress tabs to recompute with the new answers.
            revision += 1
        }
    }
}

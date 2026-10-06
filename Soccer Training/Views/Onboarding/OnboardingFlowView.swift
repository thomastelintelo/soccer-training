// OnboardingFlowView.swift
// First-run setup: a short, paged flow that asks about the player's name, age,
// position, strongest skill, level, goals, equipment, and training time. The
// answers are saved to PlayerPreferences and drive the coach and Home
// recommendations. Every answer can be changed later in Profile.

import SwiftUI

struct OnboardingFlowView: View {
    @Binding var isSignedIn: Bool
    @AppStorage(PlayerPrefKey.revision) private var preferencesRevision = 0

    private enum Step: Int, CaseIterable {
        case name, age, position, strength, level, goals, equipment, time, review
    }

    @State private var step: Step = .name
    @State private var name = ""
    @State private var age = 13
    @State private var position = ""
    @State private var bestSkill = ""
    @State private var level: DrillLevel = .beginner
    @State private var goals: Set<String> = []
    @State private var equipment: Set<String> = []
    @State private var indoorOnly = false
    @State private var trainingMinutes = 30
    @State private var trainingDays = 4
    @State private var showConfetti = false
    @FocusState private var isNameFocused: Bool

    private let positionDetails: [String: String] = [
        "Goalkeeper": "Stopping shots and starting attacks",
        "Defender": "Winning the ball and keeping your shape",
        "Midfielder": "Linking play and controlling the tempo",
        "Winger": "Beating defenders and delivering into the box",
        "Striker": "Finishing chances and leading the line",
    ]

    private let skillDetails: [String: String] = [
        "Control": "Settling the ball and keeping it close",
        "Passing": "Finding teammates and switching the play",
        "Shooting": "Finishing and striking the ball",
        "Dribbling": "Taking players on and driving forward",
    ]

    private var canContinue: Bool {
        switch step {
        case .name: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .position: !position.isEmpty
        case .strength: !bestSkill.isEmpty
        default: true
        }
    }

    private var progress: Double {
        Double(step.rawValue + 1) / Double(Step.allCases.count)
    }

    var body: some View {
        ZStack {
            Color.soccerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    page
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .scrollDismissesKeyboard(.interactively)

                bottomBar
            }
        }
        .foregroundStyle(Color.soccerText)
        .overlay(alignment: .top) {
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            isNameFocused = true
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                go(back: true)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Color.soccerSurface, in: Circle())
            }
            .opacity(step == .name ? 0 : 1)
            .disabled(step == .name)

            LinearProgressBar(fraction: progress)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var bottomBar: some View {
        Button {
            if step == .review {
                finish()
            } else {
                go(back: false)
            }
        } label: {
            Label(step == .review ? "Start training" : "Continue", systemImage: step == .review ? "play.fill" : "arrow.right")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canContinue ? Color.soccerAccent : Color.gray.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!canContinue)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.soccerBackground)
    }

    // MARK: - Pages

    @ViewBuilder
    private var page: some View {
        switch step {
        case .name:
            pageHeader(icon: "figure.soccer", title: "What should we call you?", subtitle: "Your name shows on Home and your progress.")
            TextField("Your name", text: $name)
                .font(.title3)
                .padding(16)
                .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
                .focused($isNameFocused)
                .submitLabel(.continue)
                .textInputAutocapitalization(.words)
        case .age:
            pageHeader(icon: "birthday.cake.fill", title: "How old are you?", subtitle: "Drills are matched to your age, so we never suggest anything too intense.")
            Stepper(value: $age, in: 6...20) {
                Text(age >= 20 ? "20 or older" : "\(age) years old")
                    .font(.title2)
                    .fontWeight(.heavy)
            }
            .padding(16)
            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
        case .position:
            pageHeader(icon: "sportscourt.fill", title: "Where do you play?", subtitle: "We'll suggest drills that fit your position first.")
            SingleChoiceList(
                options: PlayerPreferences.positions.map { (value: $0, title: $0, subtitle: positionDetails[$0]) },
                selection: Binding(get: { position }, set: { position = $0 })
            )
        case .strength:
            pageHeader(icon: "star.fill", title: "What are you best at?", subtitle: "Pick the skill you're most confident in right now.")
            SingleChoiceList(
                options: PlayerPreferences.bestSkills.map { (value: $0, title: $0, subtitle: skillDetails[$0]) },
                selection: Binding(get: { bestSkill }, set: { bestSkill = $0 })
            )
        case .level:
            pageHeader(icon: "chart.bar.fill", title: "How long have you been playing?", subtitle: "This sets how hard your suggestions are.")
            SingleChoiceList(
                options: DrillLevel.allCases.map { (value: $0, title: $0.rawValue, subtitle: levelDetail($0)) },
                selection: $level
            )
        case .goals:
            pageHeader(icon: "target", title: "What do you want to improve?", subtitle: "Pick as many as you like. These shape your recommendations and goals.")
            ChipSelector(options: DrillCatalog.skills, selection: $goals)
        case .equipment:
            pageHeader(icon: "shippingbox.fill", title: "What equipment do you have?", subtitle: "We assume you have a ball. We only suggest drills you can do with what you pick.")
            ChipSelector(options: EquipmentNeeds.options.map(\.label), selection: $equipment)
            Toggle(isOn: $indoorOnly) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("I mostly train indoors")
                        .font(.headline)
                    Text("Prefer drills that work in a small, safe space.")
                        .font(.caption)
                        .foregroundStyle(Color.soccerText.opacity(0.6))
                }
            }
            .tint(Color.soccerAccent)
            .padding(16)
            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
        case .time:
            pageHeader(icon: "timer", title: "How much time can you train?", subtitle: "Your coach builds sessions that fit this.")
            VStack(alignment: .leading, spacing: 14) {
                Text("Per session")
                    .font(.headline)
                Picker("Minutes per session", selection: $trainingMinutes) {
                    ForEach(PlayerPreferences.trainingMinuteOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.segmented)

                Stepper(value: $trainingDays, in: 2...7) {
                    Text("\(trainingDays) days a week")
                        .font(.headline)
                }
            }
            .padding(16)
            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
        case .review:
            pageHeader(icon: "checkmark.seal.fill", title: "You're all set, \(displayName)", subtitle: "Here's your starting plan. Change anything later in Profile.")
            VStack(spacing: 0) {
                reviewRow("Age", ageText)
                reviewRow("Position", position)
                reviewRow("Strongest skill", bestSkill)
                reviewRow("Level", level.rawValue)
                reviewRow("Goals", goals.isEmpty ? "Balanced" : goals.sorted().joined(separator: ", "))
                reviewRow("Equipment", equipmentSummary)
                reviewRow("Training", "\(trainingMinutes) min, \(trainingDays) days a week")
            }
            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func pageHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.soccerAccent)
                .padding(.bottom, 4)
            Text(title)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.soccerText.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }

    private func reviewRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.soccerText.opacity(0.6))
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 16)
        }
    }

    private func levelDetail(_ level: DrillLevel) -> String {
        switch level {
        case .beginner: "Still learning the basics"
        case .intermediate: "Comfortable with the basics and playing regularly"
        case .advanced: "Playing at a high level or competing"
        }
    }

    private var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var ageText: String {
        age >= 20 ? "20 or older" : "\(age)"
    }

    private var equipmentSummary: String {
        equipment.isEmpty ? "Ball only" : "Ball, " + equipment.sorted().joined(separator: ", ").lowercased()
    }

    // MARK: - Navigation and saving

    private func go(back: Bool) {
        let target = Step(rawValue: step.rawValue + (back ? -1 : 1))
        guard let target else { return }
        Haptics.tap()
        withAnimation(.easeInOut(duration: 0.3)) {
            step = target
        }
        isNameFocused = target == .name
    }

    private func finish() {
        let defaults = UserDefaults.standard
        defaults.set(displayName, forKey: "playerUsername")
        defaults.set(position, forKey: "playerPosition")
        defaults.set(bestSkill, forKey: "playerBestSkill")
        defaults.set(age, forKey: PlayerPrefKey.age)
        defaults.set(level.rawValue, forKey: PlayerPrefKey.skillLevel)
        defaults.set(PipeList.encode(goals), forKey: PlayerPrefKey.goals)
        defaults.set(PipeList.encode(EquipmentNeeds.tokens(forLabels: equipment)), forKey: PlayerPrefKey.equipment)
        defaults.set(indoorOnly, forKey: PlayerPrefKey.indoorOnly)
        defaults.set(trainingMinutes, forKey: PlayerPrefKey.trainingMinutes)
        defaults.set(trainingDays, forKey: PlayerPrefKey.trainingDays)
        preferencesRevision += 1

        Haptics.success()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showConfetti = true
        }
        // Let the confetti play before the app swaps to the main tabs.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            isSignedIn = true
        }
    }
}

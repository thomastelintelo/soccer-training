// SessionRunnerView.swift
// Walks the player through a whole session: warm-up, drills, cool-down. Shows
// progress as they go, marks a step done when its timer completes, and ends on a
// completion screen. Each session is saved as it goes, so "Continue Training"
// can pick it up later.

import SwiftUI

struct SessionRunnerView: View {
    @State private var session: ActiveSession
    @Binding var totalPoints: Int
    @AppStorage("playerXP") private var playerXP = 0
    @AppStorage("sessionsCompleted") private var sessionsCompleted = 0
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0
    @AppStorage("trainingStreak") private var trainingStreak = 0
    @Environment(\.dismiss) private var dismiss

    private static let sessionBonusPoints = 50
    private static let sessionBonusXP = 20

    init(session: ActiveSession, totalPoints: Binding<Int>) {
        _session = State(initialValue: session)
        _totalPoints = totalPoints
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if session.isFinished {
                    completionCard
                } else {
                    progressHeader
                    currentCard
                }

                stepList
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Color.soccerBackground)
        .foregroundStyle(Color.soccerText)
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if session.isFinished && session.pointsEarned > 0 {
                ConfettiView()
            }
        }
        .onAppear {
            ActiveSessionStore.save(session)
        }
        .onChange(of: session) { _, updated in
            ActiveSessionStore.save(updated)
        }
    }

    // MARK: - Progress

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Step \(min(session.completedCount + 1, session.steps.count)) of \(session.steps.count)")
                    .font(.headline)
                    .fontWeight(.heavy)
                Spacer()
                Text("\(Int((session.progress * 100).rounded()))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soccerAccent)
            }
            LinearProgressBar(fraction: session.progress)
            Text("\(session.totalMinutes) min total · \(session.mainDrillCount) drills")
                .font(.caption)
                .foregroundStyle(Color.soccerText.opacity(0.6))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Current step

    @ViewBuilder
    private var currentCard: some View {
        if let step = session.currentStep {
            let index = session.currentIndex
            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .bottomLeading) {
                    DrillArtwork(drillName: step.drillName, height: 170)
                    LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                    Text(step.role.uppercased())
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                        .padding(12)
                }
                .frame(height: 170)
                .clipShape(.rect(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 6) {
                    Text(step.drillName)
                        .font(.title2)
                        .fontWeight(.heavy)
                    let info = DrillCatalog.info(for: step.drillName)
                    HStack(spacing: 6) {
                        MetaChip(text: "\(info.minutes) min", icon: "clock.fill")
                        MetaChip(text: info.skill, icon: DrillPresentation.icon(for: info.skill))
                    }
                }

                if step.status == .pending {
                    pendingActions(for: step, at: index)
                } else {
                    handledActions(for: step)
                }
            }
            .padding(16)
            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.soccerAccent.opacity(0.35), lineWidth: 2)
            }
        }
    }

    private func pendingActions(for step: ActiveSession.Step, at index: Int) -> some View {
        VStack(spacing: 10) {
            NavigationLink {
                DrillTimerView(
                    drill: Drill(name: step.drillName),
                    totalPoints: $totalPoints,
                    onCompleted: { markStep(at: index, as: .done, logged: false) }
                )
            } label: {
                Label("Start Drill", systemImage: "play.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.soccerAccent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 10) {
                Button {
                    markStep(at: index, as: .done, logged: true)
                } label: {
                    Label("Mark complete", systemImage: "checkmark")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.soccerBackground, in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    markStep(at: index, as: .skipped, logged: false)
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.soccerBackground, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .buttonStyle(.plain)

            Text("The timer records points and XP. Mark complete logs the time without them.")
                .font(.caption)
                .foregroundStyle(Color.soccerText.opacity(0.55))
                .multilineTextAlignment(.center)
        }
    }

    private func handledActions(for step: ActiveSession.Step) -> some View {
        VStack(spacing: 12) {
            Label(
                step.status == .done ? "Done" : "Skipped",
                systemImage: step.status == .done ? "checkmark.seal.fill" : "forward.fill"
            )
            .font(.headline)
            .foregroundStyle(step.status == .done ? Color.soccerAccent : Color.soccerText.opacity(0.6))

            Button {
                advance()
            } label: {
                Label(nextStepTitle, systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.soccerAccent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var nextStepTitle: String {
        let hasNext = session.steps.contains { $0.status == .pending }
        return hasNext ? "Next step" : "Finish session"
    }

    // MARK: - Steps list

    private var stepList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Session plan")
                .font(.headline)
                .fontWeight(.heavy)

            ForEach(Array(session.steps.enumerated()), id: \.element.id) { index, step in
                Button {
                    jump(to: index)
                } label: {
                    HStack(spacing: 12) {
                        statusIcon(for: step, isCurrent: index == session.currentIndex && !session.isFinished)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.role.uppercased())
                                .font(.caption2)
                                .fontWeight(.black)
                                .foregroundStyle(Color.soccerText.opacity(0.55))
                            Text(step.drillName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(step.status == .skipped ? Color.soccerText.opacity(0.45) : Color.soccerText)
                        }
                        Spacer()
                        Text("\(DrillTimerView.duration(for: step.drillName) / 60) min")
                            .font(.caption)
                            .foregroundStyle(Color.soccerText.opacity(0.55))
                    }
                    .padding(12)
                    .background(
                        index == session.currentIndex && !session.isFinished
                            ? Color.soccerAccent.opacity(0.08)
                            : Color.soccerSurface,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .buttonStyle(.plain)
                .disabled(step.status != .pending || index == session.currentIndex || session.isFinished)
            }
        }
    }

    private func statusIcon(for step: ActiveSession.Step, isCurrent: Bool) -> some View {
        let name: String
        let color: Color
        switch step.status {
        case .done:
            name = "checkmark.circle.fill"
            color = Color.soccerAccent
        case .skipped:
            name = "forward.circle.fill"
            color = Color.soccerText.opacity(0.4)
        case .pending:
            name = isCurrent ? "play.circle.fill" : "circle"
            color = isCurrent ? Color.soccerAccent : Color.soccerText.opacity(0.3)
        }
        return Image(systemName: name)
            .font(.title2)
            .foregroundStyle(color)
            .frame(width: 30)
    }

    // MARK: - Completion

    private var completionCard: some View {
        let completed = session.steps.filter { $0.status == .done }
        let minutes = completed.reduce(0) { $0 + DrillTimerView.duration(for: $1.drillName) / 60 }

        return VStack(spacing: 18) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.soccerGold)
                .symbolEffect(.bounce, value: session.isFinished)

            Text("Session complete")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)

            Text(completionMessage(completedCount: completed.count))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.soccerText.opacity(0.7))

            HStack(spacing: 10) {
                completionTile(value: "\(completed.count)", title: "STEPS DONE", icon: "checkmark.circle.fill")
                completionTile(value: "\(minutes) min", title: "TRAINED", icon: "timer")
                completionTile(value: "\(trainingStreak)", title: "DAY STREAK", icon: "flame.fill")
            }

            if session.pointsEarned > 0 {
                Text("Session bonus: +\(session.pointsEarned) points · +\(Self.sessionBonusXP) XP")
                    .font(.headline)
                    .foregroundStyle(Color.soccerAccent)
            }

            Button {
                dismiss()
            } label: {
                Text("Back to training")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.soccerAccent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 22))
    }

    private func completionMessage(completedCount: Int) -> String {
        if completedCount == 0 {
            return "Nothing was logged this time. Come back to it whenever you're ready."
        }
        return "Every rep counts. Your progress is saved in Progress."
    }

    private func completionTile(value: String, title: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(Color.soccerAccent)
            Text(value)
                .font(.headline)
                .fontWeight(.heavy)
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Color.soccerText.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.soccerBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - State changes

    /// Marks one step handled. `logged` records the time to Progress without
    /// awarding points, for players who train without the timer.
    private func markStep(at index: Int, as status: ActiveSession.StepStatus, logged: Bool) {
        guard session.steps.indices.contains(index), session.steps[index].status == .pending else { return }
        let step = session.steps[index]

        if logged {
            let minutes = DrillTimerView.duration(for: step.drillName) / 60
            TrainingLog.record(
                drillName: step.drillName,
                skill: DrillCatalog.skill(for: step.drillName),
                minutes: minutes,
                xp: 0
            )
            totalTrainingMinutes += minutes
        }

        session.steps[index].status = status
        if session.steps.allSatisfy({ $0.status != .pending }) {
            finish()
        }
    }

    /// Moves to the next step that hasn't been handled, or does nothing if all are.
    private func advance() {
        if let next = session.steps.indices.first(where: { $0 > session.currentIndex && session.steps[$0].status == .pending })
            ?? session.steps.indices.first(where: { session.steps[$0].status == .pending }) {
            session.currentIndex = next
        }
    }

    private func jump(to index: Int) {
        guard session.steps.indices.contains(index), session.steps[index].status == .pending else { return }
        withAnimation(.snappy) {
            session.currentIndex = index
        }
    }

    /// Ends the session once, awarding the bonus only if at least one step was done.
    private func finish() {
        guard !session.isFinished else { return }
        let completed = session.completedCount
        if completed > 0 {
            totalPoints += Self.sessionBonusPoints
            playerXP += Self.sessionBonusXP
            sessionsCompleted += 1
            session.pointsEarned = Self.sessionBonusPoints
        }
        session.isFinished = true
    }
}

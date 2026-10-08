// AssignedDrillTimerView.swift
// Countdown timer for a drill the coach assigned, with the same Live Activity
// and finish chime as the regular drill timer.

import Combine
import SwiftUI

struct AssignedDrillTimerView: View {
    let title: String
    let details: String
    let minutes: Int

    @Environment(\.dismiss) private var dismiss
    @State private var endDate: Date?
    @State private var timeLeft: Int
    @State private var isFinished = false

    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    init(title: String, details: String, minutes: Int) {
        self.title = title
        self.details = details
        self.minutes = minutes
        _timeLeft = State(initialValue: minutes * 60)
    }

    private var isRunning: Bool { endDate != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(title).font(.largeTitle.bold()).multilineTextAlignment(.center)

                Text(String(format: "%d:%02d", timeLeft / 60, timeLeft % 60))
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isFinished ? Color.green : Color.soccerAccent)

                if isFinished {
                    Label("Great work! Drill complete.", systemImage: "checkmark.seal.fill")
                        .font(.headline).foregroundStyle(.green)
                }

                if !details.isEmpty {
                    Text(details)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 16))
                }

                if isFinished {
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                } else if isRunning {
                    Button("Stop Timer", systemImage: "stop.fill", role: .destructive, action: stop)
                        .buttonStyle(.bordered)
                } else {
                    Button("Start Timer", systemImage: "play.fill", action: start)
                        .font(.title3.bold())
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .background(SoccerBackgroundView())
        .navigationTitle("Coach Drill")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(ticker) { _ in tick() }
        .onDisappear { if isRunning { stop() } }
    }

    private func start() {
        let seconds = minutes * 60
        timeLeft = seconds
        endDate = Date().addingTimeInterval(TimeInterval(seconds))
        DrillTimerLiveActivity.shared.start(
            drillName: title,
            category: DrillPresentation.category(for: title),
            duration: seconds
        )
        Haptics.soft()
    }

    private func stop() {
        endDate = nil
        timeLeft = minutes * 60
        DrillTimerLiveActivity.shared.cancel()
    }

    private func tick() {
        guard let endDate else { return }
        let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
        if remaining <= 0 {
            self.endDate = nil
            timeLeft = 0
            isFinished = true
            DrillTimerLiveActivity.shared.finish()
            Haptics.success()
        } else {
            timeLeft = remaining
        }
    }
}

//
//  DrillTimerLiveActivity.swift
//  Soccer Training
//
//  Starts and ends the drill timer Live Activity. When the timer runs out it
//  plays the gentle chime and flips the Live Activity to its completed state,
//  without posting a separate notification.
//
//  The app is normally suspended while the screen is locked, which would stop
//  both the chime and the Live Activity update. To keep them on time, a silent
//  audio loop (the "audio" background mode) keeps the app running until the
//  timer finishes.
//

import ActivityKit
import AVFoundation
import Foundation
import SwiftUI
import UIKit
import UserNotifications

final class DrillTimerLiveActivity: NSObject {
    static let shared = DrillTimerLiveActivity()

    private static let legacyAlarmNotificationID = "drill-timer-finished"

    private var activity: Activity<DrillTimerAttributes>?
    private var startTask: Task<Void, Never>?
    private var finishTask: Task<Void, Never>?
    private var keepAlivePlayer: AVAudioPlayer?
    private var chimePlayer: AVAudioPlayer?
    private var isRunning = false

    func start(drillName: String, category: String, duration: Int) {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(TimeInterval(duration))

        startTask?.cancel()
        finishTask?.cancel()
        isRunning = true
        clearLegacyNotification()
        beginKeepAlive()
        scheduleFinish(at: endDate)

        startTask = Task {
            await endAllActivities()
            guard !Task.isCancelled else { return }
            requestActivity(
                attributes: DrillTimerAttributes(
                    drillName: drillName,
                    category: category,
                    startDate: startDate,
                    endDate: endDate,
                    theme: Self.currentTheme
                )
            )
        }
    }

    /// The user stopped the drill early: remove the Live Activity and stay silent.
    func cancel() {
        isRunning = false
        startTask?.cancel()
        finishTask?.cancel()
        stopKeepAlive()
        clearLegacyNotification()

        Task {
            await endAllActivities()
        }
    }

    /// The timer reached zero: chime and show the completed state.
    func finish() {
        guard isRunning else { return }
        isRunning = false
        finishTask?.cancel()
        playChime()

        guard let activity else { return }
        self.activity = nil

        Task {
            await activity.end(
                ActivityContent(state: .init(isFinished: true), staleDate: nil),
                dismissalPolicy: .after(.now.addingTimeInterval(5 * 60))
            )
        }
    }

    // MARK: - Audio

    private func scheduleFinish(at endDate: Date) {
        finishTask = Task {
            do {
                try await Task.sleep(for: .seconds(max(0, endDate.timeIntervalSinceNow)))
            } catch {
                return
            }
            finish()
        }
    }

    private func beginKeepAlive() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        guard keepAlivePlayer == nil, let player = try? AVAudioPlayer(data: Self.silentWAV) else { return }
        player.numberOfLoops = -1
        player.prepareToPlay()
        player.play()
        keepAlivePlayer = player
    }

    private func stopKeepAlive() {
        keepAlivePlayer?.stop()
        keepAlivePlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func playChime() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        guard
            let url = Bundle.main.url(forResource: "gentle_chime", withExtension: "caf"),
            let player = try? AVAudioPlayer(contentsOf: url)
        else {
            stopKeepAlive()
            return
        }
        chimePlayer = player
        player.volume = 1
        player.prepareToPlay()
        player.play()

        // Keep the audio session alive until the chime has finished.
        Task {
            try? await Task.sleep(for: .seconds(player.duration + 0.5))
            chimePlayer = nil
            if !isRunning { stopKeepAlive() }
        }
    }

    /// One second of silence as a WAV file, looped to keep the app running.
    private static let silentWAV: Data = {
        let sampleRate = 8000
        let dataSize = sampleRate * 2
        var data = Data()
        func append32(_ value: Int) { withUnsafeBytes(of: UInt32(value).littleEndian) { data.append(contentsOf: $0) } }
        func append16(_ value: Int) { withUnsafeBytes(of: UInt16(value).littleEndian) { data.append(contentsOf: $0) } }
        data.append(contentsOf: Array("RIFF".utf8)); append32(36 + dataSize)
        data.append(contentsOf: Array("WAVEfmt ".utf8)); append32(16)
        append16(1); append16(1); append32(sampleRate); append32(sampleRate * 2); append16(2); append16(16)
        data.append(contentsOf: Array("data".utf8)); append32(dataSize)
        data.append(Data(count: dataSize))
        return data
    }()

    /// Older builds scheduled a "Time's up!" notification; make sure none is left pending.
    private func clearLegacyNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.legacyAlarmNotificationID])
    }

    /// The app's current background theme colors, captured as plain RGBA values
    /// so the widget extension can render the matching theme on its own.
    private static var currentTheme: DrillTimerTheme {
        DrillTimerTheme(
            accent: Color.soccerAccent.drillTimerComponents,
            background: Color.soccerBackground.drillTimerComponents,
            surface: Color.soccerSurface.drillTimerComponents
        )
    }

    private func requestActivity(attributes: DrillTimerAttributes) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(
                    state: .init(isFinished: false),
                    staleDate: attributes.endDate
                ),
                pushType: nil
            )
        } catch {
            print("Failed to start drill timer Live Activity: \(error)")
        }
    }

    private func endAllActivities() async {
        activity = nil
        for activity in Activity<DrillTimerAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

private extension Color {
    var drillTimerComponents: DrillTimerColorComponents {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return DrillTimerColorComponents(
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            opacity: Double(alpha)
        )
    }
}

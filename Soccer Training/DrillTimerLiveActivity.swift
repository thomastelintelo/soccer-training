//
//  DrillTimerLiveActivity.swift
//  Soccer Training
//
//  Starts and ends the drill timer Live Activity, and schedules the gentle
//  chime notification that plays when the timer finishes (even on the lock screen).
//

import ActivityKit
import Foundation
import UserNotifications

final class DrillTimerLiveActivity: NSObject {
    static let shared = DrillTimerLiveActivity()

    private static let alarmNotificationID = "drill-timer-finished"
    private static let alarmSoundName = "gentle_chime.caf"

    private var activity: Activity<DrillTimerAttributes>?
    private var startTask: Task<Void, Never>?

    /// Call once at launch so the chime also plays if the timer finishes while the app is open.
    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    func start(drillName: String, category: String, duration: Int) {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(TimeInterval(duration))

        startTask?.cancel()
        startTask = Task {
            await endAllActivities()
            guard !Task.isCancelled else { return }
            requestActivity(
                attributes: DrillTimerAttributes(
                    drillName: drillName,
                    category: category,
                    startDate: startDate,
                    endDate: endDate
                )
            )
            await scheduleAlarm(drillName: drillName, at: endDate)
        }
    }

    /// The user stopped the drill early: remove the Live Activity and cancel the alarm.
    func cancel() {
        startTask?.cancel()
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.alarmNotificationID])

        Task {
            await endAllActivities()
        }
    }

    /// The timer reached zero: show "Time's up" briefly, then dismiss.
    func finish() {
        guard let activity else { return }
        self.activity = nil

        Task {
            await activity.end(
                ActivityContent(state: .init(isFinished: true), staleDate: nil),
                dismissalPolicy: .after(.now.addingTimeInterval(60))
            )
        }
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

    private func scheduleAlarm(drillName: String, at endDate: Date) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.alarmNotificationID])

        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else {
            return
        }
        guard !Task.isCancelled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time's up!"
        content.body = "\(drillName) is complete. Open the app to log your drill."
        content.sound = UNNotificationSound(named: UNNotificationSoundName(Self.alarmSoundName))

        let interval = max(1, endDate.timeIntervalSinceNow)
        let request = UNNotificationRequest(
            identifier: Self.alarmNotificationID,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule drill timer alarm: \(error)")
        }
    }
}

extension DrillTimerLiveActivity: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

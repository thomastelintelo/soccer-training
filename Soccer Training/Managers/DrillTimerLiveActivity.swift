//
//  DrillTimerLiveActivity.swift
//  Soccer Training
//
//  Starts and ends the drill timer Live Activity, and schedules the gentle
//  chime notification that plays when the timer finishes (even on the lock screen).
//

import ActivityKit
import Foundation
import SwiftUI
import UIKit
import UserNotifications

final class DrillTimerLiveActivity: NSObject {
    static let shared = DrillTimerLiveActivity()

    private static let alarmNotificationID = "drill-timer-finished"
    private static let alarmSoundName = "gentle_chime.caf"

    private var activity: Activity<DrillTimerAttributes>?
    private var startTask: Task<Void, Never>?

    /// Call once at launch so the chime also plays if the timer finishes while the app is open.
    /// Also requests notification permission up front, so it's already granted by the time a
    /// drill finishes with the screen locked instead of racing a just-in-time prompt.
    func configure() {
        UNUserNotificationCenter.current().delegate = self
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
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
                    endDate: endDate,
                    theme: Self.currentTheme
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

    /// The app's current team colors, captured as plain RGBA values so the widget
    /// extension can render the matching theme without reading `favoriteTeam` itself.
    private static var currentTheme: DrillTimerTheme {
        DrillTimerTheme(
            accent: Color.soccerLime.drillTimerComponents,
            background: Color.soccerNavy.drillTimerComponents,
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
        // Time-sensitive so it still breaks through on the lock screen or in a Focus mode.
        content.interruptionLevel = .timeSensitive

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

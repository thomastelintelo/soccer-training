// TrainingLog.swift
// A history of completed drills, saved as JSON. It drives the weekly activity
// chart, the recently completed list, weekly challenges, and the streak.
// Writes bump a version key so any view reading the log redraws right away.

import Foundation

struct TrainingEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let drillName: String
    let skill: String
    let minutes: Int
    let xp: Int
    let date: Date
}

enum TrainingLog {
    static let versionKey = "trainingLogVersion"
    private static let storageKey = "trainingLogData"
    private static let maxEntries = 1_000

    static func entries() -> [TrainingEntry] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let entries = try? JSONDecoder().decode([TrainingEntry].self, from: data)
        else {
            return []
        }
        return entries
    }

    static func record(drillName: String, skill: String, minutes: Int, xp: Int, date: Date = Date()) {
        var all = entries()
        all.append(TrainingEntry(id: UUID(), drillName: drillName, skill: skill, minutes: minutes, xp: xp, date: date))
        if all.count > maxEntries {
            all.removeFirst(all.count - maxEntries)
        }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: versionKey) + 1, forKey: versionKey)
    }

    /// Minutes trained on each of the last `days` days, oldest first, ending today.
    static func dailyMinutes(_ entries: [TrainingEntry], days: Int, now: Date = Date(), calendar: Calendar = .current) -> [(day: Date, minutes: Int)] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let minutes = entries
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.minutes }
            return (day: day, minutes: minutes)
        }
    }

    /// Distinct days, as start-of-day dates, that have any training in them.
    static func trainedDays(_ entries: [TrainingEntry], calendar: Calendar = .current) -> Set<Date> {
        Set(entries.map { calendar.startOfDay(for: $0.date) })
    }

    /// Drill names, most recently completed first, without repeats.
    static func recentlyCompleted(_ entries: [TrainingEntry], limit: Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for entry in entries.reversed() where !seen.contains(entry.drillName) {
            seen.insert(entry.drillName)
            result.append(entry.drillName)
            if result.count == limit { break }
        }
        return result
    }

    /// The most recent completion date for each drill.
    static func lastTrained(_ entries: [TrainingEntry]) -> [String: Date] {
        entries.reduce(into: [String: Date]()) { result, entry in
            result[entry.drillName] = max(result[entry.drillName] ?? .distantPast, entry.date)
        }
    }

    /// Entries from the current calendar week, Monday to Sunday or whatever the locale uses.
    static func thisWeek(_ entries: [TrainingEntry], now: Date = Date(), calendar: Calendar = .current) -> [TrainingEntry] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        return entries.filter { week.contains($0.date) }
    }
}

enum TrainingStreak {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func dayString(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// The streak the player can still show. It drops to zero once a whole day
    /// has passed without training.
    static func current(stored: Int, lastDay: String, now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return 0 }
        let today = dayString(for: now)
        return (lastDay == today || lastDay == dayString(for: yesterday)) ? stored : 0
    }
}

/// Weekly challenges rotate through a fixed list, one per calendar week, so
/// every week asks for something a little different.
struct WeeklyChallenge {
    let title: String
    let detail: String
    let systemImage: String
    let progress: Int
    let target: Int

    var isComplete: Bool { progress >= target }
    var fraction: Double { min(1, Double(progress) / Double(max(target, 1))) }

    static func current(entries: [TrainingEntry], now: Date = Date(), calendar: Calendar = .current) -> WeeklyChallenge {
        let week = calendar.component(.weekOfYear, from: now)
        let thisWeek = TrainingLog.thisWeek(entries, now: now, calendar: calendar)
        let trainedDays = TrainingLog.trainedDays(thisWeek, calendar: calendar).count
        let minutes = thisWeek.reduce(0) { $0 + $1.minutes }

        let options: [WeeklyChallenge] = [
            WeeklyChallenge(
                title: "Complete 8 drills",
                detail: "Finish eight drills before the week ends.",
                systemImage: "checkmark.seal.fill",
                progress: thisWeek.count,
                target: 8
            ),
            WeeklyChallenge(
                title: "Train on 4 different days",
                detail: "Consistency beats intensity. Show up four days.",
                systemImage: "calendar.badge.checkmark",
                progress: trainedDays,
                target: 4
            ),
            WeeklyChallenge(
                title: "Log 120 minutes",
                detail: "Put in two solid hours of work this week.",
                systemImage: "timer",
                progress: minutes,
                target: 120
            ),
        ]
        return options[week % options.count]
    }
}

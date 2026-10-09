// WeeklyLog.swift
// Per-week training totals so the Progress dashboard can compare this week
// with previous ones. Persisted as JSON under "weeklyLog", keyed by the
// week's start date (yyyy-MM-dd).

import Foundation

struct WeekRecord: Codable {
    var drills = 0
    var minutes = 0
    var xp = 0
    var attempts = 0
    var successes = 0

    /// 0...1, or nil when no scored attempts were recorded.
    var accuracy: Double? {
        attempts > 0 ? min(1, Double(successes) / Double(attempts)) : nil
    }
}

enum WeeklyLog {
    static func decode(_ text: String) -> [String: WeekRecord] {
        guard let data = text.data(using: .utf8),
              let values = try? JSONDecoder().decode([String: WeekRecord].self, from: data) else { return [:] }
        return values
    }

    static func encode(_ values: [String: WeekRecord]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }

    static func weekStart(for date: Date) -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }

    static func key(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: weekStart(for: date))
    }

    /// Key of the week `weeksAgo` weeks before the one containing `date`.
    static func key(weeksAgo: Int, from date: Date = Date()) -> String {
        let start = weekStart(for: date)
        return key(for: Calendar.current.date(byAdding: .weekOfYear, value: -weeksAgo, to: start) ?? start)
    }

    static func add(
        to text: String,
        drills: Int = 0,
        minutes: Int = 0,
        xp: Int = 0,
        attempts: Int = 0,
        successes: Int = 0
    ) -> String {
        var log = decode(text)
        var record = log[key(for: Date())] ?? WeekRecord()
        record.drills += drills
        record.minutes += minutes
        record.xp += xp
        record.attempts += attempts
        record.successes += successes
        log[key(for: Date())] = record
        return encode(log)
    }
}

// CategoryProgress.swift
// Per-category XP and training-minute totals, keyed by category name (e.g.
// "Shooting", "Soccer IQ") so every skill category — including ones added
// later — earns and displays progress uniformly, without needing its own
// named @AppStorage property. Persisted in a pipe-delimited
// "key:value|key:value" encoding.

import Foundation

struct CategoryProgress {
    private(set) var xp: [String: Int]
    private(set) var minutes: [String: Int]

    init(xpText: String, minutesText: String) {
        xp = Self.decode(xpText)
        minutes = Self.decode(minutesText)
    }

    func xp(for category: String) -> Int {
        xp[category] ?? 0
    }

    func minutes(for category: String) -> Int {
        minutes[category] ?? 0
    }

    mutating func addXP(_ amount: Int, to category: String) {
        xp[category, default: 0] += amount
    }

    mutating func addMinutes(_ amount: Int, to category: String) {
        minutes[category, default: 0] += amount
    }

    var xpText: String { Self.encode(xp) }
    var minutesText: String { Self.encode(minutes) }

    private static func decode(_ text: String) -> [String: Int] {
        Dictionary(
            uniqueKeysWithValues: text.split(separator: "|").compactMap { entry -> (String, Int)? in
                let parts = entry.split(separator: ":", maxSplits: 1)
                guard parts.count == 2, let value = Int(parts[1]) else { return nil }
                return (String(parts[0]), value)
            }
        )
    }

    private static func encode(_ dict: [String: Int]) -> String {
        dict
            .filter { $0.value != 0 }
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: "|")
    }
}

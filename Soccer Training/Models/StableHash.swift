// StableHash.swift
// A stable string hash (djb2). Swift's built-in `Hasher` is randomized per
// process, so it can't be used for anything that needs the same value
// across launches, like a generated avatar's colors.

import Foundation

enum StableHash {
    static func value(_ string: String) -> Int {
        var hash = 5381
        for scalar in string.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return abs(hash)
    }
}

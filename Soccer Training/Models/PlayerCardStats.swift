// PlayerCardStats.swift
// A single FIFA-card-style sub-stat (PAC/SHO/PAS/DRI/DEF/PHY, or a
// goalkeeper equivalent) shown on the player's own card and stat grid.

struct PlayerCardStat: Identifiable {
    var id: String { label }
    let label: String
    let value: Int
}

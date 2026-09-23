// Color+Soccer.swift
// App-wide palette. Falls back to the default green/lime theme when no
// favorite team is selected, otherwise follows the chosen team's colors.

import SwiftUI

extension Color {
    private static var favoriteTeam: FavoriteTeam? {
        guard let teamName = UserDefaults.standard.string(forKey: "favoriteTeam") else {
            return nil
        }
        return FavoriteTeam(rawValue: teamName)
    }

    static let soccerCream = Color(red: 0.96, green: 0.99, blue: 0.97)
    static var soccerGreen: Color {
        favoriteTeam?.primaryColor ?? Color(red: 0.00, green: 0.55, blue: 0.30)
    }
    static var soccerLime: Color {
        favoriteTeam?.highlightColor ?? Color(red: 0.65, green: 0.95, blue: 0.18)
    }
    static var soccerNavy: Color {
        favoriteTeam?.darkColor ?? Color(red: 0.02, green: 0.10, blue: 0.07)
    }
    static var soccerSurface: Color {
        favoriteTeam?.surfaceColor ?? Color(red: 0.06, green: 0.16, blue: 0.11)
    }
    static let soccerGold = Color(red: 1.00, green: 0.76, blue: 0.20)
}

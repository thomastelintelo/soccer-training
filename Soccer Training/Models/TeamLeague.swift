// TeamLeague.swift
// The leagues and clubs a player can pick as their favorite team.

import SwiftUI

enum TeamLeague: String, CaseIterable, Identifiable {
    case premierLeague = "Premier League"
    case laLiga = "La Liga"
    case mls = "Major League Soccer"
    case other = "Other"

    var id: String { rawValue }
}

enum FavoriteTeam: String, CaseIterable, Identifiable {
    // Premier League 2026–27
    case arsenal = "Arsenal"
    case astonVilla = "Aston Villa"
    case bournemouth = "Bournemouth"
    case brentford = "Brentford"
    case brighton = "Brighton & Hove Albion"
    case chelsea = "Chelsea"
    case coventryCity = "Coventry City"
    case crystalPalace = "Crystal Palace"
    case everton = "Everton"
    case fulham = "Fulham"
    case hullCity = "Hull City"
    case ipswichTown = "Ipswich Town"
    case leedsUnited = "Leeds United"
    case liverpool = "Liverpool"
    case manchesterCity = "Manchester City"
    case manchesterUnited = "Manchester United"
    case newcastleUnited = "Newcastle United"
    case nottinghamForest = "Nottingham Forest"
    case sunderland = "Sunderland"
    case tottenham = "Tottenham Hotspur"

    // La Liga 2026–27
    case athleticClub = "Athletic Club"
    case atleticoMadrid = "Atlético de Madrid"
    case osasuna = "CA Osasuna"
    case celtaVigo = "Celta"
    case alaves = "Deportivo Alavés"
    case elche = "Elche CF"
    case barcelona = "Barcelona"
    case getafe = "Getafe CF"
    case levante = "Levante UD"
    case malaga = "Málaga CF"
    case racingSantander = "Racing de Santander"
    case rayoVallecano = "Rayo Vallecano"
    case deportivoLaCoruna = "RC Deportivo"
    case espanyol = "RCD Espanyol"
    case realBetis = "Real Betis"
    case realMadrid = "Real Madrid"
    case realSociedad = "Real Sociedad"
    case sevilla = "Sevilla FC"
    case valencia = "Valencia CF"
    case villarreal = "Villarreal CF"

    // Major League Soccer 2026
    case atlantaUnited = "Atlanta United"
    case austinFC = "Austin FC"
    case charlotteFC = "Charlotte FC"
    case chicagoFire = "Chicago Fire FC"
    case cincinnati = "FC Cincinnati"
    case coloradoRapids = "Colorado Rapids"
    case columbusCrew = "Columbus Crew"
    case dcUnited = "D.C. United"
    case fcDallas = "FC Dallas"
    case houstonDynamo = "Houston Dynamo FC"
    case sportingKansasCity = "Sporting Kansas City"
    case laGalaxy = "LA Galaxy"
    case lafc = "Los Angeles FC"
    case interMiami = "Inter Miami"
    case minnesotaUnited = "Minnesota United FC"
    case cfMontreal = "CF Montréal"
    case nashville = "Nashville SC"
    case newEngland = "New England Revolution"
    case newYorkRedBulls = "New York Red Bulls"
    case nycfc = "New York City FC"
    case orlandoCity = "Orlando City SC"
    case philadelphiaUnion = "Philadelphia Union"
    case portlandTimbers = "Portland Timbers"
    case realSaltLake = "Real Salt Lake"
    case sanDiegoFC = "San Diego FC"
    case sanJoseEarthquakes = "San Jose Earthquakes"
    case seattleSounders = "Seattle Sounders FC"
    case stLouisCity = "St. Louis City SC"
    case torontoFC = "Toronto FC"
    case vancouverWhitecaps = "Vancouver Whitecaps FC"

    case parisSaintGermain = "Paris Saint-Germain"
    case bayernMunich = "Bayern Munich"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barcelona: "FC Barcelona"
        case .interMiami: "Inter Miami CF"
        default: rawValue
        }
    }

    var league: TeamLeague {
        if Self.premierLeagueTeams.contains(self) { return .premierLeague }
        if Self.laLigaTeams.contains(self) { return .laLiga }
        if Self.mlsTeams.contains(self) { return .mls }
        return .other
    }

    var wikipediaTitle: String {
        switch self {
        case .arsenal: "Arsenal F.C."
        case .bournemouth: "AFC Bournemouth"
        case .brighton: "Brighton & Hove Albion F.C."
        case .chelsea: "Chelsea F.C."
        case .liverpool: "Liverpool F.C."
        case .manchesterCity: "Manchester City F.C."
        case .manchesterUnited: "Manchester United F.C."
        case .tottenham: "Tottenham Hotspur F.C."
        case .barcelona: "FC Barcelona"
        case .interMiami: "Inter Miami CF"
        case .lafc: "Los Angeles FC"
        case .newYorkRedBulls: "New York Red Bulls"
        default: displayName
        }
    }

    static func teams(in league: TeamLeague) -> [FavoriteTeam] {
        allCases.filter { $0.league == league }
    }

    private static let premierLeagueTeams: Set<FavoriteTeam> = [
        .arsenal, .astonVilla, .bournemouth, .brentford, .brighton, .chelsea,
        .coventryCity, .crystalPalace, .everton, .fulham, .hullCity, .ipswichTown,
        .leedsUnited, .liverpool, .manchesterCity, .manchesterUnited, .newcastleUnited,
        .nottinghamForest, .sunderland, .tottenham,
    ]

    private static let laLigaTeams: Set<FavoriteTeam> = [
        .athleticClub, .atleticoMadrid, .osasuna, .celtaVigo, .alaves, .elche,
        .barcelona, .getafe, .levante, .malaga, .racingSantander, .rayoVallecano,
        .deportivoLaCoruna, .espanyol, .realBetis, .realMadrid, .realSociedad,
        .sevilla, .valencia, .villarreal,
    ]

    private static let mlsTeams: Set<FavoriteTeam> = [
        .atlantaUnited, .austinFC, .charlotteFC, .chicagoFire, .cincinnati,
        .coloradoRapids, .columbusCrew, .dcUnited, .fcDallas, .houstonDynamo,
        .sportingKansasCity, .laGalaxy, .lafc, .interMiami, .minnesotaUnited,
        .cfMontreal, .nashville, .newEngland, .newYorkRedBulls, .nycfc,
        .orlandoCity, .philadelphiaUnion, .portlandTimbers, .realSaltLake,
        .sanDiegoFC, .sanJoseEarthquakes, .seattleSounders, .stLouisCity,
        .torontoFC, .vancouverWhitecaps,
    ]

    var primaryColor: Color {
        switch self {
        case .arsenal, .manchesterUnited:
            Color(red: 0.78, green: 0.04, blue: 0.10)
        case .barcelona:
            Color(red: 0.86, green: 0.02, blue: 0.10)
        case .chelsea, .parisSaintGermain:
            Color(red: 0.04, green: 0.22, blue: 0.58)
        case .realMadrid:
            Color(red: 0.24, green: 0.32, blue: 0.72)
        case .manchesterCity:
            Color(red: 0.18, green: 0.55, blue: 0.72)
        case .liverpool:
            Color(red: 0.76, green: 0.02, blue: 0.12)
        case .bayernMunich:
            Color(red: 0.82, green: 0.02, blue: 0.18)
        case .interMiami:
            Color(red: 0.95, green: 0.42, blue: 0.60)
        case .cincinnati:
            Color(red: 0.00, green: 0.19, blue: 0.53)
        default:
            switch league {
            case .premierLeague: Color(red: 0.22, green: 0.05, blue: 0.36)
            case .laLiga: Color(red: 0.86, green: 0.12, blue: 0.10)
            case .mls: Color(red: 0.05, green: 0.20, blue: 0.42)
            case .other: Color(red: 0.00, green: 0.55, blue: 0.30)
            }
        }
    }

    var highlightColor: Color {
        switch self {
        case .arsenal, .liverpool:
            .white
        case .barcelona, .parisSaintGermain, .bayernMunich:
            Color(red: 0.92, green: 0.08, blue: 0.18)
        case .realMadrid, .manchesterUnited:
            Color(red: 1.00, green: 0.76, blue: 0.20)
        case .manchesterCity, .chelsea:
            Color(red: 0.72, green: 0.88, blue: 1.00)
        case .interMiami:
            Color(red: 1.00, green: 0.72, blue: 0.82)
        case .cincinnati:
            Color(red: 1.00, green: 0.31, blue: 0.00)
        default:
            .white
        }
    }

    var surfaceColor: Color {
        self == .barcelona
            ? Color(red: 0.20, green: 0.015, blue: 0.025)
            : darkColor.opacity(0.82)
    }

    var darkColor: Color {
        switch self {
        case .arsenal, .manchesterUnited, .liverpool, .bayernMunich:
            Color(red: 0.14, green: 0.01, blue: 0.03)
        case .barcelona:
            Color(red: 0.015, green: 0.01, blue: 0.01)
        case .realMadrid, .manchesterCity, .chelsea, .parisSaintGermain:
            Color(red: 0.01, green: 0.04, blue: 0.13)
        case .interMiami:
            Color(red: 0.10, green: 0.03, blue: 0.07)
        case .cincinnati:
            Color(red: 0.02, green: 0.12, blue: 0.26)
        default:
            primaryColor.opacity(0.30)
        }
    }
}

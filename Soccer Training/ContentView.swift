//
//  ContentView.swift
//  Soccer Training
//
//  Created by Thomas Telintelo on 9/13/26.
//

import AVFoundation
import StoreKit
import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@Observable
@MainActor
final class RewardedAdManager: NSObject {
    private(set) var isReady = false
    private(set) var isLoading = false
    private(set) var statusMessage = "Preparing rewarded ad…"

    #if canImport(GoogleMobileAds)
    private var rewardedAd: RewardedAd?
    private let testAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    #endif

    func prepare() async {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start()
        await loadAd()
        #else
        statusMessage = "Add the Google Mobile Ads package in Xcode to enable rewarded ads."
        #endif
    }

    func showAd(onReward: @escaping @MainActor () -> Void) {
        #if canImport(GoogleMobileAds)
        guard let ad = rewardedAd, isReady else {
            statusMessage = "The ad is still loading."
            return
        }

        rewardedAd = nil
        isReady = false
        statusMessage = "Watch the full ad to earn your points."
        ad.present(from: nil) {
            onReward()
            self.statusMessage = "Reward earned! 50 points were added."
        }
        #else
        statusMessage = "Rewarded ads need the Google Mobile Ads package."
        #endif
    }

    #if canImport(GoogleMobileAds)
    private func loadAd() async {
        guard !isLoading else { return }
        isLoading = true
        statusMessage = "Loading rewarded ad…"

        do {
            let ad = try await RewardedAd.load(with: testAdUnitID, request: Request())
            rewardedAd = ad
            rewardedAd?.fullScreenContentDelegate = self
            isReady = true
            statusMessage = "Watch an ad to earn 50 points."
        } catch {
            statusMessage = "No ad is available right now. Try again later."
        }

        isLoading = false
    }
    #endif
}

#if canImport(GoogleMobileAds)
extension RewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { await loadAd() }
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        statusMessage = "The ad could not be shown. Try again."
        Task { await loadAd() }
    }
}
#endif

@Observable
@MainActor
final class PlusSubscriptionManager {
    static let productID = "com.thomastelintelo.soccertraining.plus.monthly"

    private(set) var product: Product?
    private(set) var isPurchasing = false
    private(set) var statusMessage = "Loading Plus subscription…"

    var monthlyPriceText: String {
        product.map { "\($0.displayPrice)/month" } ?? "$9.99/month"
    }

    func prepare() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
            statusMessage = product == nil
                ? "Plus must be configured in App Store Connect."
                : "Unlock all Plus benefits for \(monthlyPriceText)."
        } catch {
            statusMessage = "Plus pricing is unavailable right now."
        }

        await refreshEntitlement()
    }

    func purchase() async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                UserDefaults.standard.set(true, forKey: "isProMember")
                statusMessage = "Plus is active."
                await transaction.finish()
            case .pending:
                statusMessage = "The purchase is waiting for approval."
            case .userCancelled:
                statusMessage = "The purchase was cancelled."
            @unknown default:
                statusMessage = "The purchase did not finish."
            }
        } catch {
            statusMessage = "The purchase could not be completed."
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlement()
        } catch {
            statusMessage = "Purchases could not be restored."
        }
    }

    func refreshEntitlement() async {
        var hasActivePlus = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productID == Self.productID else { continue }
            guard transaction.revocationDate == nil else { continue }

            if transaction.expirationDate.map({ $0 > Date() }) ?? true {
                hasActivePlus = true
            }
        }

        UserDefaults.standard.set(hasActivePlus, forKey: "isProMember")
        if hasActivePlus {
            statusMessage = "Plus is active."
        }
    }

    private func checkVerified<T>(
        _ result: VerificationResult<T>
    ) throws -> T {
        switch result {
        case .verified(let value):
            value
        case .unverified:
            throw StoreError.failedVerification
        }
    }

    private enum StoreError: Error {
        case failedVerification
    }
}

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

private struct ClubCrestView: View {
    let team: FavoriteTeam
    let size: CGFloat
    @State private var crestURL: URL?

    var body: some View {
        Group {
            if let crestURL {
                AsyncImage(url: crestURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .task(id: team.id) {
            crestURL = await loadCrestURL()
        }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Image(systemName: "shield.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(team.primaryColor)
    }

    private func loadCrestURL() async -> URL? {
        guard let title = team.wikipediaTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(title)")
        else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("SoccerTrainingApp/1.0", forHTTPHeaderField: "User-Agent")

        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            return nil
        }

        return try? JSONDecoder().decode(WikipediaPlayerSummary.self, from: data).thumbnail?.source
    }
}

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

struct Drill: Identifiable {
    let id = UUID()
    let name: String
}

struct Topic: Identifiable {
    let id = UUID()
    let name: String
    let drills: [Drill]
}

struct ScheduleItem: Identifiable {
    let id: Int
    let focus: String
    let drillName: String
}

struct ScheduleDay: Identifiable {
    let day: String
    let drills: [ScheduleItem]

    var id: String {
        day
    }
}

enum PassTurnDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var calloutInterval: TimeInterval {
        switch self {
        case .easy:
            12
        case .medium:
            8
        case .hard:
            5
        }
    }

    var reward: Int {
        switch self {
        case .easy:
            0
        case .medium:
            10
        case .hard:
            20
        }
    }

    var durationMultiplier: Double {
        switch self {
        case .easy: 0.7
        case .medium: 1
        case .hard: 1.3
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let id: String
    let name: String
    let score: Int
}

struct SoccerPlayer: Identifiable {
    let id: String
    let name: String
    let position: String
    let overall: Int
    let cost: Int
    let weeklyStock: Int
}

enum PlayerRating {
    static let haaland = 97
}

enum PlayerCatalog {
    static let players = [
        SoccerPlayer(id: "ronaldo", name: "Cristiano Ronaldo", position: "ST", overall: 99, cost: 12_000, weeklyStock: 1),
        SoccerPlayer(id: "messi", name: "Lionel Messi", position: "RM", overall: 99, cost: 12_000, weeklyStock: 1),
        SoccerPlayer(id: "pele", name: "Pelé", position: "ST", overall: 99, cost: 12_000, weeklyStock: 1),
        SoccerPlayer(id: "ronaldo_nazario", name: "Ronaldo Nazário", position: "ST", overall: 98, cost: 10_000, weeklyStock: 1),
        SoccerPlayer(id: "maradona", name: "Diego Maradona", position: "CM", overall: 98, cost: 10_000, weeklyStock: 1),
        SoccerPlayer(id: "mbappe", name: "Kylian Mbappé", position: "ST", overall: 98, cost: 9_000, weeklyStock: 1),
        SoccerPlayer(id: "haaland", name: "Erling Haaland", position: "ST", overall: PlayerRating.haaland, cost: 8_000, weeklyStock: 1),
        SoccerPlayer(id: "neymar", name: "Neymar Jr", position: "LM", overall: 97, cost: 8_000, weeklyStock: 1),
        SoccerPlayer(id: "van_dijk", name: "Virgil van Dijk", position: "CB", overall: 93, cost: 6_000, weeklyStock: 1),
        SoccerPlayer(id: "vinicius", name: "Vinícius Júnior", position: "LM", overall: 97, cost: 8_000, weeklyStock: 1),
        SoccerPlayer(id: "bellingham", name: "Jude Bellingham", position: "CM", overall: 96, cost: 7_000, weeklyStock: 1),
        SoccerPlayer(id: "kane", name: "Harry Kane", position: "ST", overall: 93, cost: 5_500, weeklyStock: 1),
        SoccerPlayer(id: "martinez_gk", name: "Emiliano Martínez", position: "GK", overall: 90, cost: 2_000, weeklyStock: 1),
        SoccerPlayer(id: "alisson", name: "Alisson Becker", position: "GK", overall: 91, cost: 2_500, weeklyStock: 1),
        SoccerPlayer(id: "neuer", name: "Manuel Neuer", position: "GK", overall: 90, cost: 2_200, weeklyStock: 1),
        SoccerPlayer(id: "salah", name: "Mohamed Salah", position: "RM", overall: 94, cost: 5_500, weeklyStock: 1),
        SoccerPlayer(id: "maignan", name: "Mike Maignan", position: "GK", overall: 89, cost: 1_100, weeklyStock: 2),
        SoccerPlayer(id: "raya", name: "David Raya", position: "GK", overall: 85, cost: 650, weeklyStock: 4),
        SoccerPlayer(id: "costa", name: "Diogo Costa", position: "GK", overall: 82, cost: 400, weeklyStock: 6),
        SoccerPlayer(id: "hernandez", name: "Theo Hernández", position: "LB", overall: 87, cost: 850, weeklyStock: 3),
        SoccerPlayer(id: "davies", name: "Alphonso Davies", position: "LB", overall: 84, cost: 550, weeklyStock: 5),
        SoccerPlayer(id: "saliba", name: "William Saliba", position: "CB", overall: 88, cost: 950, weeklyStock: 2),
        SoccerPlayer(id: "araujo", name: "Ronald Araújo", position: "CB", overall: 86, cost: 700, weeklyStock: 3),
        SoccerPlayer(id: "bastoni", name: "Alessandro Bastoni", position: "CB", overall: 85, cost: 600, weeklyStock: 4),
        SoccerPlayer(id: "hakimi", name: "Achraf Hakimi", position: "RB", overall: 88, cost: 950, weeklyStock: 2),
        SoccerPlayer(id: "frimpong", name: "Jeremie Frimpong", position: "RB", overall: 84, cost: 500, weeklyStock: 5),
        SoccerPlayer(id: "rodri", name: "Rodri", position: "CM", overall: 95, cost: 1_300, weeklyStock: 1),
        SoccerPlayer(id: "pedri", name: "Pedri", position: "CM", overall: 88, cost: 900, weeklyStock: 2),
        SoccerPlayer(id: "valverde", name: "Federico Valverde", position: "CM", overall: 88, cost: 900, weeklyStock: 2),
        SoccerPlayer(id: "macallister", name: "Alexis Mac Allister", position: "CM", overall: 86, cost: 650, weeklyStock: 4),
        SoccerPlayer(id: "leao", name: "Rafael Leão", position: "LM", overall: 87, cost: 800, weeklyStock: 3),
        SoccerPlayer(id: "mitoma", name: "Kaoru Mitoma", position: "LM", overall: 83, cost: 450, weeklyStock: 5),
        SoccerPlayer(id: "yamal", name: "Lamine Yamal", position: "RM", overall: 97, cost: 8_000, weeklyStock: 1),
        SoccerPlayer(id: "saka", name: "Bukayo Saka", position: "RM", overall: 93, cost: 1_050, weeklyStock: 2),
        SoccerPlayer(id: "olise", name: "Michael Olise", position: "RM", overall: 91, cost: 500, weeklyStock: 5),
        SoccerPlayer(id: "osimhen", name: "Victor Osimhen", position: "ST", overall: 88, cost: 950, weeklyStock: 2),
        SoccerPlayer(id: "isak", name: "Alexander Isak", position: "ST", overall: 87, cost: 800, weeklyStock: 3),
        SoccerPlayer(id: "watkins", name: "Ollie Watkins", position: "ST", overall: 84, cost: 500, weeklyStock: 5),
        SoccerPlayer(id: "courtois", name: "Thibaut Courtois", position: "GK", overall: 89, cost: 1_200, weeklyStock: 2),
        SoccerPlayer(id: "grimaldo", name: "Álex Grimaldo", position: "LB", overall: 86, cost: 700, weeklyStock: 3),
        SoccerPlayer(id: "ruben_dias", name: "Rúben Dias", position: "CB", overall: 89, cost: 1_200, weeklyStock: 2),
        SoccerPlayer(id: "kounde", name: "Jules Koundé", position: "CB", overall: 87, cost: 850, weeklyStock: 3),
        SoccerPlayer(id: "alexander_arnold", name: "Trent Alexander-Arnold", position: "RB", overall: 88, cost: 1_000, weeklyStock: 2),
        SoccerPlayer(id: "rice", name: "Declan Rice", position: "CM", overall: 91, cost: 3_000, weeklyStock: 1),
        SoccerPlayer(id: "de_bruyne", name: "Kevin De Bruyne", position: "CM", overall: 92, cost: 4_000, weeklyStock: 1),
        SoccerPlayer(id: "palmer", name: "Cole Palmer", position: "RM", overall: 92, cost: 4_000, weeklyStock: 1),
        SoccerPlayer(id: "musiala", name: "Jamal Musiala", position: "LM", overall: 92, cost: 4_000, weeklyStock: 1),
        SoccerPlayer(id: "kvaratskhelia", name: "Khvicha Kvaratskhelia", position: "LM", overall: 90, cost: 2_500, weeklyStock: 1),
        SoccerPlayer(id: "lautaro", name: "Lautaro Martínez", position: "ST", overall: 89, cost: 1_200, weeklyStock: 2),
        SoccerPlayer(id: "gyokeres", name: "Viktor Gyökeres", position: "ST", overall: 88, cost: 1_000, weeklyStock: 2),

        // Affordable real players make it possible to build a full team early.
        SoccerPlayer(id: "kelleher", name: "Caoimhín Kelleher", position: "GK", overall: 76, cost: 200, weeklyStock: 8),
        SoccerPlayer(id: "mamardashvili", name: "Giorgi Mamardashvili", position: "GK", overall: 67, cost: 90, weeklyStock: 12),
        SoccerPlayer(id: "verbruggen", name: "Bart Verbruggen", position: "GK", overall: 56, cost: 25, weeklyStock: 15),
        SoccerPlayer(id: "udogie", name: "Destiny Udogie", position: "LB", overall: 77, cost: 220, weeklyStock: 8),
        SoccerPlayer(id: "kerkez", name: "Miloš Kerkez", position: "LB", overall: 68, cost: 100, weeklyStock: 12),
        SoccerPlayer(id: "dorgu", name: "Patrick Dorgu", position: "LB", overall: 57, cost: 30, weeklyStock: 15),
        SoccerPlayer(id: "branthwaite", name: "Jarrad Branthwaite", position: "CB", overall: 78, cost: 250, weeklyStock: 8),
        SoccerPlayer(id: "colwill", name: "Levi Colwill", position: "CB", overall: 72, cost: 150, weeklyStock: 10),
        SoccerPlayer(id: "murillo", name: "Murillo", position: "CB", overall: 66, cost: 85, weeklyStock: 12),
        SoccerPlayer(id: "huijsen", name: "Dean Huijsen", position: "CB", overall: 61, cost: 55, weeklyStock: 14),
        SoccerPlayer(id: "lacroix", name: "Maxence Lacroix", position: "CB", overall: 55, cost: 25, weeklyStock: 15),
        SoccerPlayer(id: "livramento", name: "Tino Livramento", position: "RB", overall: 76, cost: 200, weeklyStock: 8),
        SoccerPlayer(id: "gusto", name: "Malo Gusto", position: "RB", overall: 67, cost: 90, weeklyStock: 12),
        SoccerPlayer(id: "vanderson", name: "Vanderson", position: "RB", overall: 58, cost: 35, weeklyStock: 15),
        SoccerPlayer(id: "neves", name: "João Neves", position: "CM", overall: 78, cost: 250, weeklyStock: 8),
        SoccerPlayer(id: "mainoo", name: "Kobbie Mainoo", position: "CM", overall: 73, cost: 160, weeklyStock: 10),
        SoccerPlayer(id: "wharton", name: "Adam Wharton", position: "CM", overall: 68, cost: 100, weeklyStock: 12),
        SoccerPlayer(id: "zaire_emery", name: "Warren Zaïre-Emery", position: "CM", overall: 62, cost: 60, weeklyStock: 14),
        SoccerPlayer(id: "gray", name: "Archie Gray", position: "CM", overall: 56, cost: 25, weeklyStock: 15),
        SoccerPlayer(id: "gordon", name: "Anthony Gordon", position: "LM", overall: 77, cost: 220, weeklyStock: 8),
        SoccerPlayer(id: "gittens", name: "Jamie Gittens", position: "LM", overall: 67, cost: 90, weeklyStock: 12),
        SoccerPlayer(id: "garnacho", name: "Alejandro Garnacho", position: "LM", overall: 57, cost: 30, weeklyStock: 15),
        SoccerPlayer(id: "savinho", name: "Savinho", position: "RM", overall: 76, cost: 200, weeklyStock: 8),
        SoccerPlayer(id: "madueke", name: "Noni Madueke", position: "RM", overall: 66, cost: 85, weeklyStock: 12),
        SoccerPlayer(id: "minteh", name: "Yankuba Minteh", position: "RM", overall: 55, cost: 25, weeklyStock: 15),
        SoccerPlayer(id: "sesko", name: "Benjamin Šeško", position: "ST", overall: 78, cost: 250, weeklyStock: 8),
        SoccerPlayer(id: "hojlund", name: "Rasmus Højlund", position: "ST", overall: 72, cost: 150, weeklyStock: 10),
        SoccerPlayer(id: "delap", name: "Liam Delap", position: "ST", overall: 66, cost: 85, weeklyStock: 12),
        SoccerPlayer(id: "ferguson", name: "Evan Ferguson", position: "ST", overall: 61, cost: 55, weeklyStock: 14),
        SoccerPlayer(id: "tel", name: "Mathys Tel", position: "ST", overall: 55, cost: 25, weeklyStock: 15),
    ]
}

struct RarePlayerOffer: Identifiable {
    let player: SoccerPlayer
    let price: String
    let tier: String

    var id: String { player.id }
}

enum RarePlayerCatalog {
    static let offers = [
        RarePlayerOffer(
            player: SoccerPlayer(id: "ronaldo", name: "Cristiano Ronaldo", position: "ST", overall: 99, cost: 0, weeklyStock: 0),
            price: "$14.99",
            tier: "GOAT"
        ),
        RarePlayerOffer(
            player: SoccerPlayer(id: "messi", name: "Lionel Messi", position: "RM", overall: 99, cost: 0, weeklyStock: 0),
            price: "$14.99",
            tier: "GOAT"
        ),
        RarePlayerOffer(
            player: SoccerPlayer(id: "vinicius", name: "Vinícius Júnior", position: "LM", overall: 97, cost: 0, weeklyStock: 0),
            price: "$9.99",
            tier: "Elite"
        ),
        RarePlayerOffer(
            player: SoccerPlayer(id: "mbappe", name: "Kylian Mbappé", position: "ST", overall: 98, cost: 0, weeklyStock: 0),
            price: "$9.99",
            tier: "Elite"
        ),
        RarePlayerOffer(
            player: SoccerPlayer(id: "haaland", name: "Erling Haaland", position: "ST", overall: PlayerRating.haaland, cost: 0, weeklyStock: 0),
            price: "$9.99",
            tier: "Elite"
        ),
        RarePlayerOffer(
            player: SoccerPlayer(id: "bellingham", name: "Jude Bellingham", position: "CM", overall: 96, cost: 0, weeklyStock: 0),
            price: "$7.99",
            tier: "Elite"
        ),
        RarePlayerOffer(
            player: SoccerPlayer(id: "yamal", name: "Lamine Yamal", position: "RM", overall: 97, cost: 0, weeklyStock: 0),
            price: "$7.99",
            tier: "Wonderkid"
        ),
    ]
}

struct PointsPack: Identifiable {
    let id: String
    let points: Int
    let price: String
}

enum CashStoreCatalog {
    static let pointsPacks = [
        PointsPack(id: "points500", points: 500, price: "$1.99"),
        PointsPack(id: "points1500", points: 1_500, price: "$4.99"),
        PointsPack(id: "points5000", points: 5_000, price: "$9.99"),
    ]

    static let players = [
        RarePlayerOffer(player: SoccerPlayer(id: "eze", name: "Eberechi Eze", position: "CM", overall: 88, cost: 0, weeklyStock: 0), price: "$5.99", tier: "Quality"),
        RarePlayerOffer(player: SoccerPlayer(id: "bowen", name: "Jarrod Bowen", position: "RM", overall: 87, cost: 0, weeklyStock: 0), price: "$5.99", tier: "Quality"),
        RarePlayerOffer(player: SoccerPlayer(id: "mbeumo", name: "Bryan Mbeumo", position: "RM", overall: 86, cost: 0, weeklyStock: 0), price: "$4.99", tier: "Solid"),
        RarePlayerOffer(player: SoccerPlayer(id: "solanke", name: "Dominic Solanke", position: "ST", overall: 86, cost: 0, weeklyStock: 0), price: "$4.99", tier: "Solid"),
        RarePlayerOffer(player: SoccerPlayer(id: "gibbs_white", name: "Morgan Gibbs-White", position: "CM", overall: 86, cost: 0, weeklyStock: 0), price: "$4.99", tier: "Solid"),
        RarePlayerOffer(player: SoccerPlayer(id: "guehi", name: "Marc Guéhi", position: "CB", overall: 86, cost: 0, weeklyStock: 0), price: "$4.99", tier: "Solid"),
        RarePlayerOffer(player: SoccerPlayer(id: "onana", name: "André Onana", position: "GK", overall: 85, cost: 0, weeklyStock: 0), price: "$4.99", tier: "Solid"),
        RarePlayerOffer(player: SoccerPlayer(id: "haaland", name: "Erling Haaland", position: "ST", overall: PlayerRating.haaland, cost: 0, weeklyStock: 0), price: "$9.99", tier: "Superstar"),
        RarePlayerOffer(player: SoccerPlayer(id: "mbappe", name: "Kylian Mbappé", position: "ST", overall: 98, cost: 0, weeklyStock: 0), price: "$9.99", tier: "Superstar"),
        RarePlayerOffer(player: SoccerPlayer(id: "salah", name: "Mohamed Salah", position: "RW", overall: 94, cost: 0, weeklyStock: 0), price: "$7.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "kane", name: "Harry Kane", position: "ST", overall: 93, cost: 0, weeklyStock: 0), price: "$7.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "de_bruyne", name: "Kevin De Bruyne", position: "CM", overall: 92, cost: 0, weeklyStock: 0), price: "$6.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "van_dijk", name: "Virgil van Dijk", position: "CB", overall: 93, cost: 0, weeklyStock: 0), price: "$7.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "lewandowski", name: "Robert Lewandowski", position: "ST", overall: 92, cost: 0, weeklyStock: 0), price: "$6.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "vinicius", name: "Vinícius Júnior", position: "LW", overall: 97, cost: 0, weeklyStock: 0), price: "$9.99", tier: "Superstar"),
        RarePlayerOffer(player: SoccerPlayer(id: "rodri", name: "Rodri", position: "CM", overall: 96, cost: 0, weeklyStock: 0), price: "$9.99", tier: "Superstar"),
        RarePlayerOffer(player: SoccerPlayer(id: "saka", name: "Bukayo Saka", position: "RW", overall: 93, cost: 0, weeklyStock: 0), price: "$7.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "palmer", name: "Cole Palmer", position: "CAM", overall: 92, cost: 0, weeklyStock: 0), price: "$7.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "musiala", name: "Jamal Musiala", position: "CAM", overall: 92, cost: 0, weeklyStock: 0), price: "$7.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "wirtz", name: "Florian Wirtz", position: "CAM", overall: 91, cost: 0, weeklyStock: 0), price: "$6.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "olise", name: "Michael Olise", position: "RW", overall: 91, cost: 0, weeklyStock: 0), price: "$6.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "luis_diaz", name: "Luis Díaz", position: "LW", overall: 89, cost: 0, weeklyStock: 0), price: "$5.99", tier: "Quality"),
        RarePlayerOffer(player: SoccerPlayer(id: "bruno_guimaraes", name: "Bruno Guimarães", position: "CM", overall: 89, cost: 0, weeklyStock: 0), price: "$5.99", tier: "Quality"),
        RarePlayerOffer(player: SoccerPlayer(id: "martinelli", name: "Gabriel Martinelli", position: "LW", overall: 88, cost: 0, weeklyStock: 0), price: "$4.99", tier: "Quality"),
        RarePlayerOffer(player: SoccerPlayer(id: "rice", name: "Declan Rice", position: "CM", overall: 91, cost: 0, weeklyStock: 0), price: "$6.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "donnarumma", name: "Gianluigi Donnarumma", position: "GK", overall: 90, cost: 0, weeklyStock: 0), price: "$6.99", tier: "Elite"),
        RarePlayerOffer(player: SoccerPlayer(id: "kvaratskhelia", name: "Khvicha Kvaratskhelia", position: "LW", overall: 90, cost: 0, weeklyStock: 0), price: "$6.99", tier: "Elite"),
    ]
}

struct ContentView: View {
    @AppStorage("totalPoints") private var totalPoints = 0
    @AppStorage("playerUsername") private var playerUsername = ""
    @AppStorage("playerPosition") private var playerPosition = ""
    @AppStorage("playerBestSkill") private var playerBestSkill = ""
    @AppStorage("favoriteTeam") private var favoriteTeam = ""

    let topics = [
        Topic(name: "Shooting", drills: [
            Drill(name: "Practice Shooting"), Drill(name: "Quick Shot"), Drill(name: "Dribble and Shoot"),
            Drill(name: "First Touch Finish"), Drill(name: "Target Corners"), Drill(name: "Power Shots"),
            Drill(name: "Weak Foot Finishing"), Drill(name: "Turn and Shoot"), Drill(name: "Volley Finish"),
            Drill(name: "Near Post Finish"), Drill(name: "Cutback Finish"),
            Drill(name: "Far Post Finish"), Drill(name: "Low Driven Finish"),
            Drill(name: "Rebound Finish"), Drill(name: "One Touch Finish"),
        ]),
        Topic(name: "Dribbling", drills: [
            Drill(name: "Cone Weave"), Drill(name: "Speed Dribble"), Drill(name: "Box Dribble"),
            Drill(name: "L-Drag Turn"), Drill(name: "Stop and Go"), Drill(name: "Pullback Turn"),
            Drill(name: "Figure Eight"), Drill(name: "Zigzag Sprint"), Drill(name: "Scissors Move"),
            Drill(name: "Change of Pace"), Drill(name: "Shield and Turn"), Drill(name: "Cruyff Turn"),
            Drill(name: "V-Cut Dribble"), Drill(name: "Double Touch"),
            Drill(name: "Body Feint"), Drill(name: "Step Over Exit"),
            Drill(name: "Drag Push"), Drill(name: "Slalom Control"),
        ]),
        Topic(name: "Passing", drills: [
            Drill(name: "Wall Passing"), Drill(name: "One Touch Passing"), Drill(name: "Weak Foot Passing"),
            Drill(name: "Pass and Turn"), Drill(name: "Long Passing"),
            Drill(name: "Two Touch Passing"), Drill(name: "Driven Wall Pass"),
            Drill(name: "Triangle Passing"), Drill(name: "Outside Foot Pass"),
            Drill(name: "Give and Go"), Drill(name: "Passing Gates"),
            Drill(name: "First Time Pass"), Drill(name: "Lofted Pass"),
        ]),
        Topic(name: "Control", drills: [
            Drill(name: "Juggling"), Drill(name: "Wall Control"), Drill(name: "Inside-Outside Touches"),
            Drill(name: "Sole Roll and Push"), Drill(name: "Aerial Control"), Drill(name: "First Touch Gates"),
            Drill(name: "Thigh Control"), Drill(name: "Chest Control"), Drill(name: "Cushion Touch"),
            Drill(name: "Outside Foot Control"), Drill(name: "Bounce Control"), Drill(name: "Half Turn Control"),
            Drill(name: "Directional First Touch"), Drill(name: "Sole Cushion"),
            Drill(name: "High Ball Settle"), Drill(name: "Turn on First Touch"),
        ]),
        Topic(name: "Indoor Training", drills: [
            Drill(name: "Ball Mastery"), Drill(name: "Toe Tap Challenge"),
            Drill(name: "Sole Roll Circuit"), Drill(name: "Tight Space Turns"),
            Drill(name: "Indoor Wall Passing"), Drill(name: "Foundation Touches"), Drill(name: "Small Space Weave"),
            Drill(name: "Box Ball Mastery"), Drill(name: "Sole Tap Rhythm"),
            Drill(name: "Indoor Figure Eight"), Drill(name: "Wall Touch Challenge"),
        ]),
        Topic(name: "Goalkeeping", drills: [
            Drill(name: "Set Position Saves"), Drill(name: "Low Diving Saves"), Drill(name: "Goalkeeper Footwork"),
            Drill(name: "Angle Positioning"), Drill(name: "Throw Distribution"), Drill(name: "Cross Collection"),
            Drill(name: "Reaction Saves"), Drill(name: "1v1 Goalkeeper"), Drill(name: "High Ball Catch"),
            Drill(name: "Scoop Saves"), Drill(name: "Quick Hands"),
            Drill(name: "Near Post Saves"), Drill(name: "Collapse Dive"),
            Drill(name: "Foot Saves"), Drill(name: "Distribution Accuracy"),
        ]),
        Topic(name: "Defense", drills: [
            Drill(name: "Jockeying"), Drill(name: "Defensive Shuffle"), Drill(name: "Close Down"),
            Drill(name: "Recovery Run"), Drill(name: "Block and Clear"),
            Drill(name: "1v1 Shadow"), Drill(name: "Backpedal and Turn"),
            Drill(name: "Interception Steps"), Drill(name: "Clear and Recover"),
            Drill(name: "Delay the Attacker"), Drill(name: "Cover Shadow"),
            Drill(name: "Tackle Timing"), Drill(name: "Wide Channel Defense"),
        ]),
        Topic(name: "Plus Training", drills: [
            Drill(name: "Elite Finishing Circuit"), Drill(name: "Pressure Passing"),
            Drill(name: "Advanced Ball Mastery"), Drill(name: "Explosive Dribble"),
            Drill(name: "First Touch Under Pressure"), Drill(name: "Match Speed Control"),
            Drill(name: "Complete Midfielder Circuit"), Drill(name: "Striker Movement Circuit"),
            Drill(name: "Crossbar Challenge"), Drill(name: "Around the World"),
            Drill(name: "Beat the Cone"), Drill(name: "Weak Foot Hero"),
            Drill(name: "Skill Move Combo"), Drill(name: "Rapid Fire Finishing"),
            Drill(name: "Perfect Pass Streak"), Drill(name: "Juggling Ladder"),
        ]),
        Topic(name: "Workout", drills: [
            Drill(name: "Running"), Drill(name: "Abs Circuit"), Drill(name: "Arm Strength"),
            Drill(name: "Leg Strength"), Drill(name: "Chest Workout"), Drill(name: "Full Body Workout"),
            Drill(name: "Agility Sprints"), Drill(name: "Recovery Stretch"), Drill(name: "Shuttle Runs"),
            Drill(name: "Balance Circuit"), Drill(name: "Quick Feet"),
            Drill(name: "Core Stability"), Drill(name: "Lateral Hops"),
            Drill(name: "Single Leg Strength"), Drill(name: "Mobility Flow"),
        ]),
    ]

    private var schedule: [ScheduleDay] {
        let positionPriorities: [String]

        switch playerPosition {
        case "Goalkeeper":
            positionPriorities = ["Goalkeeping", "Control", "Passing", "Defense"]
        case "Defender":
            positionPriorities = ["Defense", "Passing", "Control", "Dribbling"]
        case "Midfielder":
            positionPriorities = ["Passing", "Control", "Dribbling", "Shooting"]
        case "Winger":
            positionPriorities = ["Dribbling", "Shooting", "Control", "Passing"]
        case "Striker":
            positionPriorities = ["Shooting", "Control", "Dribbling", "Passing"]
        default:
            positionPriorities = ["Control", "Passing", "Dribbling", "Shooting"]
        }

        let developmentSkills = positionPriorities.filter {
            playerBestSkill.isEmpty || $0 != playerBestSkill
        }
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        return days.enumerated().map { dayIndex, day in
            var dailyFocuses = (0..<4).map { offset in
                developmentSkills[(dayIndex + offset) % developmentSkills.count]
            }

            if positionPriorities.contains(playerBestSkill) && (dayIndex == 2 || dayIndex == 4) {
                dailyFocuses[2] = playerBestSkill
            }
            dailyFocuses.append("Workout")

            let drills = dailyFocuses.enumerated().map { drillIndex, focus in
                let scheduleIndex = (dayIndex * 5) + drillIndex
                return ScheduleItem(
                    id: scheduleIndex,
                    focus: focus,
                    drillName: drillName(for: focus, index: scheduleIndex)
                )
            }

            return ScheduleDay(day: day, drills: drills)
        }
    }

    private func drillName(for focus: String, index: Int) -> String {
        guard let drills = topics.first(where: { $0.name == focus })?.drills, !drills.isEmpty else {
            return "Juggling"
        }
        return drills[index % drills.count].name
    }

    var body: some View {
        TabView {
            NavigationStack {
                HomeDashboardView(
                    username: playerUsername,
                    position: playerPosition,
                    bestSkill: playerBestSkill,
                    schedule: schedule,
                    totalPoints: $totalPoints
                )
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                AllDrillsView(topics: topics, totalPoints: $totalPoints)
            }
            .tabItem {
                Label("Drills", systemImage: "figure.soccer")
            }

            NavigationStack {
                PlayerShopView(totalPoints: $totalPoints)
            }
            .tabItem {
                Label("Player Shop", systemImage: "cart.fill")
            }

            NavigationStack {
                RarePlayerStoreView()
            }
            .tabItem {
                Label("Store", systemImage: "sparkles")
            }

            NavigationStack {
                ProfileView(
                    username: playerUsername,
                    position: playerPosition,
                    bestSkill: playerBestSkill,
                    totalPoints: $totalPoints
                )
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
        }
        .id(favoriteTeam)
        .tint(FavoriteTeam(rawValue: favoriteTeam)?.highlightColor ?? .soccerLime)

    }
}

struct HomeDashboardView: View {
    let username: String
    let position: String
    let bestSkill: String
    let schedule: [ScheduleDay]
    @Binding var totalPoints: Int
    @AppStorage("completedWeeklyTasks") private var completedWeeklyTasks = ""
    @AppStorage("completedWeeklyDays") private var completedWeeklyDays = ""
    @AppStorage("weeklyProgressStart") private var weeklyProgressStart = 0.0
    @AppStorage("favoriteTeam") private var favoriteTeam = ""
    @AppStorage("weeklyDrillSubstitutions") private var substitutionText = ""
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0

    private var completedTaskIDs: Set<String> {
        Set(completedWeeklyTasks.split(separator: "|").map(String.init))
    }

    private var substitutions: [String: String] {
        Dictionary(
            uniqueKeysWithValues: substitutionText.split(separator: "|").compactMap { entry in
                let parts = entry.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                return (String(parts[0]), String(parts[1]))
            }
        )
    }

    private var todayName: String? {
        switch Calendar.current.component(.weekday, from: Date()) {
        case 2: "Monday"
        case 3: "Tuesday"
        case 4: "Wednesday"
        case 5: "Thursday"
        case 6: "Friday"
        case 7: "Saturday"
        case 1: "Sunday"
        default: nil
        }
    }

    private var dailyChallengeDrill: Drill {
        let choices = [
            "Ball Mastery", "Wall Passing", "Cone Weave", "Juggling",
            "Toe Tap Challenge", "Quick Shot", "Tight Space Turns",
        ]
        let dayNumber = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return Drill(name: choices[dayNumber % choices.count])
    }

    private var dailyChallengeID: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        return "daily-\(formatter.string(from: Date()))"
    }

    private var isDailyChallengeCompleted: Bool {
        completedTaskIDs.contains(dailyChallengeID)
    }

    private func displayedDrillName(for item: ScheduleItem, taskID: String) -> String {
        substitutions[taskID] ?? item.drillName
    }

    private func dashboardStat(
        title: LocalizedStringKey,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.soccerLime)
            Text(value)
                .font(.headline)
                .fontWeight(.heavy)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.soccerCream.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func substituteDrill(for item: ScheduleItem, taskID: String) {
        let replacement: String

        switch item.focus {
        case "Shooting":
            replacement = "Practice Shooting"
        case "Dribbling":
            replacement = "Inside-Outside Touches"
        case "Passing":
            replacement = "Wall Passing"
        case "Control":
            replacement = "Juggling"
        case "Goalkeeping":
            replacement = "Goalkeeper Footwork"
        case "Defense":
            replacement = "Jockeying"
        default:
            replacement = "Running"
        }

        var updatedSubstitutions = substitutions
        updatedSubstitutions[taskID] = replacement == item.drillName ? "Running" : replacement
        substitutionText = updatedSubstitutions
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: "|")
    }

    var body: some View {
        ZStack {
            Color.soccerNavy
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("PRO TRAINING", systemImage: "figure.soccer")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundStyle(Color.soccerNavy)

                            Spacer()

                            Text("NEW")
                                .font(.caption)
                                .fontWeight(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.soccerNavy, in: Capsule())
                        }

                        Text("Train with purpose.")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.soccerNavy)

                        Text("Longer sessions, coaching tips, equipment lists, and bigger rewards are ready in the Drills tab.")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.soccerNavy.opacity(0.78))

                        HStack(spacing: 10) {
                            Label("\(totalTrainingMinutes) min trained", systemImage: "timer")
                            Label("More points", systemImage: "star.fill")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.soccerNavy)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color.soccerLime, Color.soccerGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 24)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.55), lineWidth: 2)
                    }

                    if let team = FavoriteTeam(rawValue: favoriteTeam) {
                        HStack(spacing: 14) {
                            ClubCrestView(team: team, size: 58)
                            Text(team.displayName)
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .minimumScaleFactor(0.65)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 34)
                            .background {
                                LinearGradient(
                                    colors: [team.primaryColor, team.darkColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                            .clipShape(.rect(cornerRadius: 22))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(team.highlightColor, lineWidth: 3)
                            }
                    }

                    Text("Points: \(totalPoints)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.soccerGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.soccerNavy.opacity(0.92))
                        .clipShape(.capsule)

                    Text("Welcome, \(username)!")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)

                    Text("\(position) • Best at \(bestSkill)")
                        .font(.headline)
                        .foregroundStyle(Color.soccerCream.opacity(0.78))

                    HStack(spacing: 12) {
                        dashboardStat(
                            title: "Points",
                            value: totalPoints.formatted(),
                            systemImage: "star.fill"
                        )
                        dashboardStat(
                            title: "Minutes",
                            value: totalTrainingMinutes.formatted(),
                            systemImage: "timer"
                        )
                        dashboardStat(
                            title: "Completed",
                            value: completedTaskIDs.count.formatted(),
                            systemImage: "checkmark.circle.fill"
                        )
                    }

                    NavigationLink {
                        ProfileView(
                            username: username,
                            position: position,
                            bestSkill: bestSkill,
                            totalPoints: $totalPoints
                        )
                    } label: {
                        Label("View Player Profile", systemImage: "person.crop.circle.fill")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.soccerSurface, in: RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Daily Challenge", systemImage: "calendar.badge.checkmark")
                                .font(.title2)
                                .fontWeight(.heavy)
                            Spacer()
                            Text(isDailyChallengeCompleted ? "DONE" : "+25 BONUS")
                                .font(.caption)
                                .fontWeight(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.soccerGold, in: Capsule())
                                .foregroundStyle(Color.soccerNavy)
                        }

                        Text(dailyChallengeDrill.name)
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("Complete today’s challenge to earn the normal drill reward plus 25 bonus points. A new challenge appears each day.")
                            .font(.subheadline)
                            .foregroundStyle(Color.soccerCream.opacity(0.75))

                        NavigationLink {
                            DrillTimerView(
                                drill: dailyChallengeDrill,
                                totalPoints: $totalPoints,
                                weeklyTaskID: dailyChallengeID,
                                weeklyDay: dailyChallengeID
                            )
                        } label: {
                            Label(
                                isDailyChallengeCompleted ? "Challenge Completed" : "Start Daily Challenge",
                                systemImage: isDailyChallengeCompleted ? "checkmark.circle.fill" : "play.fill"
                            )
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                isDailyChallengeCompleted ? Color.gray.opacity(0.45) : Color.soccerGreen,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .disabled(isDailyChallengeCompleted)
                    }
                    .padding()
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Today's training plan. Complete drills to build XP, stats, and training time.")
                            .font(.subheadline)
                            .foregroundStyle(Color.soccerCream.opacity(0.72))

                        ForEach(schedule.filter { $0.day == todayName }) { scheduleDay in
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(scheduleDay.drills) { item in
                                    let taskID = "\(scheduleDay.day)-\(item.id)"
                                    let isToday = scheduleDay.day == todayName
                                    let drillName = displayedDrillName(for: item, taskID: taskID)

                                    HStack(spacing: 8) {
                                        NavigationLink {
                                            DrillTimerView(
                                                drill: Drill(name: drillName),
                                                totalPoints: $totalPoints,
                                                weeklyTaskID: taskID,
                                                weeklyDay: scheduleDay.day
                                            )
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(drillName)
                                                        .font(.headline)
                                                        .fontWeight(.bold)
                                                    Text(isToday ? "Focus: \(item.focus)" : "Unlocks on \(scheduleDay.day)")
                                                        .font(.subheadline)
                                                }

                                                Spacer()

                                                Image(
                                                    systemName: completedTaskIDs.contains(taskID)
                                                        ? "checkmark.circle.fill"
                                                        : isToday ? "chevron.right" : "lock.fill"
                                                )
                                                .foregroundStyle(
                                                    completedTaskIDs.contains(taskID)
                                                        ? Color.soccerLime
                                                        : Color.soccerCream
                                                )
                                            }
                                            .contentShape(.rect)
                                        }
                                        .disabled(!isToday)

                                        Menu {
                                            Button {
                                                substituteDrill(for: item, taskID: taskID)
                                            } label: {
                                                Label("I don't have the equipment", systemImage: "shippingbox")
                                            }

                                            Button {
                                                substituteDrill(for: item, taskID: taskID)
                                            } label: {
                                                Label("I don't have a training partner", systemImage: "person.slash")
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis.circle.fill")
                                                .font(.title2)
                                                .padding(8)
                                        }
                                        .disabled(!isToday || completedTaskIDs.contains(taskID))
                                        .accessibilityLabel("More options for \(drillName)")
                                    }
                                    .foregroundStyle(Color.soccerCream)
                                    .padding()
                                    .background(isToday ? Color.soccerGreen : Color.gray.opacity(0.35))
                                    .clipShape(.rect(cornerRadius: 14))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isToday ? Color.white : Color.gray, lineWidth: 2)
                                    }
                                    .opacity(isToday ? 1 : 0.65)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding()
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 18))

                }
                .padding()
            }
        }
        .foregroundStyle(Color.soccerCream)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            resetWeeklyProgressIfNeeded()
        }
    }

    private func resetWeeklyProgressIfNeeded() {
        let now = Date().timeIntervalSince1970
        let week: TimeInterval = 7 * 24 * 60 * 60

        if weeklyProgressStart == 0 {
            weeklyProgressStart = now
        } else if now - weeklyProgressStart >= week {
            completedWeeklyTasks = ""
            completedWeeklyDays = ""
            substitutionText = ""
            weeklyProgressStart = now
        }
    }
}

private struct TrainingAchievement: Identifiable {
    let title: String
    let detail: String
    let systemImage: String
    let isUnlocked: Bool

    var id: String { title }
}

struct ProfileView: View {
    let username: String
    let position: String
    let bestSkill: String
    @Binding var totalPoints: Int
    @AppStorage("favoriteTeam") private var favoriteTeam = ""
    @AppStorage("hasCompletedOnboarding") private var isSignedIn = false
    @AppStorage("profilePhoto") private var profilePhoto = ""
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0
    @AppStorage("playerXP") private var playerXP = 0
    @AppStorage("shootingXP") private var shootingXP = 0
    @AppStorage("dribblingXP") private var dribblingXP = 0
    @AppStorage("passingXP") private var passingXP = 0
    @AppStorage("controlXP") private var controlXP = 0
    @AppStorage("fitnessXP") private var fitnessXP = 0
    @AppStorage("totalGoals") private var totalGoals = 0
    @AppStorage("totalShots") private var totalShots = 0
    @AppStorage("totalPasses") private var totalPasses = 0
    @AppStorage("totalDribblingAttempts") private var totalDribblingAttempts = 0
    @AppStorage("totalControls") private var totalControls = 0
    @AppStorage("totalSessions") private var totalSessions = 0
    @AppStorage("trainingStreak") private var trainingStreak = 0
    @AppStorage("rewardBoxes") private var rewardBoxes = 0
    @AppStorage("rewardBoxFixVersion") private var rewardBoxFixVersion = 0
    @State private var rewardBoxMessage = ""
    @State private var isShowingSignOutConfirmation = false
    @State private var isShowingCamera = false
    @State private var isShowingCameraUnavailable = false

    private var savedProfileImage: UIImage? {
        guard
            let data = Data(base64Encoded: profilePhoto),
            let image = UIImage(data: data)
        else {
            return nil
        }
        return image
    }

    private var level: Int {
        playerXP / 500 + 1
    }

    private var levelTitle: String {
        switch level {
        case 1...4: "Developing Player"
        case 5...9: "Rising Player"
        case 10...19: "Strong Player"
        default: "Elite Trainer"
        }
    }

    private var progress: Double {
        Double(playerXP % 500) / 500
    }

    private var achievements: [TrainingAchievement] {
        [
            TrainingAchievement(title: "First Goal", detail: "Score your first training goal", systemImage: "soccerball", isUnlocked: totalGoals >= 1),
            TrainingAchievement(title: "Goal Getter", detail: "Score 50 training goals", systemImage: "scope", isUnlocked: totalGoals >= 50),
            TrainingAchievement(title: "Getting Started", detail: "Complete 5 sessions", systemImage: "figure.run", isUnlocked: totalSessions >= 5),
            TrainingAchievement(title: "On a Roll", detail: "Reach a 3-day streak", systemImage: "flame.fill", isUnlocked: trainingStreak >= 3),
            TrainingAchievement(title: "Point Collector", detail: "Hold 1,000 points", systemImage: "star.fill", isUnlocked: totalPoints >= 1_000),
            TrainingAchievement(title: "Level Five", detail: "Reach level 5", systemImage: "trophy.fill", isUnlocked: level >= 5),
        ]
    }

    private func skillRating(for xp: Int) -> Int {
        let trainingTimeBonus = totalTrainingMinutes / 30
        return min(99, 40 + xp / 50 + trainingTimeBonus)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        isShowingCamera = true
                    } else {
                        isShowingCameraUnavailable = true
                    }
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        if let savedProfileImage {
                            Image(uiImage: savedProfileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(Color.soccerGreen)
                        }

                        Image(systemName: "camera.fill")
                            .font(.headline)
                            .padding(9)
                            .foregroundStyle(.white)
                            .background(Color.soccerGreen, in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Take profile photo")

                Text(username)
                    .font(.largeTitle)
                    .fontWeight(.heavy)

                VStack(spacing: 8) {
                    Text("Level \(level) • \(levelTitle)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Your XP comes from recorded results and training time. Every 30 training minutes also raises all Profile ratings.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Level Progress")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(playerXP) XP")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.soccerGreen)
                    }

                    ProgressView(value: progress)
                        .tint(.blue)

                    Text("\(500 - (playerXP % 500)) XP until Level \(level + 1) • Reward: one reward box")
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerGreen)
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                HStack(spacing: 12) {
                    profileCard(title: "Position", value: position)
                    profileCard(title: "Best Skill", value: bestSkill)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Player Stats")
                        .font(.title2)
                        .fontWeight(.heavy)

                    HStack(spacing: 10) {
                        skillCard(title: "Shooting", rating: skillRating(for: shootingXP))
                        skillCard(title: "Dribbling", rating: skillRating(for: dribblingXP))
                    }
                    HStack(spacing: 10) {
                        skillCard(title: "Passing", rating: skillRating(for: passingXP))
                        skillCard(title: "Control", rating: skillRating(for: controlXP))
                    }
                    skillCard(title: "Fitness", rating: skillRating(for: fitnessXP))

                    Text("\(totalSessions) sessions completed • \(totalTrainingMinutes) minutes trained")
                        .font(.subheadline)
                    Text("\(totalPasses) accurate passes • \(totalDribblingAttempts) dribbling attempts • \(totalControls) successful controls")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Label("Reward Boxes: \(rewardBoxes)", systemImage: "shippingbox.fill")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.soccerGold)

                    Text("Earn one box every time you level up. Each box contains 150 points.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Open Reward Box") {
                        guard rewardBoxes > 0 else { return }
                        totalPoints += 150
                        rewardBoxes -= 1
                        rewardBoxMessage = "You received 150 points! Your new balance is \(totalPoints) points."
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(rewardBoxes == 0)

                    if !rewardBoxMessage.isEmpty {
                        Label(rewardBoxMessage, systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.soccerGreen)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Achievements")
                        .font(.title2)
                        .fontWeight(.heavy)

                    ForEach(achievements) { achievement in
                        HStack(spacing: 12) {
                            Image(systemName: achievement.systemImage)
                                .frame(width: 28)
                                .foregroundStyle(achievement.isUnlocked ? Color.soccerGold : Color.gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(achievement.title)
                                    .fontWeight(.bold)
                                Text(achievement.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: achievement.isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                                .foregroundStyle(achievement.isUnlocked ? Color.soccerGreen : Color.gray)
                        }
                    }
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Label("Choose Your Team", systemImage: "shield.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.soccerLime)

                    Text("Your choice changes the colors across the entire app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Favorite team", selection: $favoriteTeam) {
                        Text("Select a team").tag("")
                        ForEach(TeamLeague.allCases) { league in
                            Section(league.rawValue) {
                                ForEach(FavoriteTeam.teams(in: league)) { team in
                                    Text(team.displayName).tag(team.rawValue)
                                }
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.soccerLime)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let team = FavoriteTeam(rawValue: favoriteTeam) {
                        HStack(spacing: 12) {
                            ClubCrestView(team: team, size: 44)

                            Text(team.displayName)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 16))

                NavigationLink {
                    MyTeamView()
                } label: {
                    Label("My Team", systemImage: "person.3.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.soccerSurface)
                        .foregroundStyle(Color.soccerCream)
                        .clipShape(.rect(cornerRadius: 14))
                }

                NavigationLink {
                    LeaderboardsView(username: username, totalPoints: totalPoints)
                } label: {
                    Label("Leaderboards", systemImage: "trophy.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.soccerGreen)
                        .foregroundStyle(Color.soccerCream)
                        .clipShape(.rect(cornerRadius: 14))
                }

                Button(role: .destructive) {
                    isShowingSignOutConfirmation = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .background(Color.soccerNavy)
        .foregroundStyle(Color.soccerCream)
        .navigationTitle("Profile")
        .onAppear {
            if rewardBoxFixVersion < 1 {
                rewardBoxes += 1
                rewardBoxFixVersion = 1
                rewardBoxMessage = "Your missing reward box has been returned."
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            ProfileCameraPicker { image in
                guard let data = image.jpegData(compressionQuality: 0.7) else { return }
                profilePhoto = data.base64EncodedString()
            }
            .ignoresSafeArea()
        }
        .alert("Camera Unavailable", isPresented: $isShowingCameraUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Use an iPhone with a camera to take your profile picture.")
        }
        .confirmationDialog(
            "Sign out of Futbol Trainnier?",
            isPresented: $isShowingSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                isSignedIn = false
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your points, players, training progress, and team choice will stay saved.")
        }
    }

    private func skillCard(title: String, rating: Int) -> some View {
        VStack(spacing: 6) {
            Text(rating.formatted())
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerLime)
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(Color.soccerNavy.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
    }

    private func profileCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(8)
        .background(Color.soccerSurface)
        .clipShape(.rect(cornerRadius: 16))
    }
}

private struct ProfileCameraPicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ProfileCameraPicker

        init(parent: ProfileCameraPicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            if let image {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
    }
}

private enum BotTeamGenerator {
    static let positions = ["GK", "LB", "CB", "CB", "RB", "LM", "CM", "CM", "RM", "ST", "ST"]

    static func lineup(seed: Int, stockText: String) -> [SoccerPlayer] {
        let availableIDs: Set<String> = Set(
            stockText.split(separator: "|").compactMap { entry -> String? in
                let parts = entry.split(separator: ":")
                guard parts.count == 2, let count = Int(parts[1]), count > 0 else { return nil }
                return String(parts[0])
            }
        )

        var strongPlayersUsed = 0
        var selectedPlayers: [SoccerPlayer] = []

        for (slotIndex, position) in positions.enumerated() {
            let candidates = PlayerCatalog.players.filter { player in
                guard player.position == position && player.id != "yamal" else { return false }
                if player.overall <= 78 {
                    return true
                }
                return strongPlayersUsed < 2 && availableIDs.contains(player.id)
            }
            let samePositionBefore = positions.prefix(slotIndex).filter { $0 == position }.count
            guard !candidates.isEmpty else { continue }

            let player = candidates[(seed + samePositionBefore) % candidates.count]
            selectedPlayers.append(player)
            if player.overall > 78 {
                strongPlayersUsed += 1
            }
        }

        return selectedPlayers
    }

    static func rating(seed: Int, stockText: String) -> Int {
        let players = lineup(seed: seed, stockText: stockText)
        guard players.count == positions.count else { return 0 }
        return players.map(\.overall).reduce(0, +) / players.count
    }
}

struct LeaderboardsView: View {
    let username: String
    let totalPoints: Int
    @AppStorage("ownedPlayerIDs") private var ownedPlayerIDs = ""
    @AppStorage("playerShopDailyStockV2") private var stockText = ""

    private let requiredPositions = [
        "GK": 1, "LB": 1, "CB": 2, "RB": 1,
        "LM": 1, "CM": 2, "RM": 1, "ST": 2,
    ]

    private var ownedPlayers: [SoccerPlayer] {
        let ownedIDs = Set(ownedPlayerIDs.split(separator: "|").map(String.init))
        return PlayerCatalog.players.filter { ownedIDs.contains($0.id) }
    }

    private var hasFullTeam: Bool {
        requiredPositions.allSatisfy { position, count in
            ownedPlayers.filter { $0.position == position }.count >= count
        }
    }

    private var teamOverall: Int {
        let selectedPlayers = requiredPositions.flatMap { position, count in
            Array(
                ownedPlayers
                    .filter { $0.position == position }
                    .sorted { $0.overall > $1.overall }
                    .prefix(count)
            )
        }
        guard selectedPlayers.count == 11 else { return 0 }
        return selectedPlayers.map(\.overall).reduce(0, +) / selectedPlayers.count
    }

    private var teamRankings: [LeaderboardEntry] {
        let botTeamNames = [
            "CR7Fan's XI", "MessiGOAT FC", "TopBins United", "GoalMachine XI",
            "SpeedyStriker FC", "SkillMovesOnly", "FutureGOATs", "SundayBallers", "NoLookPass FC",
        ]
        var rankings = botTeamNames.enumerated().map { index, name in
            LeaderboardEntry(
                id: "team\(index + 1)",
                name: name,
                score: BotTeamGenerator.rating(seed: index, stockText: stockText)
            )
        }
        if hasFullTeam {
            rankings.append(LeaderboardEntry(id: "playerTeam", name: "\(username)'s Team", score: teamOverall))
        }
        return rankings.sorted { $0.score > $1.score }
    }

    private var pointRankings: [LeaderboardEntry] {
        var rankings = [
            LeaderboardEntry(id: "points1", name: "CR7Fan", score: 2_750),
            LeaderboardEntry(id: "points2", name: "MessiGOAT", score: 2_300),
            LeaderboardEntry(id: "points3", name: "GoalMachine", score: 1_850),
            LeaderboardEntry(id: "points4", name: "SpeedyStriker", score: 1_500),
            LeaderboardEntry(id: "points5", name: "TopBins", score: 1_200),
            LeaderboardEntry(id: "points6", name: "SkillMoves", score: 950),
            LeaderboardEntry(id: "points7", name: "GoldenBoot", score: 725),
            LeaderboardEntry(id: "eli", name: "Eli", score: 560),
            LeaderboardEntry(id: "points8", name: "PassMaster", score: 500),
            LeaderboardEntry(id: "points9", name: "FutureGOAT", score: 300),
            LeaderboardEntry(id: "noah", name: "Noah", score: 220),
            LeaderboardEntry(id: "points10", name: "SoccerKid", score: 150),
        ]

        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedUsername != "eli" && normalizedUsername != "noah" {
            rankings.append(LeaderboardEntry(id: "currentPlayer", name: username, score: totalPoints))
        }

        return rankings.sorted { $0.score > $1.score }
    }

    var body: some View {
        List {
            Section("Team Rating Leaderboard") {
                if !hasFullTeam {
                    Label(
                        "Complete your Starting 11 to add your team",
                        systemImage: "lock.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                ForEach(Array(teamRankings.enumerated()), id: \.element.id) { index, entry in
                    NavigationLink {
                        if entry.id == "playerTeam" {
                            MyTeamView()
                        } else {
                            OpponentTeamView(
                                teamName: entry.name,
                                teamOverall: entry.score,
                                seed: Int(entry.id.dropFirst(4)).map { $0 - 1 } ?? 0
                            )
                        }
                    } label: {
                        rankingRow(rank: index + 1, entry: entry, unit: "OVR")
                    }
                }
            }

            Section("Most Points Leaderboard") {
                ForEach(Array(pointRankings.enumerated()), id: \.element.id) { index, entry in
                    rankingRow(rank: index + 1, entry: entry, unit: "points")
                }
            }
        }
        .navigationTitle("Leaderboards")
    }

    private func rankingRow(rank: Int, entry: LeaderboardEntry, unit: String) -> some View {
        HStack {
            Text("#\(rank)")
                .font(.headline)
                .frame(width: 42)
            Text(entry.name)
                .fontWeight(entry.id == "currentPlayer" || entry.id == "playerTeam" ? .bold : .regular)
            Spacer()
            Text("\(entry.score) \(unit)")
                .fontWeight(.bold)
                .foregroundStyle(unit == "points" ? Color.soccerGreen : Color.primary)
        }
        .foregroundStyle(entry.id == "currentPlayer" || entry.id == "playerTeam" ? Color.soccerGreen : Color.primary)
    }
}

struct OpponentTeamView: View {
    let teamName: String
    let teamOverall: Int
    let seed: Int
    @AppStorage("playerShopDailyStockV2") private var stockText = ""

    private let positions = BotTeamGenerator.positions

    private var lineup: [SoccerPlayer] {
        BotTeamGenerator.lineup(seed: seed, stockText: stockText)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.soccerGreen)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(teamName)
                            .font(.title2)
                            .fontWeight(.heavy)
                        Text("Team Overall: \(teamOverall)")
                            .foregroundStyle(Color.soccerGreen)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Starting 11") {
                ForEach(Array(positions.enumerated()), id: \.offset) { index, position in
                    let player = lineup[index]

                    HStack(spacing: 14) {
                        PlayerPhotoView(player: player, size: 52)
                            .overlay {
                                Circle()
                                    .stroke(Color.soccerGreen, lineWidth: 2)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(player.name)
                                .fontWeight(.bold)
                            Text(position)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(player.overall)")
                            .font(.headline)
                            .foregroundStyle(Color.soccerGreen)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.soccerNavy)
        .navigationTitle(teamName)
        .navigationBarTitleDisplayMode(.inline)
    }

}

private struct LineupSlot: Identifiable {
    let id: String
    let position: String
    let occurrence: Int
    let label: String
}

struct MyTeamView: View {
    @AppStorage("ownedPlayerIDs") private var ownedPlayerIDs = ""
    @AppStorage("startingLineupSelections") private var lineupSelectionText = ""

    private var ownedPlayers: [SoccerPlayer] {
        let ownedIDs = Set(ownedPlayerIDs.split(separator: "|").map(String.init))
        return PlayerCatalog.players.filter { ownedIDs.contains($0.id) }
    }

    private let lineupSlots = [
        LineupSlot(id: "ST0", position: "ST", occurrence: 0, label: "Striker 1"),
        LineupSlot(id: "ST1", position: "ST", occurrence: 1, label: "Striker 2"),
        LineupSlot(id: "LM0", position: "LM", occurrence: 0, label: "Left Midfielder"),
        LineupSlot(id: "CM0", position: "CM", occurrence: 0, label: "Center Midfielder 1"),
        LineupSlot(id: "CM1", position: "CM", occurrence: 1, label: "Center Midfielder 2"),
        LineupSlot(id: "RM0", position: "RM", occurrence: 0, label: "Right Midfielder"),
        LineupSlot(id: "LB0", position: "LB", occurrence: 0, label: "Left Back"),
        LineupSlot(id: "CB0", position: "CB", occurrence: 0, label: "Center Back 1"),
        LineupSlot(id: "CB1", position: "CB", occurrence: 1, label: "Center Back 2"),
        LineupSlot(id: "RB0", position: "RB", occurrence: 0, label: "Right Back"),
        LineupSlot(id: "GK0", position: "GK", occurrence: 0, label: "Goalkeeper"),
    ]

    private var lineupSelections: [String: String] {
        Dictionary(
            uniqueKeysWithValues: lineupSelectionText.split(separator: "|").compactMap { entry in
                let parts = entry.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                return (String(parts[0]), String(parts[1]))
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Starting 11")
                    .font(.largeTitle)
                    .fontWeight(.heavy)

                Text("Your players are shown in their spots on the field.")
                    .foregroundStyle(.secondary)

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.soccerSurface,
                                    Color.soccerNavy,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    SoccerFieldLines()

                    VStack {
                        HStack(spacing: 48) {
                            TeamPlayerSpot(player: player(for: "ST", occurrence: 0), position: "ST", portraitNumber: 1)
                            TeamPlayerSpot(player: player(for: "ST", occurrence: 1), position: "ST", portraitNumber: 2)
                        }

                        Spacer()

                        HStack {
                            TeamPlayerSpot(player: player(for: "LM"), position: "LM", portraitNumber: 3)
                            Spacer()
                            TeamPlayerSpot(player: player(for: "CM", occurrence: 0), position: "CM", portraitNumber: 4)
                            TeamPlayerSpot(player: player(for: "CM", occurrence: 1), position: "CM", portraitNumber: 5)
                            Spacer()
                            TeamPlayerSpot(player: player(for: "RM"), position: "RM", portraitNumber: 6)
                        }

                        Spacer()

                        HStack {
                            TeamPlayerSpot(player: player(for: "LB"), position: "LB", portraitNumber: 7)
                            Spacer()
                            TeamPlayerSpot(player: player(for: "CB", occurrence: 0), position: "CB", portraitNumber: 8)
                            TeamPlayerSpot(player: player(for: "CB", occurrence: 1), position: "CB", portraitNumber: 9)
                            Spacer()
                            TeamPlayerSpot(player: player(for: "RB"), position: "RB", portraitNumber: 10)
                        }

                        Spacer()

                        TeamPlayerSpot(player: player(for: "GK"), position: "GK", portraitNumber: 11)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 24)
                }
                .frame(height: 620)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.soccerLime.opacity(0.75), lineWidth: 2)
                }

                Label(
                    "\(ownedPlayers.count) players owned",
                    systemImage: ownedPlayers.count >= 11 ? "checkmark.circle.fill" : "person.3.fill"
                )
                .font(.headline)
                .foregroundStyle(Color.soccerLime)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Substitutions")
                        .font(.title2)
                        .fontWeight(.heavy)

                    Text("Choose the starter for each position when you own multiple players.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(lineupSlots) { slot in
                        let candidates = players(for: slot.position)

                        if !candidates.isEmpty {
                            HStack {
                                Text(slot.label)
                                    .fontWeight(.semibold)
                                Spacer()
                                Picker(
                                    slot.label,
                                    selection: lineupBinding(for: slot)
                                ) {
                                    ForEach(candidates) { player in
                                        Text("\(player.name) • \(player.overall) OVR")
                                            .tag(player.id)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 18))
            }
            .padding()
        }
        .background(Color.soccerNavy)
        .foregroundStyle(Color.soccerCream)
        .navigationTitle("My Team")
    }

    private func players(for position: String) -> [SoccerPlayer] {
        ownedPlayers
            .filter { $0.position == position }
            .sorted { $0.overall > $1.overall }
    }

    private func player(for position: String, occurrence: Int = 0) -> SoccerPlayer? {
        let matchingPlayers = players(for: position)
        let slotID = "\(position)\(occurrence)"

        if let selectedID = lineupSelections[slotID],
           let selectedPlayer = matchingPlayers.first(where: { $0.id == selectedID }) {
            return selectedPlayer
        }

        guard matchingPlayers.indices.contains(occurrence) else { return nil }

        let selectedForOtherSlots = Set(
            lineupSelections
                .filter { $0.key != slotID }
                .map(\.value)
        )
        let defaultPlayer = matchingPlayers[occurrence]
        if !selectedForOtherSlots.contains(defaultPlayer.id) {
            return defaultPlayer
        }

        return matchingPlayers.first { !selectedForOtherSlots.contains($0.id) }
    }

    private func lineupBinding(for slot: LineupSlot) -> Binding<String> {
        Binding(
            get: {
                player(for: slot.position, occurrence: slot.occurrence)?.id ?? ""
            },
            set: { playerID in
                selectPlayer(playerID, for: slot.id)
            }
        )
    }

    private func selectPlayer(_ playerID: String, for slotID: String) {
        var updatedSelections = lineupSelections
        updatedSelections = updatedSelections.filter { $0.value != playerID }
        updatedSelections[slotID] = playerID
        lineupSelectionText = updatedSelections
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: "|")
    }
}

private struct WikipediaPlayerSummary: Decodable {
    let thumbnail: WikipediaPlayerThumbnail?
}

private struct WikipediaPlayerThumbnail: Decodable {
    let source: URL
}

private struct PlayerPhotoView: View {
    let player: SoccerPlayer?
    let size: CGFloat
    @State private var photoURL: URL?

    var body: some View {
        Group {
            if let photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .task(id: player?.id) {
            photoURL = await loadPhotoURL()
        }
    }

    private var placeholder: some View {
        Image(systemName: player == nil ? "person.crop.circle.badge.plus" : "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.soccerCream.opacity(0.7))
            .padding(4)
    }

    private func loadPhotoURL() async -> URL? {
        guard let player, player.hasRealPhoto else { return nil }
        guard let title = player.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        guard let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(title)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("SoccerTrainingApp/1.0", forHTTPHeaderField: "User-Agent")

        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            return nil
        }

        return try? JSONDecoder().decode(WikipediaPlayerSummary.self, from: data).thumbnail?.source
    }
}

private extension SoccerPlayer {
    var hasRealPhoto: Bool {
        Self.realPlayerIDs.contains(id)
    }

    private static let realPlayerIDs: Set<String> = [
        "maignan", "raya", "costa", "hernandez", "davies", "saliba", "araujo",
        "bastoni", "hakimi", "frimpong", "rodri", "pedri", "valverde",
        "macallister", "leao", "mitoma", "yamal", "saka", "olise", "osimhen",
        "isak", "watkins", "kelleher", "mamardashvili", "verbruggen", "udogie",
        "kerkez", "dorgu", "branthwaite", "colwill", "murillo", "huijsen",
        "lacroix", "livramento", "gusto", "vanderson", "neves", "mainoo",
        "wharton", "zaire_emery", "gray", "gordon", "gittens", "garnacho",
        "savinho", "madueke", "minteh", "sesko", "hojlund", "delap",
        "ferguson", "tel", "ronaldo", "messi", "vinicius", "mbappe",
        "haaland", "bellingham", "eze", "bowen", "mbeumo", "solanke",
        "gibbs_white", "guehi", "onana", "salah", "kane", "de_bruyne",
        "van_dijk", "lewandowski", "palmer", "musiala", "wirtz", "luis_diaz",
        "bruno_guimaraes", "martinelli",
    ]
}

private struct TeamPlayerSpot: View {
    let player: SoccerPlayer?
    let position: String
    let portraitNumber: Int

    private var portraitName: String {
        Self.portraitNames[(portraitNumber - 1) % Self.portraitNames.count]
    }

    private static let portraitNames = [
        "PlayerFace01",
        "PlayerFace02",
        "PlayerFace03",
        "PlayerFace04",
        "PlayerFace05",
        "PlayerFace06",
        "PlayerFace07",
        "PlayerFace08",
        "PlayerFace09",
        "PlayerFace10",
        "PlayerFace11",
    ]

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(player == nil ? Color.soccerNavy : Color.soccerGreen)
                    .frame(width: 54, height: 54)
                    .overlay {
                        PlayerPhotoView(player: player, size: 50)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.soccerLime, lineWidth: 2)
                    }

                Text(position)
                    .font(.caption2)
                    .fontWeight(.heavy)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color.soccerLime)
                    .foregroundStyle(Color.soccerNavy)
                    .clipShape(.capsule)
            }

            Text(player?.name.split(separator: " ").last.map(String.init) ?? "Open")
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(player.map { "\($0.overall) OVR" } ?? "Empty spot")
                .font(.caption2)
                .foregroundStyle(player == nil ? Color.soccerCream.opacity(0.65) : Color.soccerLime)
        }
        .frame(width: 72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            player.map { "\(position), \($0.name), overall \($0.overall)" }
                ?? "\(position), open position"
        )
    }
}

private struct SoccerFieldLines: View {
    var body: some View {
        GeometryReader { geometry in
            let lineColor = Color.soccerCream.opacity(0.38)

            ZStack {
                Rectangle()
                    .stroke(lineColor, lineWidth: 2)
                    .padding(12)

                Rectangle()
                    .fill(lineColor)
                    .frame(height: 2)

                Circle()
                    .stroke(lineColor, lineWidth: 2)
                    .frame(width: 94, height: 94)

                VStack {
                    Rectangle()
                        .stroke(lineColor, lineWidth: 2)
                        .frame(width: geometry.size.width * 0.48, height: 72)

                    Spacer()

                    Rectangle()
                        .stroke(lineColor, lineWidth: 2)
                        .frame(width: geometry.size.width * 0.48, height: 72)
                }
                .padding(.vertical, 12)
            }
        }
        .allowsHitTesting(false)
    }
}

private enum StoreCategory: String, CaseIterable, Identifiable {
    case players = "Players"
    case points = "Points"

    var id: String { rawValue }
}

struct RarePlayerStoreView: View {
    @State private var selectedCategory = StoreCategory.players
    @State private var rewardedAdManager = RewardedAdManager()
    @State private var plusSubscription = PlusSubscriptionManager()
    @AppStorage("totalPoints") private var totalPoints = 0
    @AppStorage("isProMember") private var isProMember = false
    @AppStorage("rarePlayerStockIDs") private var stockIDs = ""
    @AppStorage("rarePlayerLastDailyRefreshV2") private var lastRefresh = 0.0
    @AppStorage("cashPlayerStockIDsV4") private var cashStockIDs = ""
    @AppStorage("cashPlayerLastRefreshV4") private var cashLastRefresh = 0.0

    private var availableIDs: Set<String> {
        Set(stockIDs.split(separator: "|").map(String.init))
    }

    private var cashAvailableIDs: Set<String> {
        Set(cashStockIDs.split(separator: "|").map(String.init))
    }

    private var weeklyCashOffers: [RarePlayerOffer] {
        CashStoreCatalog.players.filter { cashAvailableIDs.contains($0.id) }
    }

    private var rareDropOffers: [RarePlayerOffer] {
        RarePlayerCatalog.offers
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Label("FUTBOL TRAINNIER PLUS", systemImage: "crown.fill")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.soccerGold)

                    Text("Get more points, better drills, exclusive Plus Training, and more rewards every time you train.")
                        .font(.headline)

                    Label("25% more points from every completed drill", systemImage: "star.fill")
                    Label("Exclusive advanced and fun Plus drills", systemImage: "figure.soccer")
                    Label("Better progress toward players and crates", systemImage: "arrow.up.circle.fill")

                    Button {
                        Task {
                            await plusSubscription.purchase()
                        }
                    } label: {
                        Label(
                            isProMember
                                ? "PLUS ACTIVE"
                                : "SUBSCRIBE • \(plusSubscription.monthlyPriceText)",
                            systemImage: isProMember ? "checkmark.seal.fill" : "crown.fill"
                        )
                        .font(.title3)
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 64)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.soccerGreen)
                    .disabled(
                        isProMember
                            || plusSubscription.isPurchasing
                            || plusSubscription.product == nil
                    )

                    Text("Auto-renews monthly until cancelled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button("Restore Purchases") {
                        Task {
                            await plusSubscription.restore()
                        }
                    }
                    .font(.subheadline)

                    Text(plusSubscription.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)
            }

            Section {
                Picker("Store category", selection: $selectedCategory) {
                    ForEach(StoreCategory.allCases) { category in
                        Label(
                            category.rawValue,
                            systemImage: category == .players ? "person.3.fill" : "star.fill"
                        )
                        .tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }

            if selectedCategory == .points {
                Section("Earn Points") {
                    Button {
                        rewardedAdManager.showAd {
                            totalPoints += 50
                        }
                    } label: {
                        Label("Watch Ad • Earn 50 Points", systemImage: "play.rectangle.fill")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!rewardedAdManager.isReady)

                    Text(rewardedAdManager.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Buy Points") {
                    Text("Choose a points pack to use in the Player Shop.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(CashStoreCatalog.pointsPacks) { pack in
                        HStack {
                            Label("\(pack.points) Points", systemImage: "star.fill")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.soccerGold)
                            Spacer()
                            Button(pack.price) { }
                                .buttonStyle(.borderedProminent)
                                .disabled(true)
                        }
                        .padding(.vertical, 6)
                    }
                }
            } else {
                Section("Player Store • 6 Players This Week") {
                    ForEach(weeklyCashOffers) { offer in
                        cashPlayerRow(offer)
                    }
                }

                Section("Rare Player Drop • Buy with Points") {
                    Text("This bonus point offer refreshes every day. There is a 2% chance that one GOAT or elite player appears.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(rareDropOffers) { offer in
                        rarePlayerRow(offer)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.soccerNavy)
        .navigationTitle("Store")
        .task {
            async let adPreparation: Void = rewardedAdManager.prepare()
            async let plusPreparation: Void = plusSubscription.prepare()
            _ = await (adPreparation, plusPreparation)
        }
        .onAppear {
            refreshStockIfNeeded()
            refreshCashStockIfNeeded()
        }
    }

    private func cashPlayerRow(_ offer: RarePlayerOffer) -> some View {
        HStack(spacing: 14) {
            PlayerPhotoView(player: offer.player, size: 62)
                .overlay {
                    Circle()
                        .stroke(Color.soccerGreen, lineWidth: 2)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(offer.player.name)
                    .font(.headline)

                Text("\(offer.player.position) • \(offer.player.overall) OVR • \(offer.tier)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label("Unlimited Availability", systemImage: "infinity.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.soccerGreen)

                Button("Buy for \(offer.price)") { }
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
            }
        }
        .padding(.vertical, 8)
    }

    private func rarePlayerRow(_ offer: RarePlayerOffer) -> some View {
        let isAvailable = availableIDs.contains(offer.id)
        let pointCost = rarePointCost(for: offer)
        let formattedPointCost = pointCost.formatted()

        return HStack(spacing: 14) {
            PlayerPhotoView(player: offer.player, size: 68)
                .overlay {
                    Circle()
                        .stroke(isAvailable ? Color.soccerGold : Color.gray, lineWidth: 3)
                }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(offer.player.name)
                        .font(.headline)
                    Text(offer.tier)
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.soccerGold)
                        .foregroundStyle(Color.black)
                        .clipShape(.capsule)
                }

                Text("\(offer.player.position) • \(offer.player.overall) OVR")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label(
                    isAvailable ? "Available This Week • \(formattedPointCost) Points" : "Not Available This Week • \(formattedPointCost) Points",
                    systemImage: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isAvailable ? Color.soccerGold : Color.gray)

                Button(isAvailable ? "Buy for \(formattedPointCost) Points" : "Not Available This Week") { }
                    .buttonStyle(.borderedProminent)
                    .tint(isAvailable ? Color.soccerGreen : Color.gray)
                    .disabled(true)
            }
        }
        .padding(.vertical, 8)
    }

    private func rarePointCost(for offer: RarePlayerOffer) -> Int {
        switch offer.player.overall {
        case 99...:
            12_000
        case 98:
            10_000
        case 97:
            8_000
        default:
            7_000
        }
    }

    private func refreshCashStockIfNeeded() {
        let now = Date().timeIntervalSince1970
        let week: TimeInterval = 7 * 24 * 60 * 60
        guard cashLastRefresh == 0 || now - cashLastRefresh >= week else { return }

        let weeklySuperstarID = CashStoreCatalog.players
            .filter { $0.tier == "Superstar" }
            .randomElement()?
            .id
        let weeklyEliteID = CashStoreCatalog.players
            .filter { $0.tier == "Elite" }
            .randomElement()?
            .id
        let lowerTierIDs = CashStoreCatalog.players
            .filter { $0.tier == "Quality" || $0.tier == "Solid" }
            .shuffled()
            .prefix(4)
            .map(\.id)

        cashStockIDs = (
            [weeklySuperstarID, weeklyEliteID].compactMap { $0 } + lowerTierIDs
        )
        .joined(separator: "|")
        cashLastRefresh = now
    }

    private func refreshStockIfNeeded() {
        let now = Date().timeIntervalSince1970
        let day: TimeInterval = 24 * 60 * 60
        guard lastRefresh == 0 || now - lastRefresh >= day else { return }

        if Int.random(in: 0..<100) < 2, let rarePlayer = rareDropOffers.randomElement() {
            stockIDs = rarePlayer.id
        } else {
            stockIDs = ""
        }
        lastRefresh = now
    }
}

private struct CrateOdds {
    let goat: Int
    let superstar: Int
    let legendary: Int
    let elite: Int
    let otherRare: Int
    let good: Int
    let points: Int
    let regular: Int

    var rare: Int {
        goat + superstar + legendary + elite + otherRare
    }
}

private enum PlayerCrateTier: String, CaseIterable, Identifiable {
    case starter
    case pro
    case premium

    var id: String { rawValue }

    var name: LocalizedStringResource {
        switch self {
        case .starter:
            "Starter Crate"
        case .pro:
            "Pro Crate"
        case .premium:
            "Premium Crate"
        }
    }

    var cost: Int {
        switch self {
        case .starter:
            150
        case .pro:
            300
        case .premium:
            600
        }
    }

    var odds: CrateOdds {
        switch self {
        case .starter:
            CrateOdds(
                goat: 10,
                superstar: 1_000,
                legendary: 2_000,
                elite: 3_000,
                otherRare: 5_000,
                good: 20_000,
                points: 10_000,
                regular: 58_990
            )
        case .pro:
            CrateOdds(
                goat: 50,
                superstar: 2_500,
                legendary: 4_000,
                elite: 6_000,
                otherRare: 7_500,
                good: 30_000,
                points: 10_000,
                regular: 39_950
            )
        case .premium:
            CrateOdds(
                goat: 200,
                superstar: 5_000,
                legendary: 7_000,
                elite: 9_000,
                otherRare: 10_000,
                good: 40_000,
                points: 10_000,
                regular: 18_800
            )
        }
    }

    func percentageText(for count: Int) -> String {
        let percentage = Double(count) / 1_000
        return percentage.formatted(.number.precision(.fractionLength(0...3))) + "%"
    }
}

private struct PlayerCrateCard: View {
    let tier: PlayerCrateTier
    let availablePoints: Int
    let onOpen: () -> Void

    var body: some View {
        let odds = tier.odds

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(tier.name, systemImage: "shippingbox.fill")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soccerGold)
                Spacer()
                Text("\(tier.cost) points")
                    .fontWeight(.bold)
            }

            LabeledContent("Regular player", value: tier.percentageText(for: odds.regular))
            LabeledContent("Good player", value: tier.percentageText(for: odds.good))
            LabeledContent("Rare player", value: tier.percentageText(for: odds.rare))
            LabeledContent("Points reward", value: tier.percentageText(for: odds.points))
            LabeledContent("GOAT included in Rare", value: tier.percentageText(for: odds.goat))
                .foregroundStyle(.secondary)

            Button {
                onOpen()
            } label: {
                Label(
                    availablePoints >= tier.cost
                        ? "Open for \(tier.cost) Points"
                        : "Need \(tier.cost - availablePoints) More Points",
                    systemImage: "sparkles"
                )
                .font(.headline)
                .fontWeight(.heavy)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.soccerGreen)
            .disabled(availablePoints < tier.cost)
        }
        .padding(.vertical, 8)
    }
}

struct PlayerShopView: View {
    @Binding var totalPoints: Int
    @AppStorage("ownedPlayerIDs") private var ownedPlayerIDs = ""
    @AppStorage("playerShopDailyStockV6") private var stockText = ""
    @AppStorage("playerShopLastDailyRestockV6") private var lastRestock = 0.0
    @State private var shopMessage = ""
    @State private var showShopMessage = false
    @State private var searchText = ""
    @State private var selectedPosition = "All"
    @State private var yamalProduct: Product?
    @State private var isPurchasingYamal = false

    private let yamalProductID = "com.thomastelintelo.soccertraining.yamal"

    private let positionOrder = ["GK", "LB", "CB", "RB", "LM", "CM", "RM", "ST"]

    private var allShopPlayers: [SoccerPlayer] {
        PlayerCatalog.players
    }

    private var regularPlayers: [SoccerPlayer] {
        allShopPlayers.filter { stock[$0.id, default: 0] > 0 }
    }

    private var yamal: SoccerPlayer {
        PlayerCatalog.players.first { $0.id == "yamal" }
            ?? SoccerPlayer(id: "yamal", name: "Lamine Yamal", position: "RM", overall: 97, cost: 8_000, weeklyStock: 0)
    }

    private var ownedIDs: Set<String> {
        Set(ownedPlayerIDs.split(separator: "|").map(String.init))
    }

    private var stock: [String: Int] {
        var savedStock: [String: Int] = [:]

        for entry in stockText.split(separator: "|") {
            let parts = entry.split(separator: ":")
            guard parts.count == 2, let count = Int(parts[1]) else { continue }
            savedStock[String(parts[0])] = count
        }

        for player in allShopPlayers where savedStock[player.id] == nil {
            savedStock[player.id] = 0
        }

        return savedStock
    }

    private var matchingPlayers: [SoccerPlayer] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        return regularPlayers
            .filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.position.localizedCaseInsensitiveContains(query)
            }
            .sorted {
                let firstPosition = positionOrder.firstIndex(of: $0.position) ?? positionOrder.count
                let secondPosition = positionOrder.firstIndex(of: $1.position) ?? positionOrder.count
                if firstPosition == secondPosition {
                    return $0.overall > $1.overall
                }
                return firstPosition < secondPosition
            }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    Text("BUILD YOUR DREAM TEAM")
                        .font(.caption)
                        .fontWeight(.black)
                        .tracking(1.2)

                    HStack(alignment: .firstTextBaseline) {
                        Text("Transfer Market")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                        Spacer()
                        Label("\(totalPoints)", systemImage: "star.fill")
                            .font(.title2)
                            .fontWeight(.heavy)
                    }

                    Text("Open crates or sign players by position. Better crates cost more and give stronger odds.")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.soccerNavy)
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Color.soccerLime, Color.soccerGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20)
                )
                .listRowBackground(Color.clear)
            }

            Section("Choose Position") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(["All"] + positionOrder, id: \.self) { position in
                            Button(position) {
                                selectedPosition = position
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedPosition == position ? Color.soccerGreen : Color.soccerSurface)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Player Crates") {
                Text("Higher-cost crates have better chances of getting Good, Rare, and GOAT players.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(PlayerCrateTier.allCases) { tier in
                    PlayerCrateCard(
                        tier: tier,
                        availablePoints: totalPoints
                    ) {
                        openPlayerCrate(tier)
                    }

                    if tier != PlayerCrateTier.allCases.last {
                        Divider()
                    }
                }
            }

            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ForEach(
                    positionOrder.filter { selectedPosition == "All" || $0 == selectedPosition },
                    id: \.self
                ) { position in
                    Section(position) {
                        ForEach(
                            regularPlayers
                                .filter { $0.position == position }
                                .sorted { $0.overall > $1.overall }
                        ) { player in
                            playerRow(player)
                        }
                    }
                }
            } else if matchingPlayers.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                Section("Search Results") {
                    ForEach(matchingPlayers) { player in
                        playerRow(player)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.soccerNavy)
        .navigationTitle("Player Shop")
        .safeAreaPadding(.bottom, 72)
        .searchable(text: $searchText, prompt: "Search players or positions")
        .onAppear {
            restockIfNeeded()
        }
        .task {
            yamalProduct = try? await Product.products(for: [yamalProductID]).first
        }
        .alert("Player Shop", isPresented: $showShopMessage) {
            Button("OK") { }
        } message: {
            Text(shopMessage)
        }
    }

    private var rareYamalRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(yamal.name)
                        .font(.headline)
                    Text("\(yamal.position) • Overall \(yamal.overall) • Rare")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Color.soccerGold)
            }

            if ownedIDs.contains(yamal.id) {
                Label("Owned", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.soccerGreen)
            } else if let yamalProduct {
                Button {
                    Task {
                        await purchaseYamal(yamalProduct)
                    }
                } label: {
                    Text(isPurchasingYamal ? "Purchasing…" : "Buy for \(yamalProduct.displayPrice)")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPurchasingYamal)
            } else {
                Text("Rare purchase unavailable until the product is configured in App Store Connect.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func purchaseYamal(_ product: Product) async {
        isPurchasingYamal = true
        defer { isPurchasingYamal = false }

        do {
            let result = try await product.purchase()
            guard case .success(.verified(let transaction)) = result else { return }

            var updatedOwnedIDs = ownedIDs
            updatedOwnedIDs.insert(yamal.id)
            ownedPlayerIDs = updatedOwnedIDs.sorted().joined(separator: "|")
            await transaction.finish()
            shopMessage = "\(yamal.name) was added to My Team!"
            showShopMessage = true
        } catch {
            shopMessage = "The purchase could not be completed."
            showShopMessage = true
        }
    }

    private func playerRow(_ player: SoccerPlayer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.name)
                        .font(.headline)
                    Text("\(player.position) • Overall \(player.overall)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("OVR \(player.overall)")
                    .fontWeight(.heavy)
                    .padding(8)
                    .background(player.overall >= 89 ? Color.soccerGreen : Color.soccerSurface)
                    .foregroundStyle(Color.soccerCream)
                    .clipShape(.rect(cornerRadius: 9))
            }

            HStack {
                Label("\(player.cost) points", systemImage: "star.fill")
                    .foregroundStyle(Color.soccerGreen)
                Spacer()
                if !ownedIDs.contains(player.id) {
                    Label("Available", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.soccerLime)
                }
            }
            .font(.subheadline)

            Button(buttonTitle(for: player)) {
                buy(player)
            }
            .font(.headline)
            .fontWeight(.heavy)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .background(canBuy(player) ? Color.soccerGreen : Color.gray)
            .foregroundStyle(Color.soccerCream)
            .clipShape(.rect(cornerRadius: 14))
            .disabled(!canBuy(player))
        }
        .padding(.vertical, 8)
    }

    private func canBuy(_ player: SoccerPlayer) -> Bool {
        !ownedIDs.contains(player.id) && totalPoints >= player.cost
    }

    private func buttonTitle(for player: SoccerPlayer) -> String {
        if ownedIDs.contains(player.id) {
            return "Owned"
        }
        if totalPoints < player.cost {
            return "Need \(player.cost - totalPoints) More Points"
        }
        return "Buy Player"
    }

    private func buy(_ player: SoccerPlayer) {
        guard canBuy(player) else { return }

        var updatedOwnedIDs = ownedIDs
        updatedOwnedIDs.insert(player.id)
        ownedPlayerIDs = updatedOwnedIDs.sorted().joined(separator: "|")
        totalPoints -= player.cost

        shopMessage = "\(player.name) was added to My Team!"
        showShopMessage = true
    }

    private func openPlayerCrate(_ tier: PlayerCrateTier) {
        guard totalPoints >= tier.cost else { return }
        totalPoints -= tier.cost

        let roll = Int.random(in: 0..<100_000)
        let odds = tier.odds
        let goatIDs: Set<String> = ["ronaldo", "messi", "pele"]
        let superstarIDs: Set<String> = ["yamal", "mbappe", "haaland", "neymar"]
        let legendaryIDs: Set<String> = ["ronaldo_nazario", "maradona"]
        let eliteIDs: Set<String> = ["bellingham", "van_dijk", "vinicius", "kane"]
        let specialIDs = goatIDs
            .union(superstarIDs)
            .union(legendaryIDs)
            .union(eliteIDs)
        let goodIDs = Set(
            regularPlayers
                .filter { $0.overall >= 85 && !specialIDs.contains($0.id) }
                .map(\.id)
        )
        let otherRareIDs = Set(
            regularPlayers
                .filter { (79...84).contains($0.overall) && !specialIDs.contains($0.id) }
                .map(\.id)
        )
        let regularIDs = Set(
            regularPlayers
                .filter { $0.overall <= 78 && !specialIDs.contains($0.id) }
                .map(\.id)
        )

        let playerRewards: [(weight: Int, ids: Set<String>, name: String)] = [
            (odds.goat, goatIDs, "GOAT"),
            (odds.superstar, superstarIDs, "Superstar"),
            (odds.legendary, legendaryIDs, "Legendary player"),
            (odds.elite, eliteIDs, "Elite player"),
            (odds.otherRare, otherRareIDs, "Other rare"),
            (odds.good, goodIDs, "Good player"),
        ]

        var upperBound = 0
        for reward in playerRewards {
            upperBound += reward.weight
            if roll < upperBound {
                awardCratePlayer(from: reward.ids, tierName: reward.name)
                return
            }
        }

        upperBound += odds.points
        if roll < upperBound {
            awardCratePoints()
            return
        }

        awardCratePlayer(from: regularIDs, tierName: "Regular player")
    }

    private func awardCratePlayer(from ids: Set<String>, tierName: String) {
        let candidates = allShopPlayers.filter { ids.contains($0.id) }

        guard let player = candidates.randomElement() else {
            awardCratePoints()
            return
        }

        if ownedIDs.contains(player.id) {
            totalPoints += 50
            shopMessage = "Duplicate \(player.name)! You received 50 points instead."
        } else {
            var updatedOwnedIDs = ownedIDs
            updatedOwnedIDs.insert(player.id)
            ownedPlayerIDs = updatedOwnedIDs.sorted().joined(separator: "|")
            shopMessage = "\(tierName): You unlocked \(player.name)!"
        }

        showShopMessage = true
    }

    private func awardCratePoints() {
        let pointsWon = Int.random(in: 50...150)
        totalPoints += pointsWon
        shopMessage = "You won \(pointsWon) points!"
        showShopMessage = true
    }

    private func restockIfNeeded() {
        let now = Date().timeIntervalSince1970
        let day: TimeInterval = 24 * 60 * 60

        if stockText.isEmpty || lastRestock == 0 || now - lastRestock >= day {
            let freshStock = Dictionary(
                uniqueKeysWithValues: allShopPlayers.map { player in
                    let availabilityRoll = Int.random(in: 0..<100_000)
                    let isAvailable: Bool
                    if player.overall >= 90 {
                        isAvailable = availabilityRoll < 5
                    } else if player.overall >= 85 {
                        isAvailable = availabilityRoll < 20_000
                    } else {
                        isAvailable = true
                    }
                    return (player.id, isAvailable ? max(1, player.weeklyStock) : 0)
                }
            )
            saveStock(freshStock)
            lastRestock = now
        }
    }

    private func dailyStockChance(for player: SoccerPlayer) -> Int {
        switch player.id {
        case "ronaldo", "messi", "pele":
            1
        case "ronaldo_nazario", "maradona":
            2
        case "yamal", "mbappe", "haaland", "neymar":
            3
        case "van_dijk", "vinicius", "bellingham", "kane":
            4
        case "saka", "rodri", "pedri", "martinez_gk":
            10
        case "alisson", "neuer", "maignan", "raya", "costa":
            15
        case "salah":
            20
        default:
            player.overall >= 85 ? 20 : 80
        }
    }

    private func saveStock(_ stock: [String: Int]) {
        stockText = stock
            .map { "\($0.key):\($0.value)" }
            .sorted()
            .joined(separator: "|")
    }
}

struct AllDrillsView: View {
    let topics: [Topic]
    @Binding var totalPoints: Int
    @AppStorage("isProMember") private var isProMember = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.soccerNavy, Color.soccerSurface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    DrillsHeaderView(
                        totalDrills: topics.reduce(0) { $0 + $1.drills.count },
                        totalPoints: totalPoints
                    )

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(topics) { topic in
                            if topic.name == "Plus Training" && !isProMember {
                                DrillCategoryCard(
                                    name: topic.name,
                                    drillCount: topic.drills.count
                                )
                                .opacity(0.62)
                                .overlay(alignment: .topTrailing) {
                                    Label("PLUS LOCKED", systemImage: "lock.fill")
                                        .font(.caption2.weight(.heavy))
                                        .foregroundStyle(Color.soccerNavy)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color.soccerLime, in: Capsule())
                                        .padding(8)
                                }
                                .accessibilityLabel("Plus Training locked. Subscribe to Futbol Trainnier Plus in the shop.")
                            } else {
                                NavigationLink {
                                    DrillListView(
                                        topic: topic.name,
                                        drills: topic.drills,
                                        totalPoints: $totalPoints
                                    )
                                } label: {
                                    DrillCategoryCard(
                                        name: topic.name,
                                        drillCount: topic.drills.count
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .foregroundStyle(Color.soccerCream)
        .navigationTitle("Plus Training Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DrillsHeaderView: View {
    let totalDrills: Int
    let totalPoints: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "figure.soccer")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.soccerLime)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Build Your Game")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                    Text("Choose a skill and start training")
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerCream.opacity(0.72))
                }
            }

            HStack(spacing: 12) {
                Label("\(totalDrills) drills", systemImage: "list.bullet.clipboard.fill")
                Spacer()
                Label("\(totalPoints) points", systemImage: "star.fill")
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(Color.soccerLime)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [Color.soccerGreen, Color.soccerGreen.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.soccerLime.opacity(0.7), lineWidth: 2)
        }
    }
}

private struct DrillCategoryCard: View {
    let name: String
    let drillCount: Int

    private var icon: String {
        switch name {
        case "Shooting": "scope"
        case "Dribbling": "figure.soccer"
        case "Passing": "arrow.left.arrow.right"
        case "Control": "circle.grid.cross.fill"
        case "Goalkeeping": "hand.raised.fill"
        case "Defense": "shield.fill"
        default: "figure.run"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(DrillPresentation.imageName(for: name))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            LinearGradient(
                colors: [.clear, Color.soccerNavy.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Image(systemName: icon)
                    Text(name.uppercased())
                    Spacer()
                    Image(systemName: "arrow.up.right.circle.fill")
                }
                .font(.headline)
                .fontWeight(.heavy)
                .foregroundStyle(Color.soccerLime)

                Text("\(drillCount) training sessions")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text(DrillPresentation.focus(for: name))
                    .font(.caption2)
                    .foregroundStyle(Color.soccerCream.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .leading)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.soccerCream.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 8, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(drillCount) drills")
    }
}

struct DrillListView: View {
    let topic: String
    let drills: [Drill]
    @Binding var totalPoints: Int
    @AppStorage("isProMember") private var isProMember = false

    private func displayedPoints(for drillName: String) -> Int {
        let basePoints = DrillTimerView.minimumPoints(for: drillName)
        return isProMember ? basePoints * 5 / 4 : basePoints
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(drills) { drill in
                    NavigationLink {
                        DrillTimerView(drill: drill, totalPoints: $totalPoints)
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Image(systemName: "figure.soccer")
                                    .font(.system(size: 42, weight: .bold))
                                Spacer()
                                Text(topic.uppercased())
                                    .font(.caption)
                                    .fontWeight(.black)
                            }
                            .foregroundStyle(Color.soccerNavy)
                            .padding(18)
                            .background(
                                LinearGradient(
                                    colors: [Color.soccerLime, Color.soccerGreen],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                            VStack(alignment: .leading, spacing: 10) {
                                Text(drill.name)
                                    .font(.title2)
                                    .fontWeight(.heavy)

                                HStack(spacing: 16) {
                                    Label("\(DrillTimerView.duration(for: drill.name) / 60) min", systemImage: "clock.fill")
                                    Label("+\(displayedPoints(for: drill.name)) pts", systemImage: "star.fill")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.soccerLime)

                                Text(DrillPresentation.focus(for: topic))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.soccerCream.opacity(0.75))

                                HStack {
                                    Label("View full session", systemImage: "list.bullet.clipboard.fill")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.soccerLime)
                                }
                            }
                            .padding(16)
                        }
                        .foregroundStyle(Color.soccerCream)
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.soccerGreen.opacity(0.8), lineWidth: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color.soccerNavy)
        .foregroundStyle(Color.soccerCream)
        .navigationTitle(topic)
        .safeAreaPadding(.bottom, 72)
    }
}

private enum DrillPresentation {
    static let categories: [(name: String, drills: Set<String>)] = [
        ("Shooting", ["Practice Shooting", "Quick Shot", "Dribble and Shoot", "First Touch Finish", "Target Corners", "Power Shots", "Weak Foot Finishing", "Turn and Shoot", "Volley Finish", "Near Post Finish", "Cutback Finish", "Far Post Finish", "Low Driven Finish", "Rebound Finish", "One Touch Finish"]),
        ("Dribbling", ["Cone Weave", "Speed Dribble", "Box Dribble", "L-Drag Turn", "Stop and Go", "Pullback Turn", "Figure Eight", "Zigzag Sprint", "Scissors Move", "Change of Pace", "Shield and Turn", "Cruyff Turn", "V-Cut Dribble", "Double Touch", "Body Feint", "Step Over Exit", "Drag Push", "Slalom Control"]),
        ("Control", ["Juggling", "Wall Control", "Inside-Outside Touches", "Sole Roll and Push", "Aerial Control", "First Touch Gates", "Thigh Control", "Chest Control", "Cushion Touch", "Outside Foot Control", "Ball Mastery", "Toe Tap Challenge", "Sole Roll Circuit", "Tight Space Turns", "Foundation Touches", "Small Space Weave", "Bounce Control", "Half Turn Control", "Directional First Touch", "Sole Cushion", "High Ball Settle", "Turn on First Touch", "Box Ball Mastery", "Sole Tap Rhythm", "Indoor Figure Eight", "Wall Touch Challenge"]),
        ("Passing", ["Wall Passing", "One Touch Passing", "Weak Foot Passing", "Pass and Turn", "Long Passing", "Two Touch Passing", "Driven Wall Pass", "Indoor Wall Passing", "Triangle Passing", "Outside Foot Pass", "Give and Go", "Passing Gates", "First Time Pass", "Lofted Pass"]),
        ("Goalkeeping", ["Set Position Saves", "Low Diving Saves", "Goalkeeper Footwork", "Angle Positioning", "Throw Distribution", "Cross Collection", "Reaction Saves", "1v1 Goalkeeper", "High Ball Catch", "Scoop Saves", "Quick Hands", "Near Post Saves", "Collapse Dive", "Foot Saves", "Distribution Accuracy"]),
        ("Defense", ["Jockeying", "Defensive Shuffle", "Close Down", "Recovery Run", "Block and Clear", "1v1 Shadow", "Backpedal and Turn", "Interception Steps", "Clear and Recover", "Delay the Attacker", "Cover Shadow", "Tackle Timing", "Wide Channel Defense"]),
        ("Plus Training", ["Elite Finishing Circuit", "Pressure Passing", "Advanced Ball Mastery", "Explosive Dribble", "First Touch Under Pressure", "Match Speed Control", "Complete Midfielder Circuit", "Striker Movement Circuit", "Crossbar Challenge", "Around the World", "Beat the Cone", "Weak Foot Hero", "Skill Move Combo", "Rapid Fire Finishing", "Perfect Pass Streak", "Juggling Ladder"]),
        ("Workout", ["Running", "Abs Circuit", "Arm Strength", "Leg Strength", "Chest Workout", "Full Body Workout", "Agility Sprints", "Recovery Stretch", "Shuttle Runs", "Balance Circuit", "Quick Feet", "Core Stability", "Lateral Hops", "Single Leg Strength", "Mobility Flow"]),
    ]

    static func category(for drillName: String) -> String {
        categories.first(where: { $0.drills.contains(drillName) })?.name ?? "Technical"
    }

    static func imageName(for category: String) -> String {
        switch category {
        case "Indoor Training", "Plus Training":
            "DrillControl"
        default:
            "Drill" + category
        }
    }

    static func imageName(for drillName: String, category: String) -> String {
        let alternateNames: [String: Set<String>] = [
            "Shooting": ["Practice Shooting", "Power Shots", "Target Corners", "Volley Finish"],
            "Dribbling": ["Cone Weave", "Zigzag Sprint", "Figure Eight", "Speed Dribble"],
            "Passing": ["Wall Passing", "One Touch Passing", "Driven Wall Pass", "Weak Foot Passing"],
            "Goalkeeping": ["Low Diving Saves", "Reaction Saves", "Set Position Saves", "1v1 Goalkeeper"],
        ]
        return alternateNames[category]?.contains(drillName) == true
            ? "Drill\(category)2"
            : imageName(for: category)
    }

    static func equipment(for drillName: String, category: String) -> String {
        switch drillName {
        case "Juggling":
            "1 soccer ball"
        case "Ball Mastery", "Toe Tap Challenge", "Sole Roll Circuit", "Tight Space Turns":
            "1 soccer ball, small clear indoor space"
        case "Indoor Wall Passing":
            "1 soft soccer ball, safe wall, small clear indoor space"
        case "Pass and Turn":
            "1 soccer ball, wall, 3 cones"
        case "Wall Passing", "One Touch Passing", "Weak Foot Passing", "Driven Wall Pass":
            "1 soccer ball, wall, 1 marker cone"
        case "Wall Control", "Cushion Touch", "Outside Foot Control":
            "1 soccer ball, wall, 4 cones"
        case "Running", "Agility Sprints", "Shuttle Runs":
            "No equipment required"
        case "Recovery Stretch", "Abs Circuit", "Arm Strength", "Chest Workout",
             "Full Body Workout", "Leg Strength":
            "No equipment required"
        case "Goalkeeper Footwork", "Angle Positioning":
            "4 cones, goalkeeper gloves"
        case "Defensive Shuffle", "Close Down", "Recovery Run", "Backpedal and Turn":
            "2–4 cones"
        default:
            switch category {
            case "Shooting": "1 soccer ball, goal or marked target, 4–8 cones"
            case "Dribbling": "1 soccer ball, 6–8 cones"
            case "Passing": "1 soccer ball, wall or partner, 2 cones"
            case "Control": "1 soccer ball, 4 cones, wall or partner when instructed"
            case "Goalkeeping": "1 soccer ball, goalkeeper gloves, goal, partner"
            case "Defense": "1 soccer ball, 4 cones, partner when instructed"
            default: "Cones, water, exercise mat when instructed"
            }
        }
    }

    static func focus(for category: String) -> String {
        switch category {
        case "Shooting": "Technique • Accuracy • Finishing"
        case "Dribbling": "Close control • Speed • Change of direction"
        case "Passing": "First touch • Accuracy • Weight of pass"
        case "Control", "Indoor Training": "Soft touch • Balance • Ball mastery"
        case "Goalkeeping": "Set position • Handling • Reactions"
        case "Defense": "Footwork • Patience • Recovery"
        default: "Strength • Speed • Mobility"
        }
    }
}

struct DrillTimerView: View {
    private enum ScoreField: Hashable {
        case primary
        case secondary
    }

    let drill: Drill
    let weeklyTaskID: String?
    let weeklyDay: String?
    @Binding var totalPoints: Int
    @AppStorage("completedWeeklyTasks") private var completedWeeklyTasks = ""
    @AppStorage("completedWeeklyDays") private var completedWeeklyDays = ""
    @AppStorage("totalTrainingMinutes") private var totalTrainingMinutes = 0
    @AppStorage("playerXP") private var playerXP = 0
    @AppStorage("shootingXP") private var shootingXP = 0
    @AppStorage("dribblingXP") private var dribblingXP = 0
    @AppStorage("passingXP") private var passingXP = 0
    @AppStorage("controlXP") private var controlXP = 0
    @AppStorage("fitnessXP") private var fitnessXP = 0
    @AppStorage("totalGoals") private var totalGoals = 0
    @AppStorage("totalShots") private var totalShots = 0
    @AppStorage("totalPasses") private var totalPasses = 0
    @AppStorage("totalDribblingAttempts") private var totalDribblingAttempts = 0
    @AppStorage("totalControls") private var totalControls = 0
    @AppStorage("totalSessions") private var totalSessions = 0
    @AppStorage("trainingStreak") private var trainingStreak = 0
    @AppStorage("lastTrainingDate") private var lastTrainingDate = ""
    @AppStorage("rewardBoxes") private var rewardBoxes = 0
    @AppStorage("isProMember") private var isProMember = false
    @State private var timeLeft: Int
    @State private var timerActive = false
    @State private var timer: Timer?
    @State private var goalsScored = ""
    @State private var leftFootGoals = ""
    @State private var rightFootGoals = ""
    @State private var controlBoxSize = ""
    @State private var successfulTraps = ""
    @State private var attemptsCompleted = ""
    @State private var successfulAttempts = ""
    @State private var awardedPoints = 0
    @State private var awardedXP = 0
    @State private var didRecordProgress = false
    @State private var calloutCount = 0
    @State private var currentCone = 0
    @State private var calloutsActive = false
    @State private var readyCountdown = 0
    @State private var passTurnStartTask: Task<Void, Never>?
    @State private var trainingDifficulty = PassTurnDifficulty.easy
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var showScoreQuestion = false
    @State private var showThankYou = false
    @State private var shootingStarted = false
    @State private var shootingCooldown = 60
    @State private var isCompleted = false
    @FocusState private var focusedScoreField: ScoreField?

    init(
        drill: Drill,
        totalPoints: Binding<Int>,
        weeklyTaskID: String? = nil,
        weeklyDay: String? = nil
    ) {
        self.drill = drill
        self.weeklyTaskID = weeklyTaskID
        self.weeklyDay = weeklyDay
        _totalPoints = totalPoints
        _timeLeft = State(initialValue: Self.duration(for: drill.name))
    }

    static func duration(for drillName: String) -> Int {
        switch drillName {
        case "Full Body Workout", "Running":
            360
        case "Ball Mastery", "Indoor Wall Passing":
            300
        case "Sole Roll Circuit", "Tight Space Turns":
            240
        case "Toe Tap Challenge":
            180
        case "Agility Sprints", "Shuttle Runs", "Leg Strength", "Chest Workout":
            300
        case "Abs Circuit", "Arm Strength":
            240
        case "Recovery Stretch":
            180
        case "Near Post Finish", "Cutback Finish":
            300
        case "V-Cut Dribble", "Double Touch", "Triangle Passing", "Outside Foot Pass",
             "Bounce Control", "Half Turn Control", "Foundation Touches", "Small Space Weave",
             "Scoop Saves", "Quick Hands", "Interception Steps", "Clear and Recover",
             "Balance Circuit", "Quick Feet":
            240
        case "Power Shots", "Long Passing", "Low Diving Saves", "Reaction Saves":
            600
        case "Weak Foot Finishing", "1v1 Goalkeeper", "Wall Passing", "Target Corners",
             "Volley Finish", "Cross Collection":
            480
        case "Quick Shot", "Dribble and Shoot", "First Touch Finish", "Turn and Shoot",
             "Driven Wall Pass", "High Ball Catch", "Juggling":
            360
        case "Cone Weave", "Speed Dribble", "Figure Eight", "Zigzag Sprint",
             "Change of Pace", "Shield and Turn", "Cruyff Turn":
            240
        case "Inside-Outside Touches", "Stop and Go", "Pullback Turn", "Scissors Move",
             "Sole Roll and Push", "L-Drag Turn", "Goalkeeper Footwork",
             "Defensive Shuffle", "Backpedal and Turn":
            180
        default:
            300
        }
    }

    static func minimumPoints(for drillName: String) -> Int {
        let minutes = duration(for: drillName) / 60
        let isWorkout = DrillPresentation.category(for: drillName) == "Workout"
        return minutes * (isWorkout ? 30 : 35) + (isWorkout ? 150 : 0)
    }

    private var drillDuration: Int {
        let baseMinutes = Double(Self.duration(for: drill.name)) / 60
        let adjustedMinutes = max(
            2,
            Int((baseMinutes * trainingDifficulty.durationMultiplier).rounded())
        )
        return adjustedMinutes * 60
    }

    private var drillCategory: String {
        DrillPresentation.category(for: drill.name)
    }

    private var formattedTime: String {
        Self.formattedDuration(timeLeft)
    }

    private static func formattedDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var recordedAttempts: Int {
        if isPassAndTurnDrill {
            return 10
        }
        if isShootingDrill {
            return 20
        }
        if isBallControlDrill {
            return 20
        }
        return Int(attemptsCompleted) ?? 0
    }

    private var recordedSuccesses: Int {
        if isPassAndTurnDrill {
            return calloutCount
        }
        if isShootingDrill {
            return (Int(leftFootGoals) ?? 0) + (Int(rightFootGoals) ?? 0)
        }
        if isBallControlDrill {
            return Int(successfulTraps) ?? 0
        }
        return Int(successfulAttempts) ?? 0
    }

    private var accuracy: Double {
        guard recordedAttempts > 0 else { return 0 }
        return min(1, Double(recordedSuccesses) / Double(recordedAttempts))
    }

    private var basePointsAward: Int {
        let timePoints = (drillDuration / 60) * (isWorkoutDrill ? 30 : 35)
        let workoutBonus = isWorkoutDrill ? 150 : 0
        let standardPoints = timePoints
            + workoutBonus
            + trainingDifficulty.reward
            + (weeklyTaskID == nil ? 0 : 25)
        return isProMember ? standardPoints * 5 / 4 : standardPoints
    }

    private var pointsAward: Int {
        basePointsAward
    }

    private var xpAward: Int {
        (drillDuration / 60) * 10 + recordedSuccesses * 2
    }

    private var weeklyTaskAlreadyCompleted: Bool {
        guard let weeklyTaskID else { return false }
        return completedWeeklyTaskIDs.contains(weeklyTaskID)
    }

    private var completedWeeklyTaskIDs: Set<String> {
        Set(completedWeeklyTasks.split(separator: "|").map(String.init))
    }

    private var completedWeeklyDayNames: Set<String> {
        Set(completedWeeklyDays.split(separator: "|").map(String.init))
    }

    private var isShootingDrill: Bool {
        drillCategory == "Shooting"
    }

    private var isBallControlDrill: Bool {
        drillCategory == "Control"
    }

    private var isDribblingDrill: Bool {
        drillCategory == "Dribbling"
    }

    private var isWorkoutDrill: Bool {
        drillCategory == "Workout"
    }

    private var isPassAndTurnDrill: Bool {
        drill.name == "Pass and Turn"
    }

    private var isPassingDrill: Bool {
        drillCategory == "Passing"
    }

    private var isUntimedDrill: Bool {
        isShootingDrill || isBallControlDrill || isPassingDrill || isDribblingDrill
    }

    private var scoreQuestion: LocalizedStringResource {
        switch drillCategory {
        case "Shooting":
            "Record your shooting results"
        case "Passing":
            "Record your passing results"
        case "Dribbling":
            "Record your dribbling results"
        case "Control":
            "Record your ball-control results"
        default:
            "Record your completed repetitions"
        }
    }

    private var attemptLabel: LocalizedStringResource {
        switch drillCategory {
        case "Passing": "Passes attempted"
        case "Dribbling": "Dribbling attempts"
        case "Control": "Control attempts"
        default: "Repetitions attempted"
        }
    }

    private var successLabel: LocalizedStringResource {
        switch drillCategory {
        case "Passing": "Accurate passes"
        case "Dribbling": "Successful dribbles"
        case "Control": "Successful controls"
        default: "Repetitions completed"
        }
    }

    private var hasValidScore: Bool {
        if isShootingDrill {
            guard let leftGoals = Int(leftFootGoals), let rightGoals = Int(rightFootGoals) else {
                return false
            }
            return (0...10).contains(leftGoals) && (0...10).contains(rightGoals)
        }

        if isBallControlDrill {
            guard let attempts = Int(attemptsCompleted),
                  let controls = Int(successfulTraps)
            else {
                return false
            }
            return attempts > 0 && controls >= 0 && controls <= attempts
        }

        guard let attempts = Int(attemptsCompleted),
              let successes = Int(successfulAttempts)
        else {
            return false
        }
        return attempts > 0 && successes >= 0 && successes <= attempts
    }

    private var practiceRecommendation: LocalizedStringResource? {
        guard showThankYou else { return nil }

        if isPassAndTurnDrill {
            return "Great work! You completed all 10 pass, turn, and dribble callouts."
        }

        if isShootingDrill {
            guard
                let leftGoals = Int(leftFootGoals),
                let rightGoals = Int(rightFootGoals)
            else {
                return nil
            }
            return leftGoals + rightGoals >= 12
                ? "Great finishing! You can spend a little less time on shooting and work on another skill."
                : "Keep practicing your shooting. Give extra attention to the foot that scored fewer goals."
        }

        if isBallControlDrill {
            return accuracy >= 0.8
                ? "Excellent control! Most of your touches stayed under control."
                : "Keep developing your first touch and try to improve your successful-control percentage."
        }

        return accuracy >= 0.8
            ? "Strong results! Your successful attempts increased your XP."
            : "Keep practicing. More successful attempts will increase your XP."
    }

    private var canComplete: Bool {
        showThankYou
    }

    private var passAndTurnInstructions: LocalizedStringResource {
        "Stand at your starting point facing away from the wall. Take 5 steps to your left and place Cone 1. Return to the starting point, take 7 steps straight ahead, and place Cone 2. Return again, take 5 steps to your right, and place Cone 3. Stand near a wall with the ball. Press Start and pass the ball firmly against the wall. As the ball returns, listen for the spoken cone number. Receive the ball, turn quickly toward that cone, and dribble to it using small, controlled touches. Return to the starting point and get ready for the next call. Complete all 10 calls to finish the drill and earn points. Choose a difficulty that gives you enough time to return before the next call."
    }

    private var sessionInstructions: String {
        let minutes = drillDuration / 60
        let opening = "Complete the \(drill.name) drill for \(minutes) minutes. Do as many quality repetitions as you can before time ends."

        switch drill.name {
        case "Ball Mastery":
            return "\(opening) Rotate through toe taps, sole rolls, inside-outside touches, and pullbacks. Keep the ball close and avoid breakable objects."
        case "Toe Tap Challenge":
            return "\(opening) Alternate light toe taps on top of the ball. Stay balanced, keep a steady rhythm, and speed up only when every touch is controlled."
        case "Sole Roll Circuit":
            return "\(opening) Roll the ball side to side with your soles, then add pullbacks and diagonal rolls. Use both feet and keep the ball inside your space."
        case "Tight Space Turns":
            return "\(opening) Practice pullback, inside, outside, and Cruyff turns. Take two or three close touches between turns and keep your head up."
        case "Indoor Wall Passing":
            return "\(opening) Use a soft ball and a safe wall. Pass gently, control the return, alternate feet, and count your accurate passes."
        default:
            break
        }

        switch drillCategory {
        case "Shooting":
            return "\(opening) Alternate feet when possible, choose a target before each shot, and focus on accuracy before power."
        case "Dribbling":
            return "\(opening) Keep the ball close, use both feet, and stay under control when you change direction."
        case "Passing":
            return "\(opening) Count your accurate passes, alternate feet, and use a wall or partner if available."
        case "Control":
            return "\(opening) Count every clean control that keeps the ball close enough for your next move."
        case "Goalkeeping":
            return "\(opening) Work safely with gentle service, get set before each attempt, and count your clean saves."
        case "Defense":
            return "\(opening) Stay balanced, move with control, and reset your stance after every repetition."
        case "Plus Training":
            return "\(opening) Work at match speed while keeping clean technique. Slow down briefly if control drops, then build the speed again."
        default:
            return "\(opening) Use good form, rest briefly when needed, drink water, and stop if you feel pain."
        }
    }

    private var untimedDrillInstructions: LocalizedStringResource {
        switch drill.name {
        case "Weak Foot Passing":
            "Stand a few steps away from a wall and mark your starting spot with a cone. Use only your weaker foot for this drill. Point your standing foot toward the target, keep it beside the ball, lock the ankle of your passing foot, and strike through the middle of the ball with the inside of your foot. Aim for the same spot on the wall each time. Control the return when needed, reset your body, and complete 50 accurate passes with your weaker foot."
        case "One Touch Passing":
            "Stand a few steps from a wall with enough space to move safely. Pass the ball against the wall and return it with one touch without stopping it first. Keep your standing foot pointed toward the target, lock your ankle, and use the inside of your foot for accuracy. Stay light on your toes so you can adjust to every return. Complete 25 one-touch passes with your right foot, then 25 with your left foot."
        case "Wall Passing":
            "Stand a few steps from a wall and mark your starting spot with a cone. Pass the ball firmly against the wall, control the return, and play the next pass. Keep your standing foot beside the ball, lock your ankle, and aim for the same spot on the wall each time. Complete 25 passes with your right foot and 25 passes with your left foot."
        case "Wall Control":
            "Make a square control box on the ground using four cones. Choose a box size that challenges you. Stand inside the box with a wall slightly to your side. Pass the ball against the wall at an angle so it returns and pops up. As it comes back, cushion the ball with your foot and trap it inside the box. Keep your ankle firm, stay balanced, and try to stop the ball close to you. Complete 20 passes and count every successful trap that stays inside the box."
        case "Quick Shot":
            "Set up a pole or cone. Tap the ball to the right or left, and shoot. Take 20 shots in total: 10 with your right foot and 10 with your left foot."
        case "Dribble and Shoot":
            "Set up 8 cones in a line leading toward the goal. Start with the ball at the first cone, dribble around every cone using small, controlled touches, and then shoot when you reach the end. Reset the ball and repeat for 20 shots: 10 with your right foot and 10 with your left foot."
        default:
            "Take 20 shots in total: 10 with your right foot and 10 with your left foot. Place the ball just outside the penalty area and choose the corner you want to hit before each attempt. Approach the ball at a slight angle, plant your standing foot beside it, lock your ankle, keep your head steady, and strike through the ball. Focus on accuracy before power. Reset after every shot and alternate feet until you finish all 20."
        }
    }

    private var timedDrillInstructions: LocalizedStringResource? {
        switch drill.name {
        case "Speed Dribble":
            "Set up two cones far apart. Dribble to each cone quickly using small touches. Do this for 2 minutes."
        case "Cone Weave":
            "Place 8–10 cones in a line and dribble around them as fast as possible. Do this for 2 minutes."
        case "Box Dribble":
            "Use four cones to make a box about 6 steps wide and 6 steps long. Dribble anywhere inside the box for 2 minutes. Keep the ball close with small touches, use both feet, and change direction often. Practice sharp turns, quick stops, and bursts of speed without letting the ball leave the box."
        case "L-Drag Turn":
            "Place one cone and start about 4 steps away with the ball. Dribble toward the cone under control. Just before reaching it, put the sole of one foot on top of the ball and drag it backward. Turn your hips, then use the inside of the same foot to push the ball sideways, making an L shape around the cone. Accelerate away in the new direction. Reset, alternate feet, and repeat for 2 minutes."
        case "Stop and Go":
            "Place two cones about 10 steps apart. Dribble quickly toward the second cone using small touches. Halfway there, stop the ball completely with the sole of your foot, pause for one second, then push the ball forward and explode into a fast dribble. Turn at the cone and repeat in the other direction. Alternate the foot you use to stop and restart the ball for 2 minutes."
        case "Pullback Turn":
            "Place one cone and start about 5 steps away with the ball. Dribble toward the cone, then place the sole of one foot on top of the ball just before you reach it. Pull the ball backward while turning your body, take it away with the same foot, and accelerate back toward your starting point. Keep the ball close and look up after the turn. Alternate feet and repeat for 2 minutes."
        case "Wall Passing":
            "Find a wall and pass the ball against it for 5 minutes. Alternate between your right and left foot."
        case "Juggling":
            "Juggle as much as you can for 10 minutes. Try to alternate feet, keep your foot locked in, and try each day to get a better record."
        case "Inside-Outside Touches":
            "Place two cones about 8 steps apart. Dribble toward the second cone using only one foot: touch the ball across your body with the inside of the foot, then push it back outside with the outside of the same foot. Keep alternating inside and outside touches while moving forward. Turn at the cone, switch feet, and continue for 2 minutes. Stay light on your toes and keep every touch close."
        case "Sole Roll and Push":
            "Place two cones about 8 steps apart. Put the sole of one foot on the ball and roll it sideways across your body. Immediately use the inside of your other foot to push the ball forward. Follow the ball, then repeat the roll and push while moving toward the cone. Turn around, switch the rolling foot, and continue for 2 minutes. Keep your knees bent and the ball close."
        case "First Touch Finish":
            "Pass the ball against a wall, move toward the return, take one touch into space, and shoot with your second touch. Complete 10 shots with each foot."
        case "Target Corners":
            "Mark the four corners of the goal as targets. Take 20 controlled shots, calling your target before every shot. Aim for accuracy and alternate feet."
        case "Power Shots":
            "Place the ball outside the penalty area. Approach at an angle, plant beside the ball, lock your ankle, and strike through the center with your laces. Take 10 shots with each foot."
        case "Weak Foot Finishing":
            "Set the ball near the penalty spot and use only your weaker foot. Take 20 shots, aiming low into alternating corners while keeping your ankle firm."
        case "Turn and Shoot":
            "Start with your back to goal beside a cone. Roll the ball forward, turn around the cone with one touch, and shoot quickly. Complete 10 turns each way."
        case "Volley Finish":
            "Gently toss the ball in front of you, let it bounce once, then strike it toward a goal before the second bounce. Complete 10 volleys with each foot."
        case "Figure Eight":
            "Place two cones 4 steps apart. Dribble in a figure-eight pattern using both feet, keeping the ball close and looking up between turns for 2 minutes."
        case "Zigzag Sprint":
            "Set up 8 cones in a zigzag. Dribble through them at speed, cut sharply at every cone, walk back, and repeat for 2 minutes."
        case "Scissors Move":
            "Dribble toward a cone, circle one foot around the front of the ball, then push away with the outside of the other foot. Alternate sides for 2 minutes."
        case "Change of Pace":
            "Set two cones 12 steps apart. Dribble slowly for the first half, then push the ball forward and sprint to the second cone. Turn and repeat for 2 minutes."
        case "Shield and Turn":
            "Use a cone as a defender. Keep your body between the cone and ball, hold the ball for two seconds, then turn away with the sole or outside of your foot. Alternate sides for 2 minutes."
        case "Cruyff Turn":
            "Dribble toward a cone, fake a pass, then pull the ball behind your standing leg with the inside of your foot. Turn and accelerate away. Complete 10 each side."
        case "Long Passing":
            "Place a target 20 steps away. Strike under the ball with your laces to reach the target. Complete 10 long passes with each foot, focusing on direction before power."
        case "Two Touch Passing":
            "Stand near a wall. Use your first touch to control the return across your body and your second touch to pass. Complete 25 repetitions with each foot."
        case "Driven Wall Pass":
            "Mark a target on a wall. Plant beside the ball and drive a firm pass with your laces through the target. Control the return and complete 20 passes with each foot."
        case "Aerial Control":
            "Toss the ball above waist height, cushion it with your foot, and stop it within one step. Complete 10 controls with each foot."
        case "First Touch Gates":
            "Make three cone gates around you. Pass against a wall, choose a gate, and guide your first touch through it. Complete 20 controlled first touches."
        case "Thigh Control":
            "Toss the ball toward your thigh, relax your leg to cushion it downward, then control it with your foot. Complete 20 clean controls, alternating thighs."
        case "Chest Control":
            "Gently toss the ball above chest height. Lean back slightly, cushion it down with your chest, and control it with your foot. Complete 15 safe repetitions."
        case "Cushion Touch":
            "Pass firmly against a wall. As the ball returns, pull your receiving foot backward on contact so the ball stops close to you. Complete 20 touches with each foot."
        case "Outside Foot Control":
            "Pass against a wall, receive with the outside of your foot, and guide the ball across your body into space. Complete 20 controls with each foot."
        case "Set Position Saves":
            "Stand with feet shoulder-width apart, knees bent, weight forward, and hands ready. Have a partner gently roll or pass 20 balls toward you. Get set before each ball, catch securely, and bring it into your chest."
        case "Low Diving Saves":
            "Use soft grass or a padded mat. Start on your knees while a partner gently rolls the ball one step to either side. Move your hands first, land on your side instead of your elbow, secure the ball, and complete 10 safe saves each way."
        case "Goalkeeper Footwork":
            "Place four cones in a small square. Stay in your ready position and move around the square using quick side steps without crossing your feet. Reset in the center after every lap and continue for 2 minutes."
        case "Angle Positioning":
            "Set one cone in the goal center and three shooting cones in an arc. Move from the center toward each cone, staying between the ball and goal. Get set, hold for two seconds, then recover. Complete 5 rounds."
        case "Throw Distribution":
            "Set three cone targets at short, medium, and long distances. Practice 10 underarm rolls, 10 sidearm throws, and 10 overarm throws. Step toward the target and focus on accuracy."
        case "Cross Collection":
            "Work with a partner using gentle high tosses. Call for the ball, step forward, jump from one leg, raise the other knee for protection, and catch at the highest safe point. Complete 12 controlled catches."
        case "Reaction Saves":
            "Stand 3 steps from a partner in your ready position. Have them point left or right before gently rolling the ball that way. React quickly, get both hands behind the ball, and complete 20 saves."
        case "1v1 Goalkeeper":
            "Make a small goal and work with a partner. Start on your line, move forward under control as the attacker approaches, stay tall and balanced, then set before the shot. Complete 10 turns and switch roles."
        case "High Ball Catch":
            "Have a partner gently toss the ball above your head. Call for the ball, jump from one leg, catch it at the highest safe point, and secure it to your chest. Complete 15 catches."
        case "Jockeying":
            "Place two cones 8 steps apart. Face forward in a low defensive stance, stay on your toes, and shuffle between the cones without crossing your feet. Keep your body slightly sideways and repeat for 2 minutes."
        case "Defensive Shuffle":
            "Set three cones in a straight line. Shuffle quickly from the middle cone to each outside cone, touch it, and return to the middle. Stay low and balanced for 2 minutes."
        case "Close Down":
            "Place a cone 10 steps away as the attacker. Sprint toward it, then slow down 2 steps before the cone. Arrive sideways, balanced, and ready to block. Reset and repeat 12 times."
        case "Recovery Run":
            "Place one cone at the starting line and another 15 steps behind you. Begin in a defensive stance, turn quickly, sprint to the back cone, then recover into position. Complete 10 runs on each turning side."
        case "Block and Clear":
            "Place a cone as the attacker and stand 5 steps away. Close the space, plant firmly, block an imaginary shot, then clear the ball safely toward a wide target. Complete 10 clearances with each foot."
        case "1v1 Shadow":
            "Work with a partner in a small cone box. The attacker moves without tackling while the defender stays goal-side and mirrors every turn. Switch roles after 45 seconds and complete three rounds each."
        case "Backpedal and Turn":
            "Backpedal from the first cone to the second, turn over one shoulder, and sprint to the third cone. Alternate turning sides for 12 repetitions."
        case "Running":
            "Warm up by walking for 1 minute. Run at a comfortable, steady pace for 8 minutes, then walk for the final minute. Keep your shoulders relaxed, breathe steadily, and stop if you feel pain."
        case "Abs Circuit":
            "Complete three rounds: 10 crunches, a 20-second plank, 10 bicycle crunches on each side, and 10 slow leg raises. Rest for 20 seconds between rounds and keep your lower back controlled."
        case "Arm Strength":
            "Complete three rounds of 8 push-ups, 10 chair triceps dips, and a 20-second high plank. Use knee push-ups if needed and keep a straight line from your head to your knees or heels."
        case "Leg Strength":
            "Complete three rounds of 12 squats, 8 reverse lunges on each leg, 12 calf raises, and a 20-second wall sit. Keep your knees lined up with your toes and move with control."
        case "Chest Workout":
            "Complete three rounds of 8 regular push-ups, 6 wide push-ups, and a 20-second push-up hold at the top. Use your knees when needed and keep your body straight."
        case "Full Body Workout":
            "Complete three rounds of 10 squats, 8 push-ups, 10 mountain climbers on each side, 8 reverse lunges on each leg, and a 20-second plank. Rest for 30 seconds between rounds."
        case "Agility Sprints":
            "Place two cones 10 steps apart. Sprint to the second cone, slow down under control, and walk back. Repeat 8 times, resting for 20 seconds between sprints."
        case "Recovery Stretch":
            "Move gently through calf, quadriceps, hamstring, hip, chest, and shoulder stretches. Hold each stretch for 20 seconds per side without bouncing, breathe slowly, and never stretch into pain."
        case "Shuttle Runs":
            "Place two cones 10 steps apart. Sprint to the far cone, touch the ground, and sprint back. Complete 8 shuttles with 20 seconds of rest between rounds."
        case "Near Post Finish", "Cutback Finish":
            "Use a ball, a safe goal, and one marker. Focus on a controlled setup touch and accurate finishing."
        case "V-Cut Dribble", "Double Touch":
            "Use a ball and two markers. Repeat the move with both feet while keeping the ball close."
        case "Triangle Passing", "Outside Foot Pass":
            "Use a wall or partner and nearby markers. Focus on clean technique and accurate passes."
        case "Bounce Control", "Half Turn Control":
            "Use a ball and a safe space. Cushion every touch and move the ball into space under control."
        case "Foundation Touches", "Small Space Weave":
            "Use a soft ball in a clear indoor space. Stay light on your feet and keep every touch close."
        case "Scoop Saves", "Quick Hands":
            "Work with a partner using gentle service. Get set before each ball and secure it safely."
        case "Interception Steps", "Clear and Recover":
            "Use markers to practice reading the pass, stepping in under control, and recovering your position."
        case "Balance Circuit", "Quick Feet":
            "Move with control, keep your knees soft, and rest briefly whenever your form starts to drop."
        default:
            nil
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 64, weight: .bold))
                    Text(drillCategory.uppercased())
                        .font(.headline)
                        .fontWeight(.black)
                }
                .foregroundStyle(Color.soccerNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .background(
                    LinearGradient(
                        colors: [Color.soccerLime, Color.soccerGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Text(drill.name)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Picker("Difficulty", selection: $trainingDifficulty) {
                    ForEach(PassTurnDifficulty.allCases) { difficulty in
                        Text(difficulty.rawValue)
                            .tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .disabled(timerActive || shootingStarted || calloutsActive)
                .onChange(of: trainingDifficulty) { _, _ in
                    guard !timerActive, !shootingStarted, !calloutsActive else { return }
                    timeLeft = drillDuration
                    shootingCooldown = drillDuration
                }

                HStack(spacing: 10) {
                    sessionFact(
                        title: "DURATION",
                        value: Self.formattedDuration(drillDuration),
                        icon: "clock.fill"
                    )
                    sessionFact(
                        title: "LEVEL",
                        value: "DEVELOPING",
                        icon: "chart.bar.fill"
                    )
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 14) {
                    Label(DrillPresentation.focus(for: drillCategory), systemImage: "scope")
                    Label(
                        DrillPresentation.equipment(for: drill.name, category: drillCategory),
                        systemImage: "shippingbox.fill"
                    )
                    Label("Quality first: slow down if your technique breaks.", systemImage: "lightbulb.fill")
                }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.soccerSurface)
                .clipShape(.rect(cornerRadius: 18))
                .padding(.horizontal, 20)

                Text("Reward: \(pointsAward) points")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.soccerGreen)

                Label(
                    "Keep your device on and unlocked during the drill so the screen does not turn off.",
                    systemImage: "iphone.gen3.radiowaves.left.and.right"
                )
                .font(.headline)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.soccerGold.opacity(0.18))
                .clipShape(.rect(cornerRadius: 14))
                .padding(.horizontal, 20)

            if isPassAndTurnDrill {
                Text(passAndTurnInstructions)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(24)
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.black, lineWidth: 3)
                    }
                    .padding(.horizontal, 20)

                Text(
                    "Next call every \(Int(trainingDifficulty.calloutInterval)) seconds • Reward: \(pointsAward) points"
                )
                .font(.headline)

                if calloutsActive || calloutCount > 0 {
                    Text(
                        currentCone > 0
                            ? "Cone \(currentCone)"
                            : readyCountdown > 0 ? "Ready in \(readyCountdown)" : "Get ready"
                    )
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                    Text("Callout \(calloutCount) of 10")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                if !isCompleted {
                    Button(calloutsActive ? "Stop" : "Start") {
                        if calloutsActive {
                            stopPassAndTurn()
                        } else {
                            startPassAndTurn()
                        }
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(calloutsActive ? Color.red : Color.black)
                    .foregroundStyle(Color.soccerCream)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 40)
                }
            } else if isUntimedDrill {
                Text(sessionInstructions)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(24)
                    .background(Color.soccerSurface)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.black, lineWidth: 3)
                    }
                    .padding(.horizontal, 20)

                if !shootingStarted {
                    Button("Start") {
                        goalsScored = ""
                        leftFootGoals = ""
                        rightFootGoals = ""
                        controlBoxSize = ""
                        successfulTraps = ""
                        attemptsCompleted = ""
                        successfulAttempts = ""
                        showThankYou = false
                        isCompleted = false
                        didRecordProgress = false
                        shootingStarted = true
                        shootingCooldown = drillDuration
                        timer?.invalidate()
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                            if shootingCooldown > 1 {
                                shootingCooldown -= 1
                            } else {
                                shootingCooldown = 0
                                timer.invalidate()
                            }
                        }
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.soccerGreen)
                    .foregroundStyle(Color.soccerCream)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 40)
                } else {
                    Text(
                        shootingCooldown > 0
                            ? "Done available in \(shootingCooldown) seconds"
                            : "You can finish the drill now"
                    )
                    .font(.headline)

                    Button("Done") {
                        finishWithoutScoreQuestion()
                    }
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(shootingCooldown == 0 ? Color.soccerGreen : Color.gray)
                    .foregroundStyle(Color.soccerCream)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 40)
                    .disabled(shootingCooldown > 0)
                }
            } else {
                Group {
                    Text(sessionInstructions)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(24)
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.black, lineWidth: 3)
                        }
                        .padding(.horizontal, 20)
                }

                Text(formattedTime)
                    .font(.system(size: 64, weight: .bold, design: .rounded))

                Button(timerActive ? "Stop" : "Start") {
                    if timerActive {
                        timer?.invalidate()
                        timerActive = false
                    } else {
                        timerActive = true
                        goalsScored = ""
                        attemptsCompleted = ""
                        successfulAttempts = ""
                        showThankYou = false
                        isCompleted = false
                        didRecordProgress = false
                        timeLeft = drillDuration
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                            if timeLeft > 1 {
                                timeLeft -= 1
                            } else {
                                timeLeft = 0
                                timer.invalidate()
                                timerActive = false
                                finishTimedDrill()
                            }
                        }
                    }
                }
                .font(.title2)
                .padding()
                .background(timerActive ? Color.red : Color.black)
                .foregroundStyle(Color.soccerCream)
                .clipShape(.rect(cornerRadius: 12))
            }

            if showThankYou {
                Text("Good job, keep it up!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soccerGreen)

                if let practiceRecommendation {
                    Text(practiceRecommendation)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 14))
                        .padding(.horizontal, 20)
                }
            }

            if canComplete {
                if isCompleted || weeklyTaskAlreadyCompleted {
                    Text("Completed! +\(awardedPoints) points • +\(awardedXP) XP")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.soccerGreen)
                } else {
                    Button("Complete") {
                        completeDrill()
                    }
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.soccerGreen)
                    .foregroundStyle(Color.soccerCream)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 40)
                }
            }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 104)
        }
        .foregroundStyle(Color.soccerCream)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.soccerNavy.ignoresSafeArea())
        .onDisappear {
            timer?.invalidate()
            passTurnStartTask?.cancel()
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func sessionFact(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.soccerLime)
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(10)
        .background(Color.soccerSurface)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var scoreEntrySheet: some View {
        VStack(spacing: 24) {
            Text(scoreQuestion)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            if isShootingDrill {
                TextField("Left-foot goals out of 10", text: $leftFootGoals)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .primary)
                    .textFieldStyle(.roundedBorder)
                TextField("Right-foot goals out of 10", text: $rightFootGoals)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .secondary)
                    .textFieldStyle(.roundedBorder)
            } else if isBallControlDrill {
                TextField("Control attempts", text: $attemptsCompleted)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .primary)
                    .textFieldStyle(.roundedBorder)
                TextField("Successful controls", text: $successfulTraps)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .secondary)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(attemptLabel, text: $attemptsCompleted)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .primary)
                    .textFieldStyle(.roundedBorder)
                TextField(successLabel, text: $successfulAttempts)
                    .keyboardType(.numberPad)
                    .focused($focusedScoreField, equals: .secondary)
                    .textFieldStyle(.roundedBorder)
            }

            Text("Points stay fixed. XP is calculated from your successful results and \(drillDuration / 60) minutes of training.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Save Results") {
                focusedScoreField = nil
                showScoreQuestion = false
                showThankYou = true
            }
            .font(.title2)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(hasValidScore ? Color.soccerGreen : Color.gray)
            .foregroundStyle(Color.white)
            .clipShape(.rect(cornerRadius: 14))
            .disabled(!hasValidScore)
        }
        .padding(32)
        .foregroundStyle(Color.soccerCream)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.soccerNavy.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedScoreField = nil
                }
            }
        }
        .onAppear {
            Task { @MainActor in
                await Task.yield()
                focusedScoreField = .primary
            }
        }
    }

    private func finishTimedDrill() {
        if isWorkoutDrill {
            attemptsCompleted = "1"
            successfulAttempts = "1"
            showThankYou = true
        } else {
            finishWithoutScoreQuestion()
        }
    }

    private func finishWithoutScoreQuestion() {
        focusedScoreField = nil
        showThankYou = true
    }

    private func startPassAndTurn() {
        timer?.invalidate()
        passTurnStartTask?.cancel()
        speechSynthesizer.stopSpeaking(at: .immediate)

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? audioSession.setActive(true)
        calloutCount = 0
        currentCone = 0
        readyCountdown = 5
        isCompleted = false
        didRecordProgress = false
        showThankYou = false
        calloutsActive = true

        passTurnStartTask = Task { @MainActor in
            for seconds in stride(from: 5, through: 1, by: -1) {
                guard calloutsActive else { return }
                readyCountdown = seconds

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }

            guard calloutsActive else { return }
            readyCountdown = 0
            makeConeCallout()

            timer = Timer.scheduledTimer(
                withTimeInterval: trainingDifficulty.calloutInterval,
                repeats: true
            ) { timer in
                if calloutCount < 10 {
                    makeConeCallout()
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    private func stopPassAndTurn() {
        timer?.invalidate()
        passTurnStartTask?.cancel()
        speechSynthesizer.stopSpeaking(at: .immediate)
        readyCountdown = 0
        calloutsActive = false
    }

    private func makeConeCallout() {
        guard calloutsActive, calloutCount < 10 else { return }

        let availableCones = (1...3).filter { $0 != currentCone }
        let cone = availableCones.randomElement() ?? 1
        currentCone = cone
        calloutCount += 1

        let utterance = AVSpeechUtterance(string: "Pass, then cone \(cone)")
        utterance.voice = AVSpeechSynthesisVoice.speechVoices().first {
            $0.language == "en-US" && $0.name.localizedCaseInsensitiveContains("Samantha")
        } ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.15
        utterance.volume = 1
        speechSynthesizer.speak(utterance)

        if calloutCount == 10 {
            timer?.invalidate()
            calloutsActive = false
            showThankYou = true
            completeDrill()
        }
    }

    private func completeDrill() {
        if let weeklyTaskID, let weeklyDay {
            var taskIDs = completedWeeklyTaskIDs
            guard !taskIDs.contains(weeklyTaskID) else {
                isCompleted = true
                return
            }

            taskIDs.insert(weeklyTaskID)
            completedWeeklyTasks = taskIDs.sorted().joined(separator: "|")
            recordProgress()

            let completedTasksForDay = taskIDs.filter {
                $0.hasPrefix("\(weeklyDay)-")
            }.count
            var completedDays = completedWeeklyDayNames

            if completedTasksForDay >= 3 && !completedDays.contains(weeklyDay) {
                completedDays.insert(weeklyDay)
                completedWeeklyDays = completedDays.sorted().joined(separator: "|")
            }
        } else {
            recordProgress()
        }

        isCompleted = true
    }

    private func recordProgress() {
        guard !didRecordProgress else { return }
        didRecordProgress = true

        let previousLevel = playerXP / 500 + 1
        awardedPoints = pointsAward
        awardedXP = xpAward
        totalPoints += pointsAward
        playerXP += xpAward
        totalTrainingMinutes += drillDuration / 60
        totalSessions += 1

        switch drillCategory {
        case "Shooting":
            shootingXP += xpAward
            totalGoals += recordedSuccesses
            totalShots += recordedAttempts
        case "Dribbling":
            dribblingXP += xpAward
            totalDribblingAttempts += recordedAttempts
        case "Passing":
            passingXP += xpAward
            totalPasses += recordedSuccesses
        case "Control":
            controlXP += xpAward
            totalControls += recordedSuccesses
        case "Workout":
            fitnessXP += xpAward
        default:
            break
        }

        updateTrainingStreak()

        let newLevel = playerXP / 500 + 1
        if newLevel > previousLevel {
            let levelsGained = newLevel - previousLevel
            rewardBoxes += levelsGained
        }
    }

    private func updateTrainingStreak() {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"

        let today = formatter.string(from: Date())
        guard lastTrainingDate != today else { return }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        trainingStreak = lastTrainingDate == formatter.string(from: yesterday)
            ? trainingStreak + 1
            : 1
        lastTrainingDate = today
    }
}

#Preview {
    ContentView()
}

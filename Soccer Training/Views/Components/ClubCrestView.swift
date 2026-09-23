// ClubCrestView.swift
// Loads and displays a favorite team's crest from Wikipedia, with a shield
// placeholder while loading or if no image is available.
// Used by HomeDashboardView and ProfileView.

import SwiftUI

struct ClubCrestView: View {
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

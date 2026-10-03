// PlayerPhotoView.swift
// Loads a real-world photo for players that have one, falling back to a
// generic person icon otherwise. Used across MyTeamView, OpponentTeamView,
// and the Store views.

import SwiftUI

struct PlayerPhotoView: View {
    let player: SoccerPlayer?
    let width: CGFloat
    let height: CGFloat
    let isCircular: Bool
    @State private var photoURL: URL?

    /// The usual circular portrait, used everywhere except the player card.
    init(player: SoccerPlayer?, size: CGFloat) {
        self.player = player
        self.width = size
        self.height = size
        self.isCircular = true
    }

    /// A rectangular render at an arbitrary aspect ratio, for the player
    /// card's wide bleeding photo (which fades into the card instead of
    /// sitting in a circle).
    init(player: SoccerPlayer?, cardWidth: CGFloat, cardHeight: CGFloat) {
        self.player = player
        self.width = cardWidth
        self.height = cardHeight
        self.isCircular = false
    }

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
        .frame(width: width, height: height)
        .clipShape(isCircular ? AnyShape(Circle()) : AnyShape(Rectangle()))
        .task(id: player?.id) {
            photoURL = await loadPhotoURL()
        }
    }

    private var placeholder: some View {
        Image(systemName: player == nil ? "person.crop.circle.badge.plus" : "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.soccerCream.opacity(0.7))
            .padding(isCircular ? 4 : width * 0.22)
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

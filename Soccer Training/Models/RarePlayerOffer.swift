// RarePlayerOffer.swift
// The rare-player drop offers shown in the Store's points-purchase section.

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

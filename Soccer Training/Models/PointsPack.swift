// PointsPack.swift
// Purchasable points packs and the weekly cash-store player offers.

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

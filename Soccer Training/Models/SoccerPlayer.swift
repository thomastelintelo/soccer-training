// SoccerPlayer.swift
// The player model and the catalog of every player available in the app.

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

// MyTeamView.swift
// The player's Starting 11 on a soccer field, with substitution pickers.

import SwiftUI

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

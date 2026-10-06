// DrillLibraryView.swift
// The searchable drill library. Search matches a drill's name, skill, topic,
// equipment, level, and player count, and every word has to match. A filter
// sheet narrows the list by skill, difficulty, age, position, duration,
// players, equipment you have, and indoor. Scopes show all drills, favorites,
// or what you've completed recently.

import SwiftUI

struct DrillFilters: Equatable {
    enum AgeGroup: String, CaseIterable, Identifiable {
        case underTwelve = "Under 12"
        case twelveToThirteen = "12–13"
        case fourteenPlus = "14+"

        var id: String { rawValue }

        /// Whether a drill with this minimum age suits a player in this group.
        func accepts(_ minimumAge: Int) -> Bool {
            switch self {
            case .underTwelve: minimumAge == 0
            case .twelveToThirteen: minimumAge <= 12
            case .fourteenPlus: true
            }
        }
    }

    enum DurationBand: String, CaseIterable, Identifiable {
        case quick = "3–4 min"
        case standard = "5–6 min"
        case long = "7+ min"

        var id: String { rawValue }

        func contains(_ minutes: Int) -> Bool {
            switch self {
            case .quick: minutes <= 4
            case .standard: (5...6).contains(minutes)
            case .long: minutes >= 7
            }
        }
    }

    var skills: Set<String> = []
    var levels: Set<String> = []
    var ages: Set<String> = []
    var positions: Set<String> = []
    var durations: Set<String> = []
    var players: Set<String> = []
    var equipmentLabels: Set<String> = []
    var indoorOnly = false

    var activeCount: Int {
        skills.count + levels.count + ages.count + positions.count + durations.count
            + players.count + equipmentLabels.count + (indoorOnly ? 1 : 0)
    }

    func matches(_ info: DrillInfo) -> Bool {
        if !skills.isEmpty && !skills.contains(info.skill) { return false }
        if !levels.isEmpty && !levels.contains(info.level.rawValue) { return false }
        if !ages.isEmpty && !ages.contains(where: { AgeGroup(rawValue: $0)?.accepts(info.minimumAge) == true }) {
            return false
        }
        // Drills with no position list suit everyone, so they match any position filter.
        if !positions.isEmpty && !info.positions.isEmpty && positions.isDisjoint(with: info.positions) {
            return false
        }
        if !durations.isEmpty && !durations.contains(where: { DurationBand(rawValue: $0)?.contains(info.minutes) == true }) {
            return false
        }
        if !players.isEmpty && !players.contains(info.playerCount.rawValue) { return false }
        if !equipmentLabels.isEmpty && !info.equipment.isSubset(of: owned) { return false }
        if indoorOnly && !info.isIndoor { return false }
        return true
    }

    /// The equipment the player says they have, from the selected labels.
    private var owned: EquipmentNeeds {
        EquipmentNeeds.options
            .filter { equipmentLabels.contains($0.label) }
            .reduce(into: EquipmentNeeds()) { $0.insert($1.need) }
    }
}

struct DrillLibraryView: View {
    @Binding var totalPoints: Int
    @AppStorage(FavoriteDrills.storageKey) private var favoritesText = ""
    /// Read so the list redraws when a drill is completed elsewhere.
    @AppStorage(TrainingLog.versionKey) private var logVersion = 0

    @State private var searchText = ""
    @State private var filters = DrillFilters()
    @State private var scope: LibraryScope = .all
    @State private var sort: LibrarySort = .suggested
    @State private var isShowingFilters = false

    private enum LibraryScope: String, CaseIterable, Identifiable {
        case all = "All"
        case favorites = "Favorites"
        case recent = "Recent"

        var id: String { rawValue }
    }

    private enum LibrarySort: String, CaseIterable, Identifiable {
        case suggested = "Library order"
        case shortest = "Shortest first"
        case alphabetical = "A–Z"

        var id: String { rawValue }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    private var favorites: Set<String> {
        FavoriteDrills.set(from: favoritesText)
    }

    private var scopedDrills: [DrillInfo] {
        switch scope {
        case .all:
            DrillCatalog.library
        case .favorites:
            DrillCatalog.library.filter { favorites.contains($0.name) }
        case .recent:
            TrainingLog.recentlyCompleted(TrainingLog.entries(), limit: 40).map { DrillCatalog.info(for: $0) }
        }
    }

    private var results: [DrillInfo] {
        let words = searchText
            .lowercased()
            .split(separator: " ")
            .map(String.init)

        let matching = scopedDrills.filter { info in
            guard filters.matches(info) else { return false }
            guard !words.isEmpty else { return true }
            let haystack = [
                info.name, info.skill, info.topic, info.equipmentText, info.level.rawValue,
                info.playerCount.rawValue, info.isIndoor ? "indoor" : "",
            ].joined(separator: " ").lowercased()
            return words.allSatisfy { haystack.contains($0) }
        }

        // Recent keeps the order drills were completed in. Everything else follows the chosen sort.
        guard scope != .recent else { return matching }
        switch sort {
        case .suggested:
            return matching
        case .shortest:
            return matching.sorted { $0.durationSeconds < $1.durationSeconds }
        case .alphabetical:
            return matching.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SearchField(text: $searchText, prompt: "Search drills, skills, or equipment")

                Picker("Scope", selection: $scope) {
                    ForEach(LibraryScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)

                toolbar

                if results.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(results) { info in
                            ZStack(alignment: .topTrailing) {
                                NavigationLink {
                                    DrillDetailView(drillName: info.name, totalPoints: $totalPoints)
                                } label: {
                                    DrillCardView(info: info)
                                }
                                .buttonStyle(.plain)

                                FavoriteButton(isFavorite: favorites.contains(info.name)) {
                                    favoritesText = FavoriteDrills.toggled(info.name, in: favoritesText)
                                }
                                .padding(8)
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 72)
        }
        .background(Color.soccerBackground)
        .foregroundStyle(Color.soccerText)
        .sheet(isPresented: $isShowingFilters) {
            DrillFilterSheet(filters: $filters) { candidate in
                DrillCatalog.library.filter { candidate.matches($0) }.count
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button {
                isShowingFilters = true
            } label: {
                Label(
                    filters.activeCount > 0 ? "Filters (\(filters.activeCount))" : "Filters",
                    systemImage: "line.3.horizontal.decrease.circle.fill"
                )
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(filters.activeCount > 0 ? Color.soccerAccent : Color.soccerSurface, in: Capsule())
                .foregroundStyle(filters.activeCount > 0 ? Color.white : Color.soccerText)
            }
            .buttonStyle(.plain)

            if scope != .recent {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(LibrarySort.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.soccerAccent)
                }
            }

            Spacer()

            Text("\(results.count) drills")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.soccerText.opacity(0.6))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: scope == .favorites ? "heart" : (scope == .recent ? "clock" : "magnifyingglass"))
                .font(.largeTitle)
                .foregroundStyle(Color.soccerAccent)
            Text(emptyTitle)
                .font(.headline)
            Text(emptyDetail)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.soccerText.opacity(0.6))
            if filters.activeCount > 0 || !searchText.isEmpty {
                Button("Clear search and filters") {
                    searchText = ""
                    filters = DrillFilters()
                }
                .font(.subheadline)
                .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyTitle: String {
        switch scope {
        case .favorites: "No favorites yet"
        case .recent: "No completed drills yet"
        case .all: "No drills match"
        }
    }

    private var emptyDetail: String {
        switch scope {
        case .favorites: "Tap the heart on any drill to save it here."
        case .recent: "Drills you finish will show up here."
        case .all: "Try fewer filters or a different search."
        }
    }
}

private struct DrillFilterSheet: View {
    @Binding var filters: DrillFilters
    let countFor: (DrillFilters) -> Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    section("Skill") {
                        ChipSelector(options: DrillCatalog.skills, selection: $filters.skills)
                    }
                    section("Difficulty") {
                        ChipSelector(options: DrillLevel.allCases.map(\.rawValue), selection: $filters.levels)
                    }
                    section("Age") {
                        ChipSelector(options: DrillFilters.AgeGroup.allCases.map(\.rawValue), selection: $filters.ages)
                    }
                    section("Position") {
                        ChipSelector(options: DrillCatalog.positions, selection: $filters.positions)
                    }
                    section("Duration") {
                        ChipSelector(options: DrillFilters.DurationBand.allCases.map(\.rawValue), selection: $filters.durations)
                    }
                    section("Number of players") {
                        ChipSelector(options: PlayerCount.allCases.map(\.rawValue), selection: $filters.players)
                    }
                    section("Equipment I have") {
                        ChipSelector(options: EquipmentNeeds.options.map(\.label), selection: $filters.equipmentLabels)
                        Text("Shows drills you can do with only the equipment you select, plus a ball.")
                            .font(.caption)
                            .foregroundStyle(Color.soccerText.opacity(0.55))
                    }
                    section("Setting") {
                        Toggle("Indoor drills only", isOn: $filters.indoorOnly)
                            .tint(Color.soccerAccent)
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        withAnimation { filters = DrillFilters() }
                    }
                    .disabled(filters.activeCount == 0)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    dismiss()
                } label: {
                    Text("Show \(countFor(filters)) drills")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.soccerAccent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .foregroundStyle(Color.soccerText)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.heavy)
            content()
        }
    }
}

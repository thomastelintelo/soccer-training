// DrillListView.swift
// Lists every drill in a chosen topic, with duration and point preview.

import SwiftUI

private enum DrillSortOrder: String, CaseIterable, Identifiable {
    case `default` = "Suggested"
    case shortest = "Shortest first"
    case mostPoints = "Most points"
    case alphabetical = "A–Z"

    var id: String { rawValue }
}

private enum DrillDifficultyFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: Self { self }
}

struct DrillListView: View {
    let topic: String
    let drills: [Drill]
    @Binding var totalPoints: Int
    @State private var searchText = ""
    @State private var difficultyFilter = DrillDifficultyFilter.all
    @State private var sortOrder = DrillSortOrder.default

    private func displayedPoints(for drillName: String) -> Int {
        DrillTimerView.minimumPoints(for: drillName)
    }

    /// Buckets this category's own drills into thirds by duration, so every
    /// category has a real, visible spread across Beginner/Intermediate/
    /// Advanced — a fixed global time threshold left most categories with
    /// nearly everything in one bucket, making the filter look broken.
    private var difficultyByDrillName: [String: DrillDifficultyFilter] {
        // Most drills share the same fallback duration, so sorting by
        // duration alone left ties decided by declaration order — every
        // "default" drill from the same part of the list landed in the same
        // bucket. Breaking ties with a stable per-name hash spreads them out.
        let sortedByDuration = drills.sorted {
            let lhs = DrillTimerView.duration(for: $0.name)
            let rhs = DrillTimerView.duration(for: $1.name)
            if lhs != rhs { return lhs < rhs }
            return StableHash.value($0.name) < StableHash.value($1.name)
        }
        let count = sortedByDuration.count
        guard count > 0 else { return [:] }

        var result: [String: DrillDifficultyFilter] = [:]
        for (index, drill) in sortedByDuration.enumerated() {
            let fraction = Double(index) / Double(count)
            if fraction < 1.0 / 3.0 {
                result[drill.name] = .beginner
            } else if fraction < 2.0 / 3.0 {
                result[drill.name] = .intermediate
            } else {
                result[drill.name] = .advanced
            }
        }
        return result
    }

    private var filteredDrills: [Drill] {
        var result = drills

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        if difficultyFilter != .all {
            let byName = difficultyByDrillName
            result = result.filter { byName[$0.name] == difficultyFilter }
        }

        switch sortOrder {
        case .default:
            break
        case .shortest:
            result.sort { DrillTimerView.duration(for: $0.name) < DrillTimerView.duration(for: $1.name) }
        case .mostPoints:
            result.sort { displayedPoints(for: $0.name) > displayedPoints(for: $1.name) }
        case .alphabetical:
            result.sort { $0.name < $1.name }
        }

        return result
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            // A hand-built segmented control, not a native `Picker`, so a tap
            // here can never be misrouted to a drill card below it.
            HStack(spacing: 4) {
                ForEach(DrillDifficultyFilter.allCases) { difficulty in
                    Button {
                        withAnimation(.snappy) {
                            difficultyFilter = difficulty
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if difficultyFilter == difficulty {
                                Image(systemName: "checkmark")
                            }
                            Text(difficulty.rawValue)
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(.rect)
                        .background(
                            difficultyFilter == difficulty ? Color.soccerAccent : Color.soccerSurface,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(difficultyFilter == difficulty ? Color.white : Color.soccerText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(difficultyFilter == difficulty ? .isSelected : [])
                }
            }
            .padding(4)
            .background(Color.soccerSurfaceStrong, in: RoundedRectangle(cornerRadius: 10))

            Text(
                difficultyFilter == .all
                    ? "Showing all \(filteredDrills.count) drills"
                    : "Showing \(filteredDrills.count) \(difficultyFilter.rawValue.lowercased()) drills"
            )
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Color.soccerText.opacity(0.7))
            .contentTransition(.numericText())

            Menu {
                ForEach(DrillSortOrder.allCases) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        if sortOrder == order {
                            Label(order.rawValue, systemImage: "checkmark")
                        } else {
                            Text(order.rawValue)
                        }
                    }
                }
            } label: {
                Label("Sort: \(sortOrder.rawValue)", systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.soccerAccent)
            }
        }
        .padding(.horizontal)
    }

    var body: some View {
        ScrollView {
            NavigationLink {
                SessionView(title: "\(topic) Session", category: topic, drills: drills, totalPoints: $totalPoints)
            } label: {
                Label("Start \(topic) Session", systemImage: "list.bullet.clipboard.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.soccerAccent)
                    .foregroundStyle(Color.white)
                    .clipShape(.rect(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 4)

            filterBar

            LazyVStack(spacing: 16) {
                if filteredDrills.isEmpty {
                    Text("No drills match your filters.")
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerText.opacity(0.6))
                        .padding(.top, 20)
                }

                ForEach(filteredDrills) { drill in
                    NavigationLink {
                        DrillTimerView(drill: drill, totalPoints: $totalPoints)
                    } label: {
                        VStack(alignment: .leading, spacing: 0) {
                            ZStack(alignment: .bottomLeading) {
                                Image(DrillPresentation.imageName(for: drill.name, category: topic))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .overlay {
                                        // Only a handful of stock photos ship with the app, so
                                        // tint each drill's shared photo with its own stable hue.
                                        Color(hue: DrillPresentation.photoHue(for: drill.name), saturation: 0.6, brightness: 0.9)
                                            .opacity(0.4)
                                            .blendMode(.hue)
                                    }
                                    .clipped()

                                LinearGradient(
                                    colors: [.clear, Color.black.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )

                                HStack {
                                    Image(systemName: DrillPresentation.icon(for: topic))
                                        .font(.system(size: 28, weight: .bold))
                                    Spacer()
                                    Text(topic.uppercased())
                                        .font(.caption)
                                        .fontWeight(.black)
                                }
                                .padding(14)
                            }
                            .frame(height: 100)
                            .foregroundStyle(.white)
                            .overlay(alignment: .topTrailing) {
                                if DrillPresentation.isIndoor(drill.name) {
                                    Label("Indoor", systemImage: "house.fill")
                                        .font(.caption2.weight(.heavy))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.white, in: .capsule)
                                        .foregroundStyle(Color.soccerAccent)
                                        .padding(8)
                                }
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text(drill.name)
                                    .font(.title2)
                                    .fontWeight(.heavy)

                                HStack(spacing: 16) {
                                    Label("\(DrillTimerView.duration(for: drill.name) / 60) min", systemImage: "clock.fill")
                                    Label("+\(displayedPoints(for: drill.name)) pts", systemImage: "star.fill")
                                    Label(
                                        difficultyByDrillName[drill.name]?.rawValue ?? "",
                                        systemImage: "gauge.with.dots.needle.50percent"
                                    )
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.soccerAccent)

                                Text(DrillPresentation.focus(for: topic))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.soccerText.opacity(0.65))

                                HStack {
                                    Label("View full session", systemImage: "list.bullet.clipboard.fill")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.soccerAccent)
                                }
                            }
                            .padding(16)
                        }
                        .foregroundStyle(Color.soccerText)
                        .background(Color.soccerSurface)
                        .clipShape(.rect(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(SoccerBackgroundView())
        .foregroundStyle(Color.soccerText)
        .navigationTitle(topic)
        .safeAreaPadding(.bottom, 72)
        .searchable(text: $searchText, prompt: "Search \(topic) drills")
    }
}

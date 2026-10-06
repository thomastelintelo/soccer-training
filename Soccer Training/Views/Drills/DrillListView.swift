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

struct DrillListView: View {
    let topic: String
    let drills: [Drill]
    @Binding var totalPoints: Int
    @AppStorage("isProMember") private var isProMember = false
    @State private var searchText = ""
    @State private var difficultyFilter = "All"
    @State private var sortOrder = DrillSortOrder.default

    private let difficulties = ["All", "Beginner", "Intermediate", "Advanced"]

    private func displayedPoints(for drillName: String) -> Int {
        DrillTimerView.proAdjustedPoints(
            base: DrillTimerView.minimumPoints(for: drillName),
            isProMember: isProMember
        )
    }

    /// Buckets this category's own drills into thirds by duration, so every
    /// category has a real, visible spread across Beginner/Intermediate/
    /// Advanced — a fixed global time threshold left most categories with
    /// nearly everything in one bucket, making the filter look broken.
    private var difficultyByDrillName: [String: String] {
        // Many drills share a duration; break ties with a stable per-name
        // value so they spread across buckets instead of clumping together.
        let sortedByDuration = drills.sorted {
            let lhs = DrillTimerView.duration(for: $0.name)
            let rhs = DrillTimerView.duration(for: $1.name)
            if lhs != rhs { return lhs < rhs }
            return DrillPresentation.photoHue(for: $0.name) < DrillPresentation.photoHue(for: $1.name)
        }
        let count = sortedByDuration.count
        guard count > 0 else { return [:] }

        var result: [String: String] = [:]
        for (index, drill) in sortedByDuration.enumerated() {
            let fraction = Double(index) / Double(count)
            if fraction < 1.0 / 3.0 {
                result[drill.name] = "Beginner"
            } else if fraction < 2.0 / 3.0 {
                result[drill.name] = "Intermediate"
            } else {
                result[drill.name] = "Advanced"
            }
        }
        return result
    }

    private var filteredDrills: [Drill] {
        var result = drills

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        if difficultyFilter != "All" {
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
                ForEach(difficulties, id: \.self) { difficulty in
                    Button {
                        withAnimation(.snappy) { difficultyFilter = difficulty }
                    } label: {
                        Text(difficulty)
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                difficultyFilter == difficulty ? Color.soccerGreen : Color.soccerSurface,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .foregroundStyle(difficultyFilter == difficulty ? Color.white : Color.soccerCream)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.soccerNavy.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))

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
                    .foregroundStyle(Color.soccerLime)
            }
        }
        .padding(.horizontal)
    }

    var body: some View {
        let byName = difficultyByDrillName
        return ScrollView {
            filterBar

            LazyVStack(spacing: 16) {
                if filteredDrills.isEmpty {
                    Text("No drills match your filters.")
                        .font(.subheadline)
                        .foregroundStyle(Color.soccerCream.opacity(0.7))
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
                                    colors: [.clear, Color.soccerNavy.opacity(0.85)],
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
                            .foregroundStyle(Color.soccerCream)
                            .overlay(alignment: .topTrailing) {
                                if DrillPresentation.isIndoor(drill.name) {
                                    Label("Indoor", systemImage: "house.fill")
                                        .font(.caption2.weight(.heavy))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.soccerNavy.opacity(0.85), in: .capsule)
                                        .foregroundStyle(Color.soccerLime)
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
        .searchable(text: $searchText, prompt: "Search \(topic) drills")
    }
}

// SessionView.swift
// A guided session for one category: a warm-up, a handful of varied drills,
// then a cool-down, worked through in order instead of browsing one drill
// at a time.

import SwiftUI

struct SessionView: View {
    let title: String
    let category: String
    let drills: [Drill]
    var fixedDrillNames: [String]? = nil
    @Binding var totalPoints: Int
    @State private var steps: [SessionStep] = []

    var body: some View {
        List {
            Section {
                Text("Warm up, work through \(max(steps.count - 2, 0)) \(category.lowercased()) drills, then cool down. Tap a step to start it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                NavigationLink {
                    DrillTimerView(drill: Drill(name: step.drillName), totalPoints: $totalPoints)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.soccerAccent.opacity(0.15))
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundStyle(Color.soccerAccent)
                        }
                        .frame(width: 34, height: 34)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.role)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            Text(step.drillName)
                                .font(.headline)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(title)
        .onAppear {
            if steps.isEmpty {
                if let fixedDrillNames {
                    steps = SessionBuilder.steps(fixedDrillNames: fixedDrillNames)
                } else {
                    steps = SessionBuilder.steps(category: category, drills: drills)
                }
            }
        }
    }
}

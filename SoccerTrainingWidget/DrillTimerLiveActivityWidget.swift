//
//  DrillTimerLiveActivityWidget.swift
//  SoccerTrainingWidget
//
//  Lock Screen and Dynamic Island UI for the drill timer.
//

import ActivityKit
import SwiftUI
import WidgetKit

// Keep identical to "Soccer Training/DrillTimerAttributes.swift" in the app target.
struct DrillTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isFinished: Bool
    }

    var drillName: String
    var category: String
    var startDate: Date
    var endDate: Date
}

private enum DrillTimerPalette {
    static let cream = Color(red: 0.96, green: 0.99, blue: 0.97)
    static let green = Color(red: 0.00, green: 0.55, blue: 0.30)
    static let lime = Color(red: 0.65, green: 0.95, blue: 0.18)
    static let navy = Color(red: 0.02, green: 0.10, blue: 0.07)
    static let surface = Color(red: 0.06, green: 0.16, blue: 0.11)
}

private extension ActivityViewContext<DrillTimerAttributes> {
    /// The app is usually suspended when the timer ends, so also treat a stale activity as finished.
    var isTimeUp: Bool {
        state.isFinished || isStale
    }

    var timerRange: ClosedRange<Date> {
        attributes.startDate...max(attributes.startDate, attributes.endDate)
    }

    var symbolName: String {
        switch attributes.category {
        case "Shooting": "soccerball"
        case "Passing": "arrow.left.arrow.right"
        case "Control": "scope"
        case "Workout": "figure.strengthtraining.traditional"
        default: "figure.soccer"
        }
    }
}

struct DrillTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DrillTimerAttributes.self) { context in
            DrillTimerLockScreenView(context: context)
                .activityBackgroundTint(DrillTimerPalette.navy)
                .activitySystemActionForegroundColor(DrillTimerPalette.cream)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.isTimeUp ? "checkmark.circle.fill" : context.symbolName)
                        .font(.title2)
                        .foregroundStyle(DrillTimerPalette.lime)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.drillName)
                        .font(.headline)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    DrillTimerCountdownText(context: context)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(DrillTimerPalette.lime)
                        .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.isTimeUp {
                        Text("Time's up! Open the app to log your drill.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView(timerInterval: context.timerRange, countsDown: true) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        }
                        .tint(DrillTimerPalette.lime)
                        .padding(.horizontal, 4)
                    }
                }
            } compactLeading: {
                Image(systemName: context.isTimeUp ? "checkmark.circle.fill" : context.symbolName)
                    .foregroundStyle(DrillTimerPalette.lime)
            } compactTrailing: {
                DrillTimerCountdownText(context: context)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(DrillTimerPalette.lime)
                    .frame(width: 50, alignment: .trailing)
            } minimal: {
                if context.isTimeUp {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DrillTimerPalette.lime)
                } else {
                    ProgressView(timerInterval: context.timerRange, countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        Image(systemName: context.symbolName)
                            .font(.caption2)
                    }
                    .progressViewStyle(.circular)
                    .tint(DrillTimerPalette.lime)
                }
            }
            .keylineTint(DrillTimerPalette.lime)
        }
    }
}

private struct DrillTimerCountdownText: View {
    let context: ActivityViewContext<DrillTimerAttributes>

    var body: some View {
        if context.isTimeUp {
            Text("0:00")
        } else {
            Text(timerInterval: context.timerRange, countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct DrillTimerLockScreenView: View {
    let context: ActivityViewContext<DrillTimerAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: context.isTimeUp ? "checkmark" : context.symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DrillTimerPalette.lime)
                    .frame(width: 44, height: 44)
                    .background(DrillTimerPalette.surface, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.drillName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(context.isTimeUp ? "Time's up! Open the app to log your drill." : "\(context.attributes.category) drill")
                        .font(.subheadline)
                        .foregroundStyle(DrillTimerPalette.cream.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                DrillTimerCountdownText(context: context)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(DrillTimerPalette.lime)
                    .frame(maxWidth: 110, alignment: .trailing)
            }

            if !context.isTimeUp {
                ProgressView(timerInterval: context.timerRange, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(DrillTimerPalette.lime)
            }
        }
        .foregroundStyle(DrillTimerPalette.cream)
        .padding(16)
    }
}

extension DrillTimerAttributes {
    fileprivate static var preview: DrillTimerAttributes {
        DrillTimerAttributes(
            drillName: "Power Shots",
            category: "Shooting",
            startDate: .now,
            endDate: .now.addingTimeInterval(600)
        )
    }
}

#Preview("Lock Screen", as: .content, using: DrillTimerAttributes.preview) {
    DrillTimerLiveActivityWidget()
} contentStates: {
    DrillTimerAttributes.ContentState(isFinished: false)
    DrillTimerAttributes.ContentState(isFinished: true)
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: DrillTimerAttributes.preview) {
    DrillTimerLiveActivityWidget()
} contentStates: {
    DrillTimerAttributes.ContentState(isFinished: false)
}

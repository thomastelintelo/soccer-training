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
struct DrillTimerColorComponents: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

struct DrillTimerTheme: Codable, Hashable {
    var accent: DrillTimerColorComponents
    var background: DrillTimerColorComponents
    var surface: DrillTimerColorComponents
}

struct DrillTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isFinished: Bool
    }

    var drillName: String
    var category: String
    var startDate: Date
    var endDate: Date
    var theme: DrillTimerTheme
}

private enum DrillTimerPalette {
    static let text = Color(red: 0.08, green: 0.10, blue: 0.14)
}

private extension ActivityViewContext<DrillTimerAttributes> {
    /// The app is usually suspended when the timer ends, so also treat a stale activity as finished.
    var isTimeUp: Bool {
        state.isFinished || isStale
    }

    var accentColor: Color { attributes.theme.accent.color }
    var backgroundColor: Color { attributes.theme.background.color }
    var surfaceColor: Color { attributes.theme.surface.color }

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
                .activityBackgroundTint(context.backgroundColor)
                .activitySystemActionForegroundColor(DrillTimerPalette.text)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.isTimeUp ? "checkmark.circle.fill" : context.symbolName)
                        .font(.title2)
                        .foregroundStyle(context.accentColor)
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
                        .foregroundStyle(context.accentColor)
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
                        .tint(context.accentColor)
                        .padding(.horizontal, 4)
                    }
                }
            } compactLeading: {
                Image(systemName: context.isTimeUp ? "checkmark.circle.fill" : context.symbolName)
                    .foregroundStyle(context.accentColor)
            } compactTrailing: {
                DrillTimerCountdownText(context: context)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(context.accentColor)
                    .frame(width: 50, alignment: .trailing)
            } minimal: {
                if context.isTimeUp {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(context.accentColor)
                } else {
                    ProgressView(timerInterval: context.timerRange, countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        Image(systemName: context.symbolName)
                            .font(.caption2)
                    }
                    .progressViewStyle(.circular)
                    .tint(context.accentColor)
                }
            }
            .keylineTint(context.accentColor)
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
                    .foregroundStyle(context.accentColor)
                    .frame(width: 44, height: 44)
                    .background(context.surfaceColor, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.drillName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(context.isTimeUp ? "Time's up! Open the app to log your drill." : "\(context.attributes.category) drill")
                        .font(.subheadline)
                        .foregroundStyle(DrillTimerPalette.text.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                DrillTimerCountdownText(context: context)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(context.accentColor)
                    .frame(maxWidth: 110, alignment: .trailing)
            }

            if !context.isTimeUp {
                ProgressView(timerInterval: context.timerRange, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(context.accentColor)
            }
        }
        .foregroundStyle(DrillTimerPalette.text)
        .padding(16)
    }
}

extension DrillTimerAttributes {
    fileprivate static var preview: DrillTimerAttributes {
        DrillTimerAttributes(
            drillName: "Power Shots",
            category: "Shooting",
            startDate: .now,
            endDate: .now.addingTimeInterval(600),
            theme: DrillTimerTheme(
                accent: DrillTimerColorComponents(red: 0.07, green: 0.42, blue: 0.93, opacity: 1),
                background: DrillTimerColorComponents(red: 1.0, green: 1.0, blue: 1.0, opacity: 1),
                surface: DrillTimerColorComponents(red: 0.95, green: 0.96, blue: 0.98, opacity: 1)
            )
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

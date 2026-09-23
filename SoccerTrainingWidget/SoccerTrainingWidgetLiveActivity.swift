//
//  SoccerTrainingWidgetLiveActivity.swift
//  SoccerTrainingWidget
//
//  Created by Thomas Telintelo on 9/22/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SoccerTrainingWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SoccerTrainingWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SoccerTrainingWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SoccerTrainingWidgetAttributes {
    fileprivate static var preview: SoccerTrainingWidgetAttributes {
        SoccerTrainingWidgetAttributes(name: "World")
    }
}

extension SoccerTrainingWidgetAttributes.ContentState {
    fileprivate static var smiley: SoccerTrainingWidgetAttributes.ContentState {
        SoccerTrainingWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SoccerTrainingWidgetAttributes.ContentState {
         SoccerTrainingWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SoccerTrainingWidgetAttributes.preview) {
   SoccerTrainingWidgetLiveActivity()
} contentStates: {
    SoccerTrainingWidgetAttributes.ContentState.smiley
    SoccerTrainingWidgetAttributes.ContentState.starEyes
}

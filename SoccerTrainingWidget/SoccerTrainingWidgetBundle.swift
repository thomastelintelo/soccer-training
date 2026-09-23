//
//  SoccerTrainingWidgetBundle.swift
//  SoccerTrainingWidget
//
//  Created by Thomas Telintelo on 9/22/26.
//

import WidgetKit
import SwiftUI

@main
struct SoccerTrainingWidgetBundle: WidgetBundle {
    var body: some Widget {
        SoccerTrainingWidget()
        SoccerTrainingWidgetLiveActivity()
    }
}

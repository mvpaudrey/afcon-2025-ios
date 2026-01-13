//
//  LiveScoreWidgetBundle.swift
//  LiveScoreWidget
//
//  Widget Bundle for Live Score Live Activities
//

import WidgetKit
import SwiftUI

@main
struct LiveScoreWidgetBundle: WidgetBundle {
    var body: some Widget {
        LiveScoreActivityWidget()
        LiveScoreHomeWidget()
        LiveScoreScheduleWidget()
    }
}

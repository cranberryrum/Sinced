//
//  WidgetSinced2Bundle.swift
//  WidgetSinced2
//
//  Created by Aditya on 13/01/26.
//

import WidgetKit
import SwiftUI

@main
struct WidgetSinced2Bundle: WidgetBundle {
    var body: some Widget {
        // Main small widget with event selection (also used in StandBy)
        SinceSmallWidget()
        // Medium widget with two events side by side
        SincePairWidget()
        // Lock Screen: circular, rectangular and inline
        SinceLockScreenWidget()
        // Control Center, Lock Screen and Action button
        SinceResetControl()
    }
}

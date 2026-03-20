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
        // Main small widget with event selection
        SinceSmallWidget()
        
        // Control widget (if implemented)
        WidgetSinced2Control()
    }
}

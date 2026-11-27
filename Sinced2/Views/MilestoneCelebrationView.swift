//
//  MilestoneCelebrationView.swift
//  Sinced2
//
//  What a milestone or goal is, and the colours its celebration uses. The
//  celebration itself plays on home, on the counter's own card (see
//  MilestoneSpotlight).
//

import SwiftUI
import UIKit

struct MilestoneCelebration: Identifiable, Equatable {
    let eventID: UUID
    let title: String
    let theme: CardTheme
    let days: Int
    let isGoal: Bool
    let isComeback: Bool

    var id: String { "\(eventID)-\(days)" }

    /// Where the count starts climbing from. Every number gets its own tick,
    /// so the climb is at most 30 numbers: all the way up for short counts,
    /// the last stretch for long ones.
    var countFrom: Int { max(0, days - 30) }
}

struct CelebrationColors {
    let main: Color
    let accent: Color

    init(theme: CardTheme) {
        switch theme {
        case .mosaic: (main, accent) = (Color(hex: "F1622A"), Color(hex: "FFB347"))
        case .eyes: (main, accent) = (Color(hex: "FA7C8B"), Color(hex: "F03234"))
        case .circles: (main, accent) = (Color(hex: "4D4AFD"), Color(hex: "8FB0FF"))
        case .clouds: (main, accent) = (Color(hex: "6BB026"), Color(hex: "D2E68F"))
        case .puffs: (main, accent) = (Color(hex: "A77BFA"), Color(hex: "E3CCFF"))
        case .waves: (main, accent) = (Color(hex: "0EA5A3"), Color(hex: "8FE3CF"))
        case .blooms: (main, accent) = (Color(hex: "E0457F"), Color(hex: "FFD45E"))
        case .steps: (main, accent) = (Color(hex: "FF7A2F"), Color(hex: "FFC08A"))
        case .custom: (main, accent) = (Color(hex: "8E8EA0"), Color(hex: "DADAE6"))
        }
    }
}


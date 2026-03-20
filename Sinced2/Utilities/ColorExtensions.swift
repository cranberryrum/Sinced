//
//  ColorExtensions.swift
//  Sinced2
//
//  Color utilities
//

import SwiftUI

extension Color {
    // MARK: - Blue Color Scheme
    
    /// Primary blue - main actions and highlights
    static let primaryBlue = Color(hex: "007AFF")
    
    /// Secondary blue - less prominent actions
    static let secondaryBlue = Color(hex: "5AC8FA")
    
    /// Tertiary blue - backgrounds and subtle elements
    static let tertiaryBlue = Color(hex: "0A84FF")
    
    /// Light blue - info, milestones
    static let lightBlue = Color(hex: "64D2FF")
    
    /// Dark blue - important text
    static let darkBlue = Color(hex: "0051D5")
    
    /// Muted blue - disabled states
    static let mutedBlue = Color(hex: "8E8E93")
    
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    /// System background color that adapts to light/dark mode
    static var adaptiveBackground: UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .systemBackground
            } else {
                return .systemBackground
            }
        }
    }
}



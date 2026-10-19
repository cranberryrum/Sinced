//
//  ColorExtensions.swift
//  Sinced2
//
//  Color utilities
//

import SwiftUI

extension Color {
    // MARK: - Green Color Scheme (from the app icon)
    
    /// Primary green, the logo's colour - main actions and highlights
    static let primaryGreen = Color(hex: "488B5A")
    
    /// Secondary green - less prominent actions
    static let secondaryGreen = Color(hex: "7FB58F")
    
    /// Tertiary green - backgrounds and subtle elements
    static let tertiaryGreen = Color(hex: "3F7D50")
    
    /// Light green - info, milestones
    static let lightGreen = Color(hex: "5E9F70")
    
    /// Dark green - important text
    static let darkGreen = Color(hex: "2F5E3D")
    
    /// Muted grey - disabled states
    static let mutedGreen = Color(hex: "8E8E93")
    
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



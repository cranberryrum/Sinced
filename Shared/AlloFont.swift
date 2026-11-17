//
//  AlloFont.swift
//  Shared by the app and the widget extension
//
//  Allo by Josh Puckett (SIL OFL, see Fonts/Allo-OFL.txt).
//  The static weights are registered under UIAppFonts in both Info.plists.
//

import SwiftUI

enum Allo {
    /// PostScript name of the static Allo face closest to a SwiftUI weight
    static func name(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight: return "Allo-ExtraLight"
        case .thin: return "Allo-Thin"
        case .light: return "Allo-Light"
        case .medium: return "Allo-Medium"
        case .semibold: return "Allo-SemiBold"
        case .bold: return "Allo-Bold"
        case .heavy: return "Allo-ExtraBold"
        case .black: return "Allo-Black"
        default: return "Allo-Regular"
        }
    }

    /// Default point size of each text style at the standard Dynamic Type setting
    static func size(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .subheadline: return 15
        case .callout: return 16
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        default: return 17
        }
    }
}

extension Font {
    /// Allo at a fixed size, the drop-in for `.system(size:weight:)`
    static func allo(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(Allo.name(for: weight), fixedSize: size)
    }

    /// Allo sized for a text style and scaled with Dynamic Type, the drop-in for `.system(_:weight:)`
    static func allo(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .custom(Allo.name(for: weight), size: Allo.size(for: style), relativeTo: style)
    }
}

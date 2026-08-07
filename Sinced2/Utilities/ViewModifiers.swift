//
//  ViewModifiers.swift
//  Sinced2
//
//  Reusable view modifiers for consistent styling
//

import SwiftUI

/// Card background style matching Apple's design guidelines
struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
    }
}

/// Soft sheet surface used by bottom sheets
struct SheetSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
    }
}

/// Primary button style
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .primaryBlue
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 16
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.roundedHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isEnabled ? color : Color.mutedBlue)
            )
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Secondary button style
struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = .primaryBlue
    var height: CGFloat = 50
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.roundedHeadline)
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(0.1))
            )
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Compact action tile used on detail (Share / Delete)
struct ActionTileButtonStyle: ButtonStyle {
    var tint: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.16 : 0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = 20) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
    
    func sheetSurface() -> some View {
        modifier(SheetSurface())
    }
}

/// Font extension for SF Pro Rounded + product mono
extension Font {
    /// Returns SF Pro Rounded font with specified size and weight
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
    
    /// Geist Mono for timers / elapsed values
    static func geistMono(_ size: CGFloat) -> Font {
        return .custom("GeistMono-Medium", size: size)
    }
    
    /// SF Pro Rounded versions of standard text styles
    static var roundedLargeTitle: Font {
        return .system(.largeTitle, design: .rounded, weight: .bold)
    }
    
    static var roundedTitle: Font {
        return .system(.title, design: .rounded, weight: .bold)
    }
    
    static var roundedTitle2: Font {
        return .system(.title2, design: .rounded, weight: .semibold)
    }
    
    static var roundedTitle3: Font {
        return .system(.title3, design: .rounded, weight: .semibold)
    }
    
    static var roundedHeadline: Font {
        return .system(.headline, design: .rounded)
    }
    
    static var roundedSubheadline: Font {
        return .system(.subheadline, design: .rounded)
    }
    
    static var roundedBody: Font {
        return .system(.body, design: .rounded)
    }
    
    static var roundedCallout: Font {
        return .system(.callout, design: .rounded)
    }
    
    static var roundedCaption: Font {
        return .system(.caption, design: .rounded)
    }
}

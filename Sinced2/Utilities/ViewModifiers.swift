//
//  ViewModifiers.swift
//  Sinced2
//
//  Reusable view modifiers for consistent styling
//

import SwiftUI

/// Card background style matching Apple's design guidelines
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
    }
}

/// Primary button style
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .primaryGreen
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.roundedHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Secondary button style
struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = .primaryGreen
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.roundedHeadline)
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}

/// App fonts: SF Pro (the system default design, which iOS draws as
/// SF Pro Display at larger sizes). Names kept from the old rounded set.
extension Font {
    /// SF Pro at the given size and weight
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight)
    }
    
    /// SF Pro versions of standard text styles
    static var roundedLargeTitle: Font {
        return .system(.largeTitle, weight: .semibold)
    }
    
    static var roundedTitle: Font {
        return .system(.title, weight: .semibold)
    }
    
    static var roundedTitle2: Font {
        return .system(.title2, weight: .medium)
    }
    
    static var roundedTitle3: Font {
        return .system(.title3, weight: .medium)
    }
    
    static var roundedHeadline: Font {
        return .system(.headline)
    }
    
    static var roundedSubheadline: Font {
        return .system(.subheadline)
    }
    
    static var roundedBody: Font {
        return .system(.body)
    }
    
    static var roundedCallout: Font {
        return .system(.callout)
    }
    
    static var roundedCaption: Font {
        return .system(.caption)
    }
}



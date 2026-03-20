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
    var color: Color = .primaryBlue
    
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
    var color: Color = .primaryBlue
    
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

/// Font extension for SF Pro Rounded
extension Font {
    /// Returns SF Pro Rounded font with specified size and weight
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
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



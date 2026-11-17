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

/// App fonts: Allo (see Shared/AlloFont.swift). Names kept from the old rounded set.
extension Font {
    /// Allo at the given size and weight
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .allo(size, weight: weight)
    }
    
    /// Allo versions of standard text styles, scaled with Dynamic Type
    static var roundedLargeTitle: Font {
        return .allo(.largeTitle, weight: .semibold)
    }
    
    static var roundedTitle: Font {
        return .allo(.title, weight: .semibold)
    }
    
    static var roundedTitle2: Font {
        return .allo(.title2, weight: .medium)
    }
    
    static var roundedTitle3: Font {
        return .allo(.title3, weight: .medium)
    }
    
    static var roundedHeadline: Font {
        return .allo(.headline, weight: .semibold)
    }
    
    static var roundedSubheadline: Font {
        return .allo(.subheadline)
    }
    
    static var roundedBody: Font {
        return .allo(.body)
    }
    
    static var roundedCallout: Font {
        return .allo(.callout)
    }
    
    static var roundedCaption: Font {
        return .allo(.caption)
    }
}



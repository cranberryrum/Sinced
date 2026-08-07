//
//  ViewModifiers.swift
//  Sinced2
//
//  Reusable view modifiers for consistent styling
//

import SwiftUI

/// Shared motion values keep interactions responsive while respecting Reduce Motion.
enum AppMotion {
    static func spring(
        reduceMotion: Bool,
        response: Double = 0.32,
        dampingFraction: Double = 0.9
    ) -> Animation {
        reduceMotion
            ? .easeOut(duration: 0.16)
            : .spring(response: response, dampingFraction: dampingFraction)
    }

    static func smooth(reduceMotion: Bool, duration: Double = 0.35) -> Animation {
        reduceMotion ? .easeOut(duration: 0.16) : .smooth(duration: duration)
    }
}

/// Card background style matching Apple's design guidelines
struct CardBackground: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(reduceTransparency ? AnyShapeStyle(Color(UIColor.secondarySystemBackground)) : AnyShapeStyle(.thinMaterial))
            )
    }
}

/// Primary button style
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .primaryBlue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.86 : 1.0)
            .animation(AppMotion.spring(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

/// Secondary button style
struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = .primaryBlue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .animation(AppMotion.spring(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

/// Immediate touch-down feedback for tappable cards and compact controls.
struct FluidPressButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.97
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.84 : 1)
            .animation(
                AppMotion.spring(reduceMotion: reduceMotion, response: 0.2, dampingFraction: 0.92),
                value: configuration.isPressed
            )
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



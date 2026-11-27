//
//  WidgetStyles.swift
//  WidgetSinced2
//
//  The non-classic widget layouts: Big number, Sentence and Milestone ring.
//  They draw on the theme's flat colour (no pattern), so the type itself is
//  the graphic and each style reads differently on the Home Screen.
//

import WidgetKit
import SwiftUI

// MARK: - Colours

/// Text colours for the styled layouts, per theme
struct WidgetStylePalette {
    /// Body text
    let ink: Color
    /// The count, and the ring's track
    let accent: Color
}

extension SinceEvent {
    var stylePalette: WidgetStylePalette {
        if imageData != nil {
            return WidgetStylePalette(ink: .white, accent: .white)
        }
        switch cardTheme {
        case .mosaic: return WidgetStylePalette(ink: .white, accent: Color(hex: "243721"))
        case .eyes: return WidgetStylePalette(ink: Color(hex: "5A1418"), accent: Color(hex: "F03234"))
        case .circles: return WidgetStylePalette(ink: .white, accent: Color(hex: "2C2B45"))
        case .clouds: return WidgetStylePalette(ink: .white, accent: Color(hex: "BDD47E"))
        case .puffs: return WidgetStylePalette(ink: Color(hex: "2A1C57"), accent: Color(hex: "2A1C57"))
        case .waves: return WidgetStylePalette(ink: .white, accent: Color(hex: "8FE3CF"))
        case .blooms: return WidgetStylePalette(ink: .white, accent: Color(hex: "FFD45E"))
        case .steps: return WidgetStylePalette(ink: .white, accent: Color(hex: "FF7A2F"))
        case .custom: return WidgetStylePalette(ink: .white, accent: .white)
        }
    }

    /// The title as it reads mid-sentence: "since quit caffeine".
    /// Leaves acronyms and "I" alone ("since NYC", "since I moved").
    var titleInSentence: String {
        let firstWord = title.split(separator: " ").first.map(String.init) ?? title
        let keepsCase = firstWord == "I" || firstWord.hasPrefix("I'")
            || (firstWord.count > 1 && firstWord == firstWord.uppercased())
        guard !keepsCase, let first = title.first else { return title }
        return first.lowercased() + title.dropFirst()
    }
}

extension WidgetTimeUnit {
    /// "day" / "days", for running text
    func word(for count: Int) -> String {
        label(for: count).lowercased()
    }
}

// MARK: - Big number

/// The count fills the card, sitting on the bottom edge and slightly cut off
struct BigNumberWidgetView: View {
    let event: SinceEvent
    let currentDate: Date
    let size: CGSize

    var body: some View {
        let count = event.count(at: currentDate)
        let digits = CGFloat(String(count).count)
        let palette = event.stylePalette
        let inset = size.width * 0.085
        // As tall as fits, but never wider than the card
        let fontSize = min(size.height * 0.66, (size.width - inset * 1.5) / (digits * 0.64))

        ZStack(alignment: .topLeading) {
            Color.clear

            VStack(alignment: .leading, spacing: 1) {
                Text("\(event.widgetTimeUnit.word(for: count)) since")
                    .font(.allo(11, weight: .medium))
                    .foregroundStyle(palette.ink.opacity(0.7))
                Text(event.title)
                    .font(.allo(13, weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)
            }
            .padding(.top, inset)
            .padding(.leading, inset)
            // Room for the reset button
            .padding(.trailing, 40)
        }
        .overlay(alignment: .bottomLeading) {
            Text(verbatim: String(count))
                .invalidatableContent()
                .font(.allo(fontSize, weight: .semibold).monospacedDigit())
                .tracking(-fontSize * 0.05)
                .foregroundStyle(palette.accent)
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.leading, inset * 0.6)
                // Drop the baseline onto the edge so the digits are just cut off
                .offset(y: fontSize * 0.24)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.countLabel(at: currentDate).lowercased()) since \(event.title)")
    }
}

// MARK: - Sentence

/// "It's been 47 days since quit caffeine."
struct SentenceWidgetView: View {
    let event: SinceEvent
    let currentDate: Date
    let size: CGSize

    var body: some View {
        let count = event.count(at: currentDate)
        let palette = event.stylePalette
        let base: CGFloat = size.width < 160 ? 16 : 18
        let inset = size.width * 0.09

        // Only the number is set large, so the unit doesn't wrap on its own
        let sentence = Text("It's been ")
            + Text(verbatim: String(count))
                .font(.allo(base * 1.6, weight: .semibold))
                .foregroundStyle(palette.accent)
            + Text(" \(event.widgetTimeUnit.word(for: count))")
                .foregroundStyle(palette.accent)
            + Text(" since \(event.titleInSentence).")

        ZStack(alignment: .bottomLeading) {
            Color.clear
            sentence
                .invalidatableContent()
                .font(.allo(base, weight: .medium))
                .foregroundStyle(palette.ink)
                .lineLimit(5)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, inset)
                .padding(.bottom, inset)
                // Keep clear of the reset button
                .padding(.top, 38)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Milestone ring

/// Progress towards the next milestone, with the count in the middle
struct RingWidgetView: View {
    let event: SinceEvent
    let currentDate: Date
    let size: CGSize

    var body: some View {
        let count = event.count(at: currentDate)
        let milestone = event.milestoneProgress(at: currentDate)
        let palette = event.stylePalette
        let diameter = min(size.width, size.height) * 0.5
        let lineWidth = diameter * 0.11

        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(palette.accent.opacity(event.imageData == nil ? 0.45 : 0.3), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: max(0.02, milestone.fraction))
                    .stroke(palette.ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .widgetAccentable()

                VStack(spacing: -2) {
                    Text(verbatim: String(count))
                        .invalidatableContent()
                        .font(.allo(diameter * 0.3, weight: .semibold).monospacedDigit())
                        .tracking(-1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(event.widgetTimeUnit.word(for: count))
                        .font(.allo(10, weight: .medium))
                        .opacity(0.7)
                }
                .foregroundStyle(palette.ink)
                .padding(.horizontal, lineWidth * 1.4)
            }
            .frame(width: diameter, height: diameter)

            VStack(spacing: 1) {
                Text(event.title)
                    .font(.allo(12, weight: .semibold))
                    .lineLimit(1)
                Text("\(milestone.targetText) in \(milestone.remainingText)")
                    .font(.allo(11, weight: .medium))
                    .opacity(0.7)
                    .lineLimit(1)
            }
            .foregroundStyle(palette.ink)
            .padding(.horizontal, 12)
        }
        .frame(width: size.width, height: size.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.countLabel(at: currentDate).lowercased()) since \(event.title), \(milestone.targetText) milestone in \(milestone.remainingText)")
    }
}

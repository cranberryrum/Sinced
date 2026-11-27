//
//  HomeCardStyles.swift
//  Sinced2
//
//  The widget styles (Big number, Sentence, Milestone ring) drawn on Sinced's
//  own home cards. They sit on the theme's flat colour, or the photo, so the
//  type is the graphic. Everything scales with the card, so the same views
//  work on home, in the add card's carousel and in small previews.
//

import SwiftUI

/// Text colours for the styled cards, per theme (the same as the widgets)
struct CardStylePalette {
    let ink: Color
    let accent: Color

    init(event: SinceEvent) {
        if event.cardTheme == .custom && event.imageData != nil {
            ink = .white; accent = .white
            return
        }
        switch event.cardTheme {
        case .mosaic: ink = .white; accent = Color(hex: "243721")
        case .eyes: ink = Color(hex: "5A1418"); accent = Color(hex: "F03234")
        case .circles: ink = .white; accent = Color(hex: "2C2B45")
        case .clouds: ink = .white; accent = Color(hex: "BDD47E")
        case .puffs: ink = Color(hex: "2A1C57"); accent = Color(hex: "2A1C57")
        case .waves: ink = .white; accent = Color(hex: "8FE3CF")
        case .blooms: ink = .white; accent = Color(hex: "FFD45E")
        case .steps: ink = .white; accent = Color(hex: "FF7A2F")
        case .custom: ink = .white; accent = .white
        }
    }
}

/// One of the non-classic layouts, filling a square card
struct StyledCardFace: View {
    let event: SinceEvent
    let style: CardStyle
    /// The number to show, in the event's unit
    let count: Int
    /// Words to show instead of the usual small line, during a milestone
    var subtitleOverride: String? = nil
    var now = Date()

    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width
            switch style {
            case .bigNumber: bigNumber(side)
            case .sentence: sentence(side)
            case .ring: ring(side)
            case .classic: EmptyView()
            }
        }
    }

    private var palette: CardStylePalette { CardStylePalette(event: event) }
    private var unitWord: String {
        switch event.widgetTimeUnit {
        case .hours: return count == 1 ? "hour" : "hours"
        case .days: return count == 1 ? "day" : "days"
        case .months: return count == 1 ? "month" : "months"
        case .years: return count == 1 ? "year" : "years"
        }
    }
    /// "since quit caffeine", leaving acronyms and "I" alone
    private var titleInSentence: String {
        let firstWord = event.title.split(separator: " ").first.map(String.init) ?? event.title
        let keepsCase = firstWord == "I" || firstWord.hasPrefix("I'")
            || (firstWord.count > 1 && firstWord == firstWord.uppercased())
        guard !keepsCase, let first = event.title.first else { return event.title }
        return first.lowercased() + event.title.dropFirst()
    }

    // MARK: Big number

    private func bigNumber(_ side: CGFloat) -> some View {
        let k = side / 170
        let inset = side * 0.085
        let digits = CGFloat(String(count).count)
        let fontSize = min(side * 0.62, (side - inset * 1.5) / (digits * 0.64))
        return ZStack(alignment: .topLeading) {
            Color.clear
            VStack(alignment: .leading, spacing: 1 * k) {
                Text(subtitleOverride ?? "\(unitWord) since")
                    .font(.allo(11 * k, weight: .medium))
                    .foregroundStyle(palette.ink.opacity(0.75))
                Text(event.title)
                    .font(.allo(14 * k, weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)
            }
            .padding([.top, .leading], inset)
            .padding(.trailing, inset)
        }
        .overlay(alignment: .bottomLeading) {
            Text(verbatim: String(count))
                .font(.allo(fontSize, weight: .semibold).monospacedDigit())
                .tracking(-fontSize * 0.05)
                .foregroundStyle(palette.accent)
                .contentTransition(.numericText(value: Double(count)))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.leading, inset * 0.6)
                // The baseline sits on the edge, so the digits are just cut off
                .offset(y: fontSize * 0.24)
        }
        .frame(width: side, height: side)
        .clipped()
    }

    // MARK: Sentence

    private func sentence(_ side: CGFloat) -> some View {
        let k = side / 170
        let base = 17 * k
        let inset = side * 0.09
        let line = Text("It’s been ")
            + Text(verbatim: String(count)).font(.allo(base * 1.6, weight: .semibold)).foregroundStyle(palette.accent)
            + Text(" \(unitWord)").foregroundStyle(palette.accent)
            + Text(" since \(titleInSentence).")
        return ZStack(alignment: .bottomLeading) {
            Color.clear
            VStack(alignment: .leading, spacing: 4 * k) {
                if let subtitleOverride {
                    Text(subtitleOverride)
                        .font(.allo(11 * k, weight: .semibold))
                        .foregroundStyle(palette.ink.opacity(0.8))
                }
                line
                    .font(.allo(base, weight: .medium))
                    .foregroundStyle(palette.ink)
                    .lineLimit(5)
                    .minimumScaleFactor(0.55)
            }
            .padding(inset)
        }
        .frame(width: side, height: side)
    }

    // MARK: Milestone ring

    private func ring(_ side: CGFloat) -> some View {
        let k = side / 170
        let days = max(0, now.timeIntervalSince(event.startedAt)) / 86400
        let target = Milestones.next(after: Int(days))
        let previous = Milestones.previous(before: target)
        let fraction = min(max((days - Double(previous)) / Double(max(1, target - previous)), 0), 1)
        let remaining = (Double(target) - days) * 86400
        let remainingText = Int(remaining / 86400) > 0 ? "\(Int(remaining / 86400))d" : "\(max(1, Int(ceil(remaining / 3600))))h"
        let targetText = target >= 365 && target % 365 == 0 ? "\(target / 365)y" : "\(target)d"
        let diameter = side * 0.5
        let lineWidth = diameter * 0.11

        return VStack(spacing: 8 * k) {
            ZStack {
                Circle().stroke(palette.accent.opacity(event.imageData == nil ? 0.45 : 0.3), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: max(0.02, fraction))
                    .stroke(palette.ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: -2 * k) {
                    Text(verbatim: String(count))
                        .font(.allo(diameter * 0.3, weight: .semibold).monospacedDigit())
                        .tracking(-1)
                        .contentTransition(.numericText(value: Double(count)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(unitWord)
                        .font(.allo(10 * k, weight: .medium))
                        .opacity(0.75)
                }
                .foregroundStyle(palette.ink)
                .padding(.horizontal, lineWidth * 1.4)
            }
            .frame(width: diameter, height: diameter)

            VStack(spacing: 1 * k) {
                Text(event.title)
                    .font(.allo(12.5 * k, weight: .semibold))
                    .lineLimit(1)
                Text(subtitleOverride ?? "\(targetText) in \(remainingText)")
                    .font(.allo(11 * k, weight: .medium))
                    .opacity(0.75)
                    .lineLimit(1)
            }
            .foregroundStyle(palette.ink)
            .padding(.horizontal, 12 * k)
        }
        .frame(width: side, height: side)
    }
}

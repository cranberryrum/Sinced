//
//  ShareableCardView.swift
//  Sinced2
//
//  The cards people share: Stamp, Month and Sentence, always in the
//  counter's own theme, each with a small "Tracked using the Sinced app"
//  pill. Drawn at 360 points wide and saved at 3x, so 1080 pixels.
//

import SwiftUI

enum ShareDesign: String, CaseIterable, Identifiable {
    case stamp, month, sentence
    var id: String { rawValue }
    var name: String {
        switch self {
        case .stamp: return "Stamp"
        case .month: return "Month"
        case .sentence: return "Sentence"
        }
    }
}

enum ShareFormat: String, CaseIterable, Identifiable {
    case square, story
    var id: String { rawValue }
    var name: String { self == .square ? "Square" : "Story" }
    /// The card's size in points; saved at 3x
    var size: CGSize { self == .square ? CGSize(width: 360, height: 360) : CGSize(width: 360, height: 640) }
}

struct ShareCard: View {
    let event: SinceEvent
    let design: ShareDesign
    let format: ShareFormat
    var now = Date()

    private var story: Bool { format == .story }
    private var tint: Color { event.cardTheme == .custom ? .primaryGreen : event.cardTheme.backgroundColor }
    private var unit: WidgetTimeUnit { event.widgetTimeUnit }
    private var value: Int { EventPageView.value(max(0, now.timeIntervalSince(event.startedAt)), in: unit) }
    private var word: String { EventPageView.word(unit, value) }
    private var days: Int { Int(max(0, now.timeIntervalSince(event.startedAt)) / 86400) }
    private var title: String { event.title.lowercased() }
    /// Only said when it's true
    private var longestYet: Bool { event.hasBeenReset && event.isOnBestRun(at: now) }

    var body: some View {
        Group {
            switch design {
            case .stamp: stamp
            case .month: month
            case .sentence: sentence
            }
        }
        .frame(width: format.size.width, height: format.size.height)
        .clipped()
    }

    // MARK: Stamp

    private var stamp: some View {
        let inset: CGFloat = story ? 34 : 26
        return ZStack {
            EventThemeBackground(event: event)
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(tint.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .padding(8)
                VStack(spacing: 0) {
                    Text(value.formatted())
                        .font(.allo(story ? 170 : 112, weight: .semibold))
                        .tracking(story ? -8 : -5)
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .padding(.horizontal, 20)
                    Text("\(word) since".uppercased())
                        .font(.allo(story ? 18 : 15, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(CardText.connector)
                        .padding(.top, 6)
                    Text(title)
                        .font(.allo(story ? 32 : 24, weight: .semibold))
                        .tracking(-0.4)
                        .foregroundStyle(CardText.word)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                    Text("Started \(event.startedAt.sincedShortDate)" + (longestYet ? " · longest yet" : ""))
                        .font(.allo(story ? 15 : 12.5, weight: .medium))
                        .foregroundStyle(CardText.label)
                        .padding(.top, 12)
                }
                .padding(.bottom, story ? 40 : 30)
                VStack {
                    Spacer()
                    ShareWatermark(large: story).padding(.bottom, story ? 26 : 18)
                }
            }
            .padding(inset)
        }
    }

    // MARK: Month

    private var stripHeight: CGFloat { story ? 200 : 12 }

    private var month: some View {
        let cal = Calendar.current
        let resets = event.history.filter { cal.isDate($0.at, equalTo: now, toGranularity: .month) }.count
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    (Text("\(days)").font(.allo(story ? 84 : 56, weight: .semibold)) + Text("d").font(.allo(story ? 30 : 22, weight: .semibold)))
                        .tracking(-2)
                        .foregroundStyle(CardText.word)
                    Text("since \(title)")
                        .font(.allo(story ? 16 : 14, weight: .medium))
                        .foregroundStyle(CardText.label)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(now.formatted(.dateTime.month(.wide)))
                        .font(.allo(story ? 18 : 15, weight: .semibold))
                        .foregroundStyle(CardText.word)
                    Text(resets == 0 ? "No resets" : "\(resets) \(resets == 1 ? "reset" : "resets")")
                        .font(.allo(story ? 16 : 14, weight: .medium))
                        .foregroundStyle(CardText.label)
                }
            }

            ShareMonthGrid(event: event, now: now, tint: tint, row: story ? 44 : 30, large: story)
                .padding(.top, story ? 18 : 12)

            Spacer(minLength: 0)
            HStack {
                Text(longestYet ? "My longest run yet" : "Since \(event.startedAt.sincedShortDate)")
                    .font(.allo(story ? 15 : 12, weight: .medium))
                    .foregroundStyle(CardText.label)
                Spacer(minLength: 8)
                ShareWatermark(large: story)
            }
        }
        .padding(.horizontal, story ? 24 : 20)
        .padding(.top, (story ? 28 : 22) + stripHeight)
        .padding(.bottom, story ? 28 : 22)
        .background(Color.white)
        // A band of the theme across the top
        .overlay(alignment: .top) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: stripHeight)
                .overlay { EventThemeBackground(event: event) }
                .clipped()
        }
    }

    // MARK: Sentence

    private var sentence: some View {
        ZStack(alignment: .top) {
            Color(hex: "F3F2F0")
            GrainOverlay(intensity: 0.12)
            // The theme washing down from the top
            Color.clear
                .frame(width: format.size.width, height: format.size.height * (story ? 0.58 : 0.64))
                .overlay { EventThemeBackground(event: event) }
                .clipped()
                .mask(LinearGradient(stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black.opacity(0.55), location: 0.38),
                    .init(color: .clear, location: 1),
                ], startPoint: .top, endPoint: .bottom))

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                (Text("It’s been ") + Text("\(value.formatted()) \(word)").foregroundColor(CardText.word).fontWeight(.semibold)
                 + Text(" since ") + Text(title).foregroundColor(CardText.word).fontWeight(.semibold) + Text("."))
                    .font(.allo(story ? 46 : 33, weight: .medium))
                    .tracking(-0.6)
                    .lineSpacing(-2)
                    .foregroundStyle(CardText.connector)
                    .minimumScaleFactor(0.6)
                Text("Since \(event.startedAt.sincedShortDate)" + (longestYet ? " · my longest yet" : ""))
                    .font(.allo(story ? 17 : 14, weight: .medium))
                    .foregroundStyle(CardText.label)
                    .padding(.top, 8)
                DashedRule().padding(.top, 18)
                ShareWatermark(large: story).padding(.top, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, story ? 30 : 28)
            .padding(.vertical, story ? 34 : 28)
        }
    }
}

/// "Tracked using the Sinced app", with the icon, in a soft pill
struct ShareWatermark: View {
    var large = false

    var body: some View {
        HStack(spacing: large ? 8 : 7) {
            Group {
                if let logo = UIImage(named: "AppLogo") {
                    Image(uiImage: logo).resizable().scaledToFill()
                } else {
                    Color.primaryGreen
                }
            }
            .frame(width: large ? 24 : 20, height: large ? 24 : 20)
            .clipShape(RoundedRectangle(cornerRadius: large ? 7 : 6, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 1.5, y: 1)
            (Text("Tracked using the ") + Text("Sinced").foregroundColor(CardText.word).fontWeight(.semibold) + Text(" app"))
                .font(.allo(large ? 13.5 : 11.5, weight: .medium))
                .foregroundStyle(CardText.label)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.leading, large ? 5 : 4)
        .padding(.trailing, large ? 14 : 11)
        .frame(height: large ? 34 : 28)
        .background(Capsule().fill(Color.black.opacity(0.045)))
    }
}

/// This month, the way the Runs calendar draws it, small enough for a card
private struct ShareMonthGrid: View {
    let event: SinceEvent
    let now: Date
    let tint: Color
    let row: CGFloat
    let large: Bool

    private let cal = Calendar.current

    var body: some View {
        let today = cal.startOfDay(for: now)
        let first = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? today
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let lead = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        let start = cal.startOfDay(for: event.firstStartedAt)
        let resetDays = Set(event.history.map { cal.startOfDay(for: $0.at) })
        let isBand: (Date) -> Bool = { $0 >= start && $0 <= today && !resetDays.contains($0) }
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let weekdays = Array(symbols[(cal.firstWeekday - 1)...] + symbols[..<(cal.firstWeekday - 1)])
        let font: CGFloat = large ? 15 : 11.5
        let circle: CGFloat = large ? 30 : 22

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, d in
                    Text(d).frame(maxWidth: .infinity)
                }
            }
            .font(.allo(large ? 12 : 10, weight: .semibold))
            .foregroundStyle(CardText.connector)
            .padding(.bottom, 2)

            ForEach(0..<6, id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let n = week * 7 + col - lead + 1
                        if n < 1 || n > count {
                            Color.clear.frame(maxWidth: .infinity)
                        } else {
                            let day = cal.date(byAdding: .day, value: n - 1, to: first) ?? first
                            let band = isBand(day)
                            let isToday = day == today
                            let capL = col == 0 || n == 1 || !isBand(cal.date(byAdding: .day, value: -1, to: day) ?? day)
                            let capR = col == 6 || n == count || isToday || !isBand(cal.date(byAdding: .day, value: 1, to: day) ?? day)
                            ZStack {
                                if band {
                                    let r = circle / 2
                                    UnevenRoundedRectangle(topLeadingRadius: capL ? r : 0, bottomLeadingRadius: capL ? r : 0,
                                                           bottomTrailingRadius: capR ? r : 0, topTrailingRadius: capR ? r : 0, style: .continuous)
                                        .fill(tint.opacity(0.2))
                                        .frame(height: circle)
                                        .padding(.leading, capL ? 4 : 0)
                                        .padding(.trailing, capR ? 4 : 0)
                                }
                                if isToday {
                                    Circle().fill(tint).frame(width: circle, height: circle)
                                }
                                Text("\(n)")
                                    .font(.allo(font, weight: isToday ? .bold : .medium))
                                    .foregroundStyle(isToday ? Color.white : (day >= start && day <= today) ? CardText.word : Color(hex: "d4d2d4"))
                                if resetDays.contains(day) {
                                    Circle().fill(tint).frame(width: 4, height: 4).offset(y: row / 2 - 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: row)
            }
        }
    }
}

// MARK: - Image Rendering

extension View {
    /// Renders the view to a UIImage
    @MainActor
    func renderToImage(size: CGSize, scale: CGFloat = 2.0) -> UIImage? {
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = scale
        return renderer.uiImage
    }

    /// Renders the view to JPEG data
    @MainActor
    func renderToJPEGData(size: CGSize, scale: CGFloat = 2.0, compressionQuality: CGFloat = 0.85) -> Data? {
        guard let image = renderToImage(size: size, scale: scale) else { return nil }
        return image.jpegData(compressionQuality: compressionQuality)
    }
}

//
//  WidgetSinced2.swift
//  WidgetSinced2
//
//  Created by Aditya on 13/01/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct SinceWidgetProvider: AppIntentTimelineProvider {
    /// Shown in the widget gallery and while loading
    static let sampleEvent = SinceEvent(
        title: "No smoking",
        startedAt: Date().addingTimeInterval(-12 * 86400),
        cardTheme: .mosaic
    )
    
    func placeholder(in context: Context) -> SinceWidgetEntry {
        SinceWidgetEntry(
            date: Date(),
            event: Self.sampleEvent,
            configuration: SelectEventIntent()
        )
    }

    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> SinceWidgetEntry {
        // The gallery preview should show a real-looking widget even with no events yet
        let event = getEvent(for: configuration) ?? (context.isPreview ? Self.sampleEvent : nil)
        return SinceWidgetEntry(
            date: Date(),
            event: event,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<SinceWidgetEntry> {
        let now = Date()
        
        guard let event = getEvent(for: configuration) else {
            // The app reloads widgets whenever events change
            return Timeline(entries: [SinceWidgetEntry(date: now, event: nil, configuration: configuration)], policy: .never)
        }
        
        // One entry now, then one at each moment the displayed count changes
        // (startedAt + n units), so the number ticks over on time.
        let changeDates = event.countChangeDates(after: now, limit: event.widgetTimeUnit.timelineSteps)
        let entries = ([now] + changeDates).map {
            SinceWidgetEntry(date: $0, event: event, configuration: configuration)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    func getEvent(for configuration: SelectEventIntent) -> SinceEvent? {
        guard let selectedEvent = configuration.selectedEvent else {
            // Default to the first active event
            return WidgetEvents.active().first
        }
        
        // nil if the event was deleted or archived
        return WidgetEvents.event(id: selectedEvent.id)
    }
}

extension WidgetTimeUnit {
    /// Length of one unit, matching the app's display math (30-day months, 365-day years)
    var seconds: TimeInterval {
        switch self {
        case .hours: return 3600
        case .days: return 86400
        case .months: return 86400 * 30
        case .years: return 86400 * 365
        }
    }
}

// MARK: - Timeline Entry
struct SinceWidgetEntry: TimelineEntry {
    let date: Date
    let event: SinceEvent?
    let configuration: SelectEventIntent
}

// MARK: - Widget Entry View
struct SinceWidgetEntryView: View {
    var entry: SinceWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let event = entry.event {
            SmallWidgetView(event: event, currentDate: entry.date)
                // Tapping opens this event in the app
                .widgetURL(event.widgetURL)
        } else {
            PlaceholderWidgetView()
        }
    }
}

// MARK: - Widget Background
/// Drawn as the widget's container background so iOS can handle it properly
/// in tinted and clear Home Screen modes.
struct SinceWidgetBackgroundView: View {
    let event: SinceEvent?
    
    var body: some View {
        GeometryReader { geometry in
            if let event, let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .bottom) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .widgetAccentedRenderingMode(.fullColor)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    
                    // From Figma: gradient from rgba(36,36,36,0) to #242424, height 138/328 ≈ 42%
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "242424").opacity(0),
                            Color(hex: "242424").opacity(0.7),
                            Color(hex: "242424")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.42)
                }
            } else if let event {
                ZStack {
                    event.cardTheme.backgroundColor
                    ThemeDecorationView(theme: event.cardTheme, size: geometry.size)
                }
            } else {
                Color(hex: "4D4AFD")
            }
        }
    }
}

// MARK: - Placeholder View (No Event Available)
struct PlaceholderWidgetView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("No event")
                .font(.custom("GeistMono-Medium", size: 16))
                .foregroundColor(.white)
            
            Text("Add one in Sinced, then hold to choose it")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Small Widget View (Main Design)
struct SmallWidgetView: View {
    let event: SinceEvent
    let currentDate: Date
    
    var body: some View {
        GeometryReader { geometry in
            if let imageData = event.imageData, UIImage(data: imageData) != nil {
                // Custom Image Widget Design (from Figma)
                CustomImageWidgetView(
                    event: event,
                    formattedTime: formattedTimeValue,
                    size: geometry.size
                )
            } else {
                // Theme-based Widget Design
                ThemeBasedWidgetView(
                    event: event,
                    formattedTime: formattedTimeValue,
                    size: geometry.size
                )
            }
        }
    }
    
    private var formattedTimeValue: String {
        event.countLabel(at: currentDate)
    }
}

// MARK: - Custom Image Widget View (Figma: node-id=346-3624)
// Text at bottom-left over the user's image (image is in the container background)
struct CustomImageWidgetView: View {
    let event: SinceEvent
    let formattedTime: String
    let size: CGSize
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear
            
            // Text content at bottom-left
            // From Figma: left-24px padding, positioned at bottom
            VStack(alignment: .leading, spacing: 0) {
                // Time value - Geist Mono Medium, 40px (scaled), tracking -3.2px, white
                Text(formattedTime)
                    .font(.custom("GeistMono-Medium", size: size.width < 160 ? 16 : 20))
                    .tracking(-1.6)  // Scaled from -3.2px for 40px to widget size
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // Event title - SF Pro Rounded Medium, 20px (scaled), white 60%
                Text("Since \(event.title)")
                    .font(.system(size: size.width < 160 ? 10 : 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, size.width * 0.073)  // 24/328 ≈ 7.3%, both sides so long titles truncate
            .padding(.bottom, size.height * 0.12)   // Bottom padding
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Theme Based Widget View (Preset themes)
// Centered text over the theme (theme is in the container background)
struct ThemeBasedWidgetView: View {
    let event: SinceEvent
    let formattedTime: String
    let size: CGSize
    
    var body: some View {
        VStack(spacing: 2) {
            // Time value - using Geist Mono Medium
            Text(formattedTime)
                .font(.custom("GeistMono-Medium", size: size.width < 160 ? 18 : 22))
                .tracking(-1.5)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Event title - using SF Pro Rounded
            Text("Since \(event.title)")
                .font(.system(size: size.width < 160 ? 11 : 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, size.width * 0.09)  // ~15pt on a small widget
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Theme Decoration View
struct ThemeDecorationView: View {
    let theme: CardTheme
    let size: CGSize
    
    // Set to true to use PNG images from assets, false to use SwiftUI code patterns
    private let useImageAssets = true
    
    var body: some View {
        if useImageAssets {
            // Use PNG images from WidgetAssets.xcassets
            ThemeImageView(theme: theme, size: size)
        } else {
            // Use SwiftUI code patterns (kept for future use)
            ThemeCodePatternView(theme: theme, size: size)
        }
    }
}

// MARK: - Theme Image View (Uses PNG assets)
struct ThemeImageView: View {
    let theme: CardTheme
    let size: CGSize
    
    var body: some View {
        if let name = theme.svgAssetName {
            Image(name, bundle: nil)
                .renderingMode(.original)
                .resizable()
                .widgetAccentedRenderingMode(.fullColor)
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
        }
    }
}

// MARK: - Theme Code Pattern View (SwiftUI patterns - kept for future use)
struct ThemeCodePatternView: View {
    let theme: CardTheme
    let size: CGSize
    
    var body: some View {
        switch theme {
        case .mosaic:
            MosaicPatternView(size: size)
        case .eyes:
            EyesPatternView(size: size)
        case .circles:
            CirclesPatternView(size: size)
        case .clouds:
            CloudsPatternView(size: size)
        case .puffs:
            PuffsPatternView(size: size)
        case .custom:
            EmptyView()
        }
    }
}

// MARK: - Mosaic Pattern (Orange theme) - Matches mosaic.svg exactly
struct MosaicPatternView: View {
    let size: CGSize
    private let tileCount = 7
    
    var body: some View {
        let tileSize = size.width / CGFloat(tileCount)
        
        VStack(spacing: 0) {
            // Top mosaic row - positioned at very top
            HStack(spacing: 0) {
                ForEach(0..<tileCount, id: \.self) { index in
                    MosaicTile(isHighlight: index == 3, tileSize: tileSize)
                }
            }
            .frame(height: tileSize)
            
            Spacer()
            
            // Bottom mosaic row - positioned at very bottom
            HStack(spacing: 0) {
                ForEach(0..<tileCount, id: \.self) { index in
                    MosaicTile(isHighlight: index == 3, tileSize: tileSize)
                }
            }
            .frame(height: tileSize)
        }
    }
}

struct MosaicTile: View {
    let isHighlight: Bool
    let tileSize: CGFloat
    
    // Colors from SVG
    private let darkGreen = Color(hex: "243721")
    private let gold = Color(hex: "BEA644")
    private let orange = Color(hex: "F1622A")
    private let pink = Color(hex: "FFBFB3")
    
    var body: some View {
        let bgColor = isHighlight ? orange : darkGreen
        let accentColor = isHighlight ? pink : gold
        let innerSize = tileSize * 0.37
        
        ZStack {
            Rectangle().fill(bgColor)
            
            // 5-square pattern matching SVG (corners + center)
            // Top-left
            Rectangle()
                .fill(accentColor)
                .frame(width: innerSize, height: innerSize)
                .position(x: tileSize * 0.19, y: tileSize * 0.19)
            
            // Top-right
            Rectangle()
                .fill(accentColor)
                .frame(width: innerSize, height: innerSize)
                .position(x: tileSize * 0.81, y: tileSize * 0.19)
            
            // Center
            Rectangle()
                .fill(accentColor)
                .frame(width: innerSize, height: innerSize)
                .position(x: tileSize * 0.5, y: tileSize * 0.5)
            
            // Bottom-left
            Rectangle()
                .fill(accentColor)
                .frame(width: innerSize, height: innerSize)
                .position(x: tileSize * 0.19, y: tileSize * 0.81)
            
            // Bottom-right
            Rectangle()
                .fill(accentColor)
                .frame(width: innerSize, height: innerSize)
                .position(x: tileSize * 0.81, y: tileSize * 0.81)
        }
        .frame(width: tileSize, height: tileSize)
        .clipped()
    }
}

// MARK: - Eyes Pattern (Pink theme) - Matches Eyes.svg exactly
struct EyesPatternView: View {
    let size: CGSize
    
    // SVG: eye diameter is 202, viewBox is 328x328, so ratio is 202/328 ≈ 0.616
    // Top-left eye center at x=-54+101=47, y=-88+101=13 (partially off-screen)
    // Bottom-right eye center at x=180+101=281, y=214+101=315
    
    var body: some View {
        let eyeRatio: CGFloat = 202.0 / 328.0  // ~0.616
        let eyeSize = size.width * eyeRatio
        
        ZStack {
            // Top-left eye (partially off top-left corner)
            EyeView(eyeSize: eyeSize)
                .position(
                    x: size.width * (47.0 / 328.0),
                    y: size.height * (13.0 / 328.0)
                )
            
            // Bottom-right eye (partially off bottom-right corner)
            EyeView(eyeSize: eyeSize)
                .position(
                    x: size.width * (281.0 / 328.0),
                    y: size.height * (315.0 / 328.0)
                )
        }
        .clipped()
    }
}

struct EyeView: View {
    let eyeSize: CGFloat
    
    // Colors from SVG
    private let red = Color(hex: "F03234")
    private let pink = Color(hex: "FA96A1")
    
    var body: some View {
        // SVG pupils: width=21.39, height=32.08, rx=10.69 (rounded capsules)
        // Relative to 202px eye: width≈10.6%, height≈15.9%
        // Spacing between pupils: 55.32-29.97-21.39 ≈ 4 units (in 202 scale: ~2%)
        // Pupil offset from eye center: ~40.73 from top of eye, eye radius is 101
        // So pupils are at y = -101 + 40.73 + 16.04 (half height) ≈ -44 from center
        
        let pupilWidth = eyeSize * 0.106
        let pupilHeight = eyeSize * 0.159
        let pupilSpacing = eyeSize * 0.126  // gap + one pupil width
        let pupilYOffset = -eyeSize * 0.218  // offset toward top
        
        ZStack {
            Circle()
                .fill(red)
                .frame(width: eyeSize, height: eyeSize)
            
            // Two pill-shaped pupils
            HStack(spacing: pupilSpacing - pupilWidth) {
                RoundedRectangle(cornerRadius: pupilWidth / 2)
                    .fill(pink)
                    .frame(width: pupilWidth, height: pupilHeight)
                RoundedRectangle(cornerRadius: pupilWidth / 2)
                    .fill(pink)
                    .frame(width: pupilWidth, height: pupilHeight)
            }
            .offset(y: pupilYOffset)
        }
    }
}

// MARK: - Circles Pattern (Blue/Purple theme) - Matches Circles.svg exactly
struct CirclesPatternView: View {
    let size: CGSize
    
    // SVG: 7 ellipses per row, each ~29x47 units with 17.57 stroke
    // viewBox 328x328, ellipse centers at y≈263 (bottom) and y≈-0.36 (top, partially off-screen)
    // Also rows at y≈64 and y≈328 (off-screen)
    
    private let strokeColor = Color(hex: "2C2B45")
    
    var body: some View {
        let ellipseCount = 7
        let cellWidth = size.width / CGFloat(ellipseCount)
        
        // SVG ellipse: rx≈14.6, ry≈23.4, stroke=17.57
        // Scaled to widget: 
        let ellipseWidth = cellWidth * 0.62
        let ellipseHeight = size.height * 0.143  // ~47/328
        let strokeWidth = size.width * 0.054  // ~17.57/328
        
        ZStack {
            // Row 1: Very top (y≈0, partially clipped)
            HStack(spacing: 0) {
                ForEach(0..<ellipseCount, id: \.self) { _ in
                    Ellipse()
                        .stroke(strokeColor, lineWidth: strokeWidth)
                        .frame(width: ellipseWidth, height: ellipseHeight)
                        .frame(width: cellWidth)
                }
            }
            .position(x: size.width / 2, y: 0)
            
            // Row 2: Near top (y≈64/328 ≈ 0.195)
            HStack(spacing: 0) {
                ForEach(0..<ellipseCount, id: \.self) { _ in
                    Ellipse()
                        .stroke(strokeColor, lineWidth: strokeWidth)
                        .frame(width: ellipseWidth, height: ellipseHeight)
                        .frame(width: cellWidth)
                }
            }
            .position(x: size.width / 2, y: size.height * 0.195)
            
            // Row 3: Near bottom (y≈263/328 ≈ 0.802)
            HStack(spacing: 0) {
                ForEach(0..<ellipseCount, id: \.self) { _ in
                    Ellipse()
                        .stroke(strokeColor, lineWidth: strokeWidth)
                        .frame(width: ellipseWidth, height: ellipseHeight)
                        .frame(width: cellWidth)
                }
            }
            .position(x: size.width / 2, y: size.height * 0.802)
            
            // Row 4: Very bottom (y≈328, partially clipped)
            HStack(spacing: 0) {
                ForEach(0..<ellipseCount, id: \.self) { _ in
                    Ellipse()
                        .stroke(strokeColor, lineWidth: strokeWidth)
                        .frame(width: ellipseWidth, height: ellipseHeight)
                        .frame(width: cellWidth)
                }
            }
            .position(x: size.width / 2, y: size.height)
        }
        .clipped()
    }
}

// MARK: - Clouds Pattern (Green theme) - Matches Clouds.svg exactly
struct CloudsPatternView: View {
    let size: CGSize
    
    // SVG: 6 circles with r=60.2, viewBox 328x328
    // Top row centers at y=0.2 (essentially y=0), bottom at y=328.2 (essentially y=328)
    // x positions: 60.2, 164, 267.8 (evenly spaced)
    // Circle diameter: 120.4, ratio to 328 ≈ 0.367
    
    private let cloudColor = Color(hex: "BDD47E")
    
    var body: some View {
        let circleRatio: CGFloat = 120.4 / 328.0  // ≈0.367
        let circleSize = size.width * circleRatio
        
        // Circle x positions: 60.2/328, 164/328, 267.8/328
        let xPositions: [CGFloat] = [0.184, 0.5, 0.816]
        
        ZStack {
            // Top circles (centered at y=0, so half is clipped)
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(cloudColor)
                    .frame(width: circleSize, height: circleSize)
                    .position(x: size.width * xPositions[i], y: 0)
            }
            
            // Bottom circles (centered at y=height, so half is clipped)
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(cloudColor)
                    .frame(width: circleSize, height: circleSize)
                    .position(x: size.width * xPositions[i], y: size.height)
            }
        }
        .clipped()
    }
}

// MARK: - Puffs Pattern (Purple theme) - Matches Puffs.svg exactly
struct PuffsPatternView: View {
    let size: CGSize
    
    // SVG has 6 capsules per stack (smallest to largest), positioned at top and bottom
    // Bottom stack: from smallest (y≈244) to largest (y≈305)
    // Top stack: inverted, from smallest (y≈84) to largest (y≈23)

    var body: some View {
        ZStack {
            // Bottom puff stack
            PuffStack(size: size, atBottom: true)
            
            // Top puff stack (inverted)
            PuffStack(size: size, atBottom: false)
        }
        .clipped()
    }
}

struct PuffStack: View {
    let size: CGSize
    let atBottom: Bool
    
    private let puffColor = Color(hex: "2A1C57")
    
    // From SVG - 6 capsules with widths (smallest to largest):
    // ~33, ~49, ~66, ~100, ~150, ~239 (approximated from path data)
    // Heights: ~8, ~12, ~17, ~27, ~42, ~68 (pill heights from rx values)

    var body: some View {
        let puffData: [(widthRatio: CGFloat, heightRatio: CGFloat, yOffset: CGFloat)] = atBottom ? [
            // Bottom stack (small at top, large at bottom)
            (0.052, 0.024, 0.744),  // smallest - y≈244
            (0.101, 0.033, 0.787),  // 
            (0.200, 0.047, 0.844),  // 
            (0.303, 0.065, 0.901),  // 
            (0.456, 0.084, 0.929),  // 
            (0.730, 0.128, 0.968),  // largest - near bottom edge
        ] : [
            // Top stack (inverted - large at top, small at bottom)
            (0.730, 0.128, 0.032),  // largest - near top edge
            (0.456, 0.084, 0.071),  //
            (0.303, 0.065, 0.099),  //
            (0.200, 0.047, 0.156),  //
            (0.101, 0.033, 0.213),  //
            (0.052, 0.024, 0.256),  // smallest
        ]
        
        ZStack {
            ForEach(0..<puffData.count, id: \.self) { i in
                let data = puffData[i]
                Capsule()
                    .fill(puffColor)
                    .frame(
                        width: size.width * data.widthRatio,
                        height: max(size.height * data.heightRatio, 4)
                    )
                    .position(x: size.width / 2, y: size.height * data.yOffset)
            }
        }
    }
}

// MARK: - Main Widget
struct SinceSmallWidget: Widget {
    let kind: String = "SinceSmallWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectEventIntent.self,
            provider: SinceWidgetProvider()
        ) { entry in
            SinceWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    SinceWidgetBackgroundView(event: entry.event)
                }
        }
        .configurationDisplayName("Since Event")
        .description("Track time since your selected event")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
        // Keep the themed card in StandBy instead of dropping it to plain text on black
        .containerBackgroundRemovable(false)
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    SinceSmallWidget()
} timeline: {
    SinceWidgetEntry(
        date: .now,
        event: SinceEvent(
            title: "No smoking",
            startedAt: Date().addingTimeInterval(-200 * 3600),
            cardTheme: .mosaic
        ),
        configuration: SelectEventIntent()
    )
    SinceWidgetEntry(
        date: .now,
        event: SinceEvent(
            title: "Running",
            startedAt: Date().addingTimeInterval(-50 * 86400),
            cardTheme: .eyes
        ),
        configuration: SelectEventIntent()
    )
    SinceWidgetEntry(
        date: .now,
        event: SinceEvent(
            title: "Reading",
            startedAt: Date().addingTimeInterval(-10 * 86400),
            cardTheme: .circles
        ),
        configuration: SelectEventIntent()
    )
    SinceWidgetEntry(
        date: .now,
        event: SinceEvent(
            title: "Meditation",
            startedAt: Date().addingTimeInterval(-30 * 86400),
            cardTheme: .clouds
        ),
        configuration: SelectEventIntent()
    )
    SinceWidgetEntry(
        date: .now,
        event: SinceEvent(
            title: "Workout",
            startedAt: Date().addingTimeInterval(-100 * 86400),
            cardTheme: .puffs
        ),
        configuration: SelectEventIntent()
    )
}

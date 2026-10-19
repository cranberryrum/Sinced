//
//  LockScreenWidget.swift
//  WidgetSinced2
//
//  Lock Screen widgets: circular (count inside a ring filling towards the next
//  milestone), rectangular (count, title and milestone bar) and inline text.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct SinceLockScreenProvider: AppIntentTimelineProvider {
    private let eventProvider = SinceWidgetProvider()

    func placeholder(in context: Context) -> SinceWidgetEntry {
        eventProvider.placeholder(in: context)
    }

    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> SinceWidgetEntry {
        await eventProvider.snapshot(for: configuration, in: context)
    }

    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<SinceWidgetEntry> {
        let now = Date()

        guard let event = eventProvider.getEvent(for: configuration) else {
            return Timeline(entries: [SinceWidgetEntry(date: now, event: nil, configuration: configuration)], policy: .never)
        }

        // Hourly entries keep the milestone ring and "left" text moving, plus
        // the exact moments the count ticks over
        let horizon = now.addingTimeInterval(12 * 3600)
        let hourly = (1...12).map { now.addingTimeInterval(Double($0) * 3600) }
        let ticks = event.countChangeDates(after: now, limit: 12).filter { $0 <= horizon }
        let dates = [now] + Array(Set(hourly + ticks)).sorted()

        let entries = dates.map { SinceWidgetEntry(date: $0, event: event, configuration: configuration) }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - Entry View
struct SinceLockScreenEntryView: View {
    let entry: SinceWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let event = entry.event {
                switch family {
                case .accessoryCircular:
                    CircularLockScreenView(event: event, date: entry.date)
                case .accessoryRectangular:
                    RectangularLockScreenView(event: event, date: entry.date)
                default:
                    InlineLockScreenView(event: event, date: entry.date)
                }
            } else {
                EmptyLockScreenView(family: family)
            }
        }
        .widgetURL(entry.event?.widgetURL)
    }
}

// MARK: - Circular
struct CircularLockScreenView: View {
    let event: SinceEvent
    let date: Date

    var body: some View {
        let count = event.count(at: date)

        Gauge(value: event.milestoneProgress(at: date).fraction) {
            EmptyView()
        } currentValueLabel: {
            VStack(spacing: -2) {
                Text("\(count)")
                    .font(.custom("GeistMono-Medium", size: 20))
                    .tracking(-1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(event.widgetTimeUnit.shortLabel)
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 2)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.countLabel(at: date).lowercased()) since \(event.title)")
    }
}

// MARK: - Rectangular
struct RectangularLockScreenView: View {
    let event: SinceEvent
    let date: Date

    var body: some View {
        let milestone = event.milestoneProgress(at: date)

        VStack(alignment: .leading, spacing: 1) {
            Text(event.countLabel(at: date))
                .font(.custom("GeistMono-Medium", size: 20))
                .tracking(-1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .widgetAccentable()

            Text("Since \(event.title)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 6) {
                MilestoneBar(fraction: milestone.fraction)

                Text("\(milestone.targetText) in \(milestone.remainingText)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Thin progress bar towards the next milestone
struct MilestoneBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.35))
                Capsule()
                    .fill(.primary)
                    .frame(width: max(4, geometry.size.width * fraction))
                    .widgetAccentable()
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Inline
struct InlineLockScreenView: View {
    let event: SinceEvent
    let date: Date

    var body: some View {
        // Inline widgets are a single line; fall back to a shorter form when cramped
        ViewThatFits {
            Text("\(event.countLabel(at: date).lowercased()) since \(event.title)")
            Text("\(event.count(at: date)) \(event.widgetTimeUnit.shortLabel.lowercased()) · \(event.title)")
        }
    }
}

// MARK: - Empty
struct EmptyLockScreenView: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "hourglass")
                    .font(.system(size: 20, weight: .medium))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("No event")
                    .font(.custom("GeistMono-Medium", size: 18))
                Text("Add one in Sinced")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            Text("Add an event in Sinced")
        }
    }
}

// MARK: - Widget
struct SinceLockScreenWidget: Widget {
    let kind: String = "SinceLockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectEventIntent.self,
            provider: SinceLockScreenProvider()
        ) { entry in
            SinceLockScreenEntryView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Since Event")
        .description("Glance at an event and its next milestone from your Lock Screen")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Previews
#Preview(as: .accessoryCircular) {
    SinceLockScreenWidget()
} timeline: {
    SinceWidgetEntry(date: .now, event: SinceWidgetProvider.sampleEvent, configuration: SelectEventIntent())
}

#Preview(as: .accessoryRectangular) {
    SinceLockScreenWidget()
} timeline: {
    SinceWidgetEntry(date: .now, event: SinceWidgetProvider.sampleEvent, configuration: SelectEventIntent())
}

#Preview(as: .accessoryInline) {
    SinceLockScreenWidget()
} timeline: {
    SinceWidgetEntry(date: .now, event: SinceWidgetProvider.sampleEvent, configuration: SelectEventIntent())
}

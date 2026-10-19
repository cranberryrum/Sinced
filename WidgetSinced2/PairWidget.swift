//
//  PairWidget.swift
//  WidgetSinced2
//
//  Medium widget showing two events side by side, each half drawn like the
//  small widget's card
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct SincePairProvider: AppIntentTimelineProvider {
    static let sampleEvents = (
        SinceEvent(title: "No smoking", startedAt: Date().addingTimeInterval(-12 * 86400), cardTheme: .mosaic),
        SinceEvent(title: "Caffeine", startedAt: Date().addingTimeInterval(-200 * 3600), widgetTimeUnit: .hours, cardTheme: .circles)
    )

    func placeholder(in context: Context) -> SincePairEntry {
        SincePairEntry(date: Date(), first: Self.sampleEvents.0, second: Self.sampleEvents.1)
    }

    func snapshot(for configuration: SelectEventPairIntent, in context: Context) async -> SincePairEntry {
        let (first, second) = events(for: configuration)
        if context.isPreview && first == nil {
            return placeholder(in: context)
        }
        return SincePairEntry(date: Date(), first: first, second: second)
    }

    func timeline(for configuration: SelectEventPairIntent, in context: Context) async -> Timeline<SincePairEntry> {
        let now = Date()
        let (first, second) = events(for: configuration)

        // An entry whenever either count ticks over
        let changeDates = [first, second]
            .compactMap { $0 }
            .flatMap { $0.countChangeDates(after: now, limit: $0.widgetTimeUnit.timelineSteps) }
        let dates = [now] + Array(Set(changeDates)).sorted().prefix(24)

        let entries = dates.map { SincePairEntry(date: $0, first: first, second: second) }
        // With no events there's nothing to tick; the app reloads widgets when events change
        return Timeline(entries: entries, policy: first == nil ? .never : .atEnd)
    }

    /// Configured events, falling back to the first active events in order and
    /// never showing the same event in both halves
    private func events(for configuration: SelectEventPairIntent) -> (SinceEvent?, SinceEvent?) {
        let active = WidgetEvents.active()

        let first = configuration.firstEvent.flatMap { WidgetEvents.event(id: $0.id) } ?? active.first

        var second = configuration.secondEvent.flatMap { WidgetEvents.event(id: $0.id) }
        if second == nil || second?.id == first?.id {
            second = active.first { $0.id != first?.id }
        }
        return (first, second)
    }
}

// MARK: - Timeline Entry
struct SincePairEntry: TimelineEntry {
    let date: Date
    let first: SinceEvent?
    let second: SinceEvent?
}

// MARK: - Entry View
struct SincePairEntryView: View {
    let entry: SincePairEntry

    var body: some View {
        if let first = entry.first {
            HStack(spacing: 0) {
                half(for: first)

                if let second = entry.second {
                    half(for: second)
                } else {
                    AddEventHalfView()
                }
            }
        } else {
            PlaceholderWidgetView()
        }
    }

    /// Each half opens its own event
    private func half(for event: SinceEvent) -> some View {
        Link(destination: event.widgetURL ?? URL(string: "sinced://")!) {
            SmallWidgetView(event: event, currentDate: entry.date)
        }
    }
}

/// Fills the second half when only one event exists
struct AddEventHalfView: View {
    var body: some View {
        Link(destination: URL(string: "sinced://")!) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add another\nevent")
                    .font(.system(size: 12, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.white.opacity(0.6))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Each half's card background, side by side
struct SincePairBackgroundView: View {
    let entry: SincePairEntry

    var body: some View {
        if entry.first == nil {
            SinceWidgetBackgroundView(event: nil)
        } else {
            HStack(spacing: 0) {
                SinceWidgetBackgroundView(event: entry.first)

                if entry.second != nil {
                    SinceWidgetBackgroundView(event: entry.second)
                } else {
                    Color(hex: "313131")
                }
            }
        }
    }
}

// MARK: - Widget
struct SincePairWidget: Widget {
    let kind: String = "SincePairWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectEventPairIntent.self,
            provider: SincePairProvider()
        ) { entry in
            SincePairEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    SincePairBackgroundView(entry: entry)
                }
        }
        .configurationDisplayName("Two Events")
        .description("Keep two of your events side by side")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews
#Preview(as: .systemMedium) {
    SincePairWidget()
} timeline: {
    SincePairEntry(date: .now, first: SincePairProvider.sampleEvents.0, second: SincePairProvider.sampleEvents.1)
    SincePairEntry(
        date: .now,
        first: SinceEvent(title: "Meeting her", startedAt: Date().addingTimeInterval(-120 * 86400), widgetTimeUnit: .months, cardTheme: .clouds),
        second: SinceEvent(title: "No alcohol", startedAt: Date().addingTimeInterval(-40 * 86400), cardTheme: .eyes)
    )
    SincePairEntry(date: .now, first: SincePairProvider.sampleEvents.0, second: nil)
}

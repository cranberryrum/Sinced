//
//  SinceWidget.swift
//  SinceWidget
//
//  Widget displaying time elapsed since an event
//

import WidgetKit
import SwiftUI
import AppIntents

/// Timeline entry for the widget
struct SinceWidgetEntry: TimelineEntry {
    let date: Date
    let event: SinceEvent?
    let configuration: SelectEventIntent
}

/// Timeline provider for the widget with AppIntent configuration
struct SinceWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SinceWidgetEntry {
        SinceWidgetEntry(
            date: Date(),
            event: SinceEvent(
                title: "Coffee",
                startedAt: Date().addingTimeInterval(-3600)
            ),
            configuration: SelectEventIntent()
        )
    }
    
    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> SinceWidgetEntry {
        let event = getEvent(for: configuration)
        return SinceWidgetEntry(date: Date(), event: event, configuration: configuration)
    }
    
    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<SinceWidgetEntry> {
        let currentDate = Date()
        let event = getEvent(for: configuration)
        
        // Calculate next refresh time based on elapsed time
        let refreshInterval: TimeInterval
        
        if let event = event {
            let elapsed = currentDate.timeIntervalSince(event.startedAt)
            let minutes = elapsed / 60
            
            if minutes < 60 {
                refreshInterval = 60 // Refresh every minute for first hour
            } else if minutes < 1440 { // 24 hours
                refreshInterval = 300 // Refresh every 5 minutes for first day
            } else {
                refreshInterval = 900 // Refresh every 15 minutes after that
            }
        } else {
            refreshInterval = 900
        }
        
        let nextUpdateDate = currentDate.addingTimeInterval(refreshInterval)
        let entry = SinceWidgetEntry(date: currentDate, event: event, configuration: configuration)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        
        return timeline
    }
    
    /// Get the event to display based on configuration
    private func getEvent(for configuration: SelectEventIntent) -> SinceEvent? {
        let events = StorageManager.shared.loadEvents().filter { !$0.isArchived }
        
        // If user selected a specific event, find it
        if let selectedEventId = configuration.event?.id {
            return events.first { $0.id == selectedEventId }
        }
        
        // Otherwise, return the first event
        return events.first
    }
}

/// Widget view
struct SinceWidgetEntryView: View {
    var entry: SinceWidgetProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        if let event = entry.event {
            ZStack {
                // Background - show image if available
                if let imageData = event.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(UIColor.systemBackground)
                }
                
                // Gradient overlay for readability
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    
                    // Time value
                    Text(event.widgetTimeValue())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Event name
                    Text("since \(event.title)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        } else {
            // Empty state
            VStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                Text("No events")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
        }
    }
}

/// Widget configuration
struct SinceWidget: Widget {
    let kind: String = "SinceWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectEventIntent.self,
            provider: SinceWidgetProvider()
        ) { entry in
            SinceWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Since")
        .description("Track time since an event")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    SinceWidget()
} timeline: {
    SinceWidgetEntry(
        date: Date(),
        event: SinceEvent(
            title: "Coffee",
            startedAt: Date().addingTimeInterval(-3600 * 3)
        ),
        configuration: SelectEventIntent()
    )
}


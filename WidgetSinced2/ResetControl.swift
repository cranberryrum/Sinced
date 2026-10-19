//
//  ResetControl.swift
//  WidgetSinced2
//
//  Control Center / Lock Screen / Action button control that resets an event
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Configuration
struct SelectControlEventIntent: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Event"

    @Parameter(title: "Event")
    var event: EventEntity?

    init() {}
}

// MARK: - Value
struct ResetControlValue {
    /// nil when there are no events yet
    let event: EventEntity?
    /// "12 days"
    let detail: String
}

struct ResetControlProvider: AppIntentControlValueProvider {
    func previewValue(configuration: SelectControlEventIntent) -> ResetControlValue {
        ResetControlValue(
            event: configuration.event ?? EventEntity(id: "", title: "No smoking", themeName: CardTheme.mosaic.rawValue),
            detail: "12 days"
        )
    }

    func currentValue(configuration: SelectControlEventIntent) async throws -> ResetControlValue {
        let event: SinceEvent?
        if let selected = configuration.event {
            // nil if it was deleted or archived
            event = WidgetEvents.event(id: selected.id)
        } else {
            event = WidgetEvents.active().first
        }

        guard let event else {
            return ResetControlValue(event: nil, detail: "No event")
        }

        let count = event.count(at: Date())
        return ResetControlValue(
            event: EventEntity(event: event),
            detail: "\(count) \(event.widgetTimeUnit.label(for: count).lowercased())"
        )
    }
}

// MARK: - Control
struct SinceResetControl: ControlWidget {
    static let kind = "SinceResetControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: Self.kind, provider: ResetControlProvider()) { value in
            // The template builder has no if/else. With no event the entity is
            // empty, and the intent tells the user to add one.
            let event = value.event ?? EventEntity(id: "", title: "Sinced", themeName: "")
            ControlWidgetButton(action: ResetEventIntent(event: event)) {
                Label(event.title, systemImage: "arrow.counterclockwise")
                Text(value.detail)
            } actionLabel: { _ in
                Label("Reset \(event.title)", systemImage: "arrow.counterclockwise")
            }
        }
        .displayName("Reset Event")
        .description("Start an event's timer over with one tap.")
        .promptsForUserConfiguration()
    }
}

//
//  AppIntent.swift
//  WidgetSinced2
//
//  Created by Aditya on 13/01/26.
//

import WidgetKit
import AppIntents
import SwiftUI

// EventEntity and EventEntityQuery live in Shared/EventIntents.swift

// MARK: - Widget Configuration Intent
struct SelectEventIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Event"
    static var description: IntentDescription = "Choose which event to display on the widget"
    
    @Parameter(title: "Event")
    var selectedEvent: EventEntity?

    @Parameter(title: "Style", default: .classic)
    var style: WidgetStyle

    @Parameter(title: "Reset button", default: true)
    var showsResetButton: Bool
    
    init() {}
    
    init(selectedEvent: EventEntity?) {
        self.selectedEvent = selectedEvent
    }
}

// MARK: - Widget Style
/// How a widget lays out its count. Independent of the event's theme, so
/// every theme works in every style.
enum WidgetStyle: String, AppEnum {
    case classic
    case bigNumber
    case sentence
    case ring

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Style"
    static var caseDisplayRepresentations: [WidgetStyle: DisplayRepresentation] = [
        .classic: "Classic",
        .bigNumber: "Big number",
        .sentence: "Sentence",
        .ring: "Milestone ring"
    ]
}

// MARK: - Second Event Entity (pair widget)
/// Same events as `EventEntity`, but its default is the *second* event, so a
/// new pair widget shows two different events instead of the first one twice.
struct SecondEventEntity: AppEntity {
    var id: String
    var title: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Event"
    static var defaultQuery = SecondEventEntityQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct SecondEventEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SecondEventEntity] {
        StorageManager.shared.loadEvents()
            .filter { !$0.isArchived && identifiers.contains($0.id.uuidString) }
            .map { SecondEventEntity(id: $0.id.uuidString, title: $0.title) }
    }
    
    func suggestedEntities() async throws -> [SecondEventEntity] {
        StorageManager.shared.loadEvents()
            .filter { !$0.isArchived }
            .map { SecondEventEntity(id: $0.id.uuidString, title: $0.title) }
    }
    
    func defaultResult() async -> SecondEventEntity? {
        let events = StorageManager.shared.loadEvents().filter { !$0.isArchived }
        guard events.count > 1 else { return nil }
        return SecondEventEntity(id: events[1].id.uuidString, title: events[1].title)
    }
}

// MARK: - Pair Widget Configuration Intent
struct SelectEventPairIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Events"
    static var description: IntentDescription = "Choose the two events to show side by side"
    
    @Parameter(title: "First event")
    var firstEvent: EventEntity?
    
    @Parameter(title: "Second event")
    var secondEvent: SecondEventEntity?

    @Parameter(title: "Style", default: .classic)
    var style: WidgetStyle

    init() {}
}

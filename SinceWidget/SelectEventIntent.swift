//
//  SelectEventIntent.swift
//  SinceWidget
//
//  AppIntent for configuring which event to display in widget
//

import Foundation
import AppIntents
import WidgetKit

/// Represents an event entity for widget configuration
struct EventEntity: AppEntity {
    let id: UUID
    let title: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Event"
    static var defaultQuery = EventEntityQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

/// Query for available events
struct EventEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [EventEntity] {
        let events = StorageManager.shared.loadEvents()
        let filtered = events.filter { identifiers.contains($0.id) && !$0.isArchived }
        return filtered.map { EventEntity(id: $0.id, title: $0.title) }
    }
    
    func suggestedEntities() async throws -> [EventEntity] {
        let events = StorageManager.shared.loadEvents()
        let activeEvents = events.filter { !$0.isArchived }
        print("Widget: Found \(activeEvents.count) active events")
        return activeEvents.map { EventEntity(id: $0.id, title: $0.title) }
    }
    
    func defaultResult() async -> EventEntity? {
        let events = StorageManager.shared.loadEvents()
        guard let firstEvent = events.first(where: { !$0.isArchived }) else {
            print("Widget: No active events found")
            return nil
        }
        return EventEntity(id: firstEvent.id, title: firstEvent.title)
    }
}

/// EntityStringQuery for search functionality
extension EventEntityQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [EventEntity] {
        let events = StorageManager.shared.loadEvents()
        let activeEvents = events.filter { !$0.isArchived }
        
        if string.isEmpty {
            return activeEvents.map { EventEntity(id: $0.id, title: $0.title) }
        }
        
        let filtered = activeEvents.filter { event in
            event.title.localizedCaseInsensitiveContains(string)
        }
        
        return filtered.map { EventEntity(id: $0.id, title: $0.title) }
    }
}

/// Intent for selecting which event to display in the widget
struct SelectEventIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Event"
    static var description = IntentDescription("Choose which event to display in the widget")
    
    @Parameter(title: "Event")
    var event: EventEntity?
    
    init(event: EventEntity? = nil) {
        self.event = event
    }
    
    init() {
        self.event = nil
    }
}


//
//  EventIntents.swift
//  Sinced (app and widget extension)
//
//  Event entity and the reset / undo / time-since intents used by the
//  Home Screen widget button, the Control Center control and Siri.
//

import AppIntents
import Foundation
import UserNotifications
import WidgetKit

// MARK: - Event Entity
struct EventEntity: AppEntity {
    var id: String
    var title: String
    var themeName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Event"
    static var defaultQuery = EventEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    init(id: String, title: String, themeName: String) {
        self.id = id
        self.title = title
        self.themeName = themeName
    }

    init(event: SinceEvent) {
        self.init(id: event.id.uuidString, title: event.title, themeName: event.cardTheme.rawValue)
    }
}

// MARK: - Event Query
/// Active (non-archived) events. String matching lets Siri resolve spoken names.
struct EventEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [EventEntity] {
        activeEvents()
            .filter { identifiers.contains($0.id.uuidString) }
            .map(EventEntity.init(event:))
    }

    func entities(matching string: String) async throws -> [EventEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return activeEvents()
            .filter { $0.title.localizedCaseInsensitiveContains(query) }
            .map(EventEntity.init(event:))
    }

    func suggestedEntities() async throws -> [EventEntity] {
        activeEvents().map(EventEntity.init(event:))
    }

    func defaultResult() async -> EventEntity? {
        activeEvents().first.map(EventEntity.init(event:))
    }

    private func activeEvents() -> [SinceEvent] {
        StorageManager.shared.loadEvents().filter { !$0.isArchived }
    }
}

// MARK: - Errors
enum SincedIntentError: Error, CustomLocalizedStringResourceConvertible {
    case eventNotFound
    case nothingToUndo

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .eventNotFound: return "Couldn't find that event. Add or choose one in Sinced."
        case .nothingToUndo: return "There's no recent reset to undo."
        }
    }
}

// MARK: - Reset Event
struct ResetEventIntent: AppIntent {
    static let title: LocalizedStringResource = "Reset Event"
    static let description = IntentDescription("Starts an event's timer over from now. The previous run is kept in its history.")

    @Parameter(title: "Event")
    var event: EventEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Reset \(\.$event)")
    }

    init() {}

    init(event: EventEntity) {
        self.event = event
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let storage = StorageManager.shared
        guard let id = UUID(uuidString: event.id), let stored = storage.getEvent(byId: id) else {
            throw SincedIntentError.eventNotFound
        }

        let previousRun = SincedDurationText.text(for: Date().timeIntervalSince(stored.startedAt))
        storage.resetEvent(stored)
        await ExternalEventChanges.didChange(eventID: id)

        return .result(dialog: "Reset \(stored.title). Your last run was \(previousRun).")
    }
}

// MARK: - Undo Reset
/// Shown on the widget for a short while after a reset, in case it was a mis-tap
struct UndoResetIntent: AppIntent {
    static let title: LocalizedStringResource = "Undo Reset"
    static let description = IntentDescription("Puts back the run that was just reset.")
    static let isDiscoverable = false

    @Parameter(title: "Event")
    var event: EventEntity

    init() {}

    init(event: EventEntity) {
        self.event = event
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: event.id) else { throw SincedIntentError.eventNotFound }
        guard StorageManager.shared.undoRecentReset(eventID: id) else { throw SincedIntentError.nothingToUndo }
        await ExternalEventChanges.didChange(eventID: id)
        return .result()
    }
}

// MARK: - Time Since
struct TimeSinceIntent: AppIntent {
    static let title: LocalizedStringResource = "Time Since Event"
    static let description = IntentDescription("Tells you how long it's been since an event.")

    @Parameter(title: "Event")
    var event: EventEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Time since \(\.$event)")
    }

    init() {}

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard let id = UUID(uuidString: event.id), let stored = StorageManager.shared.getEvent(byId: id) else {
            throw SincedIntentError.eventNotFound
        }

        let elapsed = SincedDurationText.text(for: Date().timeIntervalSince(stored.startedAt), units: 2)
        return .result(value: elapsed, dialog: "\(elapsed) since \(stored.title.lowercased()).")
    }
}

// MARK: - Undo Support
extension SinceEvent {
    /// How long the widget offers to undo a reset
    static let undoWindow: TimeInterval = 120

    /// The latest reset, if it happened within the undo window and can be reverted
    func undoableReset(at date: Date) -> Reset? {
        guard let reset = history.first,
              reset.previousStart != nil,
              reset.at == startedAt,
              date.timeIntervalSince(reset.at) < Self.undoWindow else { return nil }
        return reset
    }
}

extension StorageManager {
    /// Reverts the latest reset if it's still within the undo window
    func undoRecentReset(eventID: UUID, now: Date = Date()) -> Bool {
        var events = loadEvents()
        guard let index = events.firstIndex(where: { $0.id == eventID }),
              let reset = events[index].undoableReset(at: now),
              let previousStart = reset.previousStart else { return false }

        events[index].history.removeFirst()
        events[index].startedAt = previousStart
        saveEvents(events)
        return true
    }
}

// MARK: - Duration Text
enum SincedDurationText {
    /// "12 days" or, with 2 units, "12 days, 4 hours"
    static func text(for interval: TimeInterval, units: Int = 1) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = units
        formatter.allowedUnits = interval < 60 ? [.second] : [.year, .month, .day, .hour, .minute]
        return formatter.string(from: max(0, interval)) ?? ""
    }
}

// MARK: - Changes Made Outside the App's UI
/// Intents can run in the widget extension while the app is open, so they tell
/// the app to reload over a Darwin notification.
enum ExternalEventChanges {
    static let darwinName = "com.adityakolte.sinced2.eventsChanged"

    static func didChange(eventID: UUID) async {
        // Reminders carry pre-computed day counts, so drop this event's ones
        // rather than let them show a stale count. The app rebuilds the
        // schedule as soon as it's open.
        let center = UNUserNotificationCenter.current()
        let prefix = "sinced-\(eventID.uuidString)"
        let stale = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: stale)

        ControlCenter.shared.reloadAllControls()
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(darwinName as CFString),
            nil, nil, true
        )
    }
}

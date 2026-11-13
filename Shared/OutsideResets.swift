//
//  OutsideResets.swift
//  Shared (app + widget)
//
//  Resets made from a widget, Control Center, the Action button or Siri.
//  The app asks about each one the next time it opens, in case it was a
//  mis-tap that just cost someone their streak.
//

import Foundation

enum OutsideResets {
    struct Entry: Codable, Equatable {
        let eventID: UUID
        /// When the reset happened, to match it to the event's history
        let at: Date
    }

    private static let key = "outsideResets"
    private static let defaults = UserDefaults(suiteName: "group.com.kolteaditya.sinced2")

    /// Asking about a reset more than this long ago would feel odd; the
    /// event page still offers undo after that
    static let askWithin: TimeInterval = 3 * 24 * 3600

    static func record(eventID: UUID, at date: Date) {
        var entries = all().filter { $0.eventID != eventID }
        entries.append(Entry(eventID: eventID, at: date))
        save(Array(entries.suffix(10)))
    }

    /// The reset was undone or answered, so stop asking about it
    static func forget(eventID: UUID) {
        save(all().filter { $0.eventID != eventID })
    }

    static func all() -> [Entry] {
        guard let data = defaults?.data(forKey: key),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return entries
    }

    private static func save(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults?.set(data, forKey: key)
    }
}

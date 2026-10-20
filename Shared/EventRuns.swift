//
//  EventRuns.swift
//  Shared (app + widget)
//
//  An event's timeline as "runs": each reset ends one run and starts the next.
//  Resets keep the start of the run they ended, so nothing about the original
//  start is ever lost.
//

import Foundation

/// One stretch of counting, from a start to the reset that ended it
struct EventRun: Identifiable, Hashable {
    let id: UUID
    let start: Date
    /// nil for the run that's still going
    let end: Date?
    let note: String?

    func duration(at now: Date = Date()) -> TimeInterval {
        max(0, (end ?? now).timeIntervalSince(start))
    }
}

extension SinceEvent {
    /// When the counter was first started, before any resets
    var firstStartedAt: Date {
        let earliestRunStart = history.compactMap(\.previousStart).min() ?? startedAt
        return min(earliestRunStart, startedAt)
    }

    var hasBeenReset: Bool { !history.isEmpty }

    /// Finished runs, newest first
    var pastRuns: [EventRun] {
        history.compactMap { reset in
            guard let start = reset.previousStart else { return nil }
            return EventRun(id: reset.id, start: start, end: reset.at, note: reset.note)
        }
    }

    /// The longest stretch so far, including the current run
    func bestRunDuration(at now: Date = Date()) -> TimeInterval {
        let current = max(0, now.timeIntervalSince(startedAt))
        return pastRuns.map { $0.duration(at: now) }.reduce(current, max)
    }

    /// Whether the current run is the longest one yet
    func isOnBestRun(at now: Date = Date()) -> Bool {
        guard hasBeenReset else { return false }
        let current = max(0, now.timeIntervalSince(startedAt))
        return pastRuns.allSatisfy { $0.duration(at: now) <= current }
    }
}

extension Date {
    /// "12 Mar", or "12 Mar 2025" outside the current year
    var sincedShortDate: String {
        let sameYear = Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
        return formatted(sameYear
            ? .dateTime.day().month(.abbreviated)
            : .dateTime.day().month(.abbreviated).year())
    }
}

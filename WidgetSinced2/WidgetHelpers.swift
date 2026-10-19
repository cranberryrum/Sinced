//
//  WidgetHelpers.swift
//  WidgetSinced2
//
//  Shared counting, milestone and event-lookup logic for all Sinced widgets
//

import WidgetKit
import SwiftUI

extension WidgetTimeUnit {
    /// Uppercased unit for the big card number ("DAY" / "DAYS")
    func label(for count: Int) -> String {
        switch self {
        case .hours: return count == 1 ? "HOUR" : "HOURS"
        case .days: return count == 1 ? "DAY" : "DAYS"
        case .months: return count == 1 ? "MONTH" : "MONTHS"
        case .years: return count == 1 ? "YEAR" : "YEARS"
        }
    }

    /// Compact unit for tight Lock Screen layouts
    var shortLabel: String {
        switch self {
        case .hours: return "HRS"
        case .days: return "DAYS"
        case .months: return "MOS"
        case .years: return "YRS"
        }
    }

    /// How many upcoming count changes to put in a timeline
    var timelineSteps: Int {
        switch self {
        case .hours: return 24
        case .days: return 7
        case .months, .years: return 2
        }
    }
}

/// Progress from the previous milestone towards the next one
struct MilestoneProgress {
    let targetDays: Int
    let fraction: Double
    let remaining: TimeInterval

    /// "30d", or "2y" for yearly milestones
    var targetText: String {
        targetDays >= 365 && targetDays % 365 == 0 ? "\(targetDays / 365)y" : "\(targetDays)d"
    }

    /// "17d" or "5h"
    var remainingText: String {
        let days = Int(remaining / 86400)
        if days > 0 { return "\(days)d" }
        return "\(max(1, Int(ceil(remaining / 3600))))h"
    }
}

extension SinceEvent {
    /// The number shown on widgets, in the event's chosen unit
    func count(at date: Date) -> Int {
        Int(max(0, date.timeIntervalSince(startedAt)) / widgetTimeUnit.seconds)
    }

    /// "12 DAYS"
    func countLabel(at date: Date) -> String {
        let count = count(at: date)
        return "\(count) \(widgetTimeUnit.label(for: count))"
    }

    /// Moments after `date` when the displayed count ticks over
    func countChangeDates(after date: Date, limit: Int) -> [Date] {
        let unit = widgetTimeUnit.seconds
        let elapsedUnits = floor(max(0, date.timeIntervalSince(startedAt)) / unit)
        return (1...max(1, limit)).map { step in
            startedAt.addingTimeInterval((elapsedUnits + Double(step)) * unit)
        }
    }

    /// Uses the app's milestones (1, 7, 30, 90, 365 days), then every year after
    func milestoneProgress(at date: Date) -> MilestoneProgress {
        let days = max(0, date.timeIntervalSince(startedAt)) / 86400
        let marks = [1, 7, 30, 90, 365]

        let target: Int
        let previous: Int
        if let next = marks.first(where: { Double($0) > days }) {
            target = next
            previous = marks.last(where: { $0 < next }) ?? 0
        } else {
            target = (Int(days / 365) + 1) * 365
            previous = target - 365
        }

        let fraction = (days - Double(previous)) / Double(target - previous)
        return MilestoneProgress(
            targetDays: target,
            fraction: min(max(fraction, 0), 1),
            remaining: (Double(target) - days) * 86400
        )
    }

    /// Deep link that opens this event in the app
    var widgetURL: URL? {
        URL(string: "sinced://event/\(id.uuidString)")
    }
}

/// Event lookups shared by the widget timeline providers
enum WidgetEvents {
    static func active() -> [SinceEvent] {
        StorageManager.shared.loadEvents().filter { !$0.isArchived }
    }

    /// nil if the event was deleted or archived
    static func event(id: String) -> SinceEvent? {
        guard let uuid = UUID(uuidString: id),
              let event = StorageManager.shared.getEvent(byId: uuid),
              !event.isArchived else { return nil }
        return event
    }
}

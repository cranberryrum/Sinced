//
//  Milestones.swift
//  Shared (app + widget)
//
//  The milestones every event passes, and the goals someone can pick. They're
//  the same numbers, so a goal is always a milestone.
//

import Foundation

enum Milestones {
    /// The named stops. After the last one, every 100 days and every year.
    static let stops = [1, 7, 14, 30, 60, 90, 100, 180, 365, 500, 730]

    /// Goals offered on the dial (0 is "no goal")
    static let goalStops = [0, 7, 14, 30, 60, 90, 100, 180, 365, 500, 730]

    /// The milestone after `days`
    static func next(after days: Int) -> Int {
        if let stop = stops.first(where: { $0 > days }) { return stop }
        let nextHundred = (days / 100 + 1) * 100
        let nextYear = (days / 365 + 1) * 365
        return min(nextHundred, nextYear)
    }

    /// The milestone before `days`, or 0
    static func previous(before days: Int) -> Int {
        var result = 0
        var stop = 0
        while true {
            stop = next(after: stop)
            if stop >= days { return result }
            result = stop
        }
    }

    /// The biggest milestone reached at `days`, or 0
    static func reached(at days: Int) -> Int {
        days >= 1 ? previous(before: days + 1) : 0
    }

    /// "100-day", "1-year", "2-year"
    static func goalAdjective(_ days: Int) -> String {
        if days >= 365, days % 365 == 0 { return "\(days / 365)-year" }
        return "\(days)-day"
    }

    /// "100 days", "1 year"
    static func label(_ days: Int) -> String {
        if days >= 365, days % 365 == 0 {
            let years = days / 365
            return "\(years) \(years == 1 ? "year" : "years")"
        }
        return "\(days) \(days == 1 ? "day" : "days")"
    }

    /// The short line under the number in the celebration
    static func words(for days: Int, isGoal: Bool, isComeback: Bool) -> String {
        if isGoal { return "You reached your goal." }
        if isComeback, days <= 30 { return "\(label(days)) again. Back on track." }
        switch days {
        case 1: return "Day one, done."
        case 7: return "One week."
        case 14: return "Two weeks."
        case 30: return "A full month."
        case 60: return "Two months."
        case 90: return "Three months."
        case 100: return "100 days."
        case 180: return "Half a year."
        case 365: return "One whole year."
        case 500: return "500 days."
        case 730: return "Two whole years."
        default:
            if days % 365 == 0 { return "\(days / 365) whole years." }
            return "\(days) days."
        }
    }
}

extension SinceEvent {
    /// Whole days in the current run
    func daysElapsed(at date: Date = Date()) -> Int {
        Int(max(0, date.timeIntervalSince(startedAt)) / 86400)
    }

    /// The line under the count on the event page
    func goalLine(at date: Date = Date()) -> GoalLine {
        let days = daysElapsed(at: date)
        if let goal = goalDays, goal > 0 {
            if days >= goal { return .goalReached(goal) }
            let left = goal - days
            return left == 1 ? .goalTomorrow(goal) : .toGoal(goal, daysLeft: left)
        }
        let next = Milestones.next(after: days)
        return .toMilestone(next, remaining: Double(next) * 86400 - max(0, date.timeIntervalSince(startedAt)))
    }
}

enum GoalLine: Equatable {
    case toMilestone(Int, remaining: TimeInterval)
    case toGoal(Int, daysLeft: Int)
    case goalTomorrow(Int)
    case goalReached(Int)

    var text: String {
        switch self {
        case let .toMilestone(days, remaining):
            let d = Int(remaining / 86400), h = Int(remaining.truncatingRemainder(dividingBy: 86400) / 3600)
            let label = days >= 365 && days % 365 == 0 ? "\(days / 365)y" : "\(days)d"
            return d > 0 ? "\(label) milestone in \(d)d \(h)h" : "\(label) milestone in \(max(1, h))h"
        case let .toGoal(goal, left):
            return "\(left) days to your \(Milestones.goalAdjective(goal)) goal"
        case let .goalTomorrow(goal):
            return "Your \(Milestones.goalAdjective(goal)) goal is tomorrow"
        case let .goalReached(goal):
            return "\(Milestones.goalAdjective(goal).capitalizedFirst) goal reached · set the next"
        }
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

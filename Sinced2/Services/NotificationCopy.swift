//
//  NotificationCopy.swift
//  Sinced2
//
//  The words in reminder notifications. Lines are lowercase and deliberately
//  ambiguous, so they read right whether the event is a chore, a habit, an
//  anniversary or a breakup. Only some lines use the person's name, and only
//  a few use an emoji.
//

import Foundation

struct NotificationCopy {
    let title: String
    let body: String

    /// Words for one reminder about `event`, delivered at `fireDate`.
    /// The same event and day always get the same line, so rebuilding the
    /// schedule never reshuffles reminders that are already queued.
    static func make(for event: SinceEvent, firingAt fireDate: Date, userName: String) -> NotificationCopy {
        let days = max(0, Int(fireDate.timeIntervalSince(event.startedAt) / 86400))
        let name = firstName(from: userName)
        let fill = Filler(
            name: name ?? "",
            event: event.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            days: days
        )
        let seed = stableHash(event.id.uuidString)
        let dayNumber = Calendar.current.ordinality(of: .day, in: .era, for: fireDate) ?? 0

        if let milestone = milestoneLines(for: days) {
            // Use the name on milestones only some of the time too
            let useName = name != nil && (seed &+ UInt64(days)) % 2 == 0
            return fill(useName ? milestone.named : milestone.plain)
        }

        // Each event walks through its own shuffled order of lines, one per day,
        // so the same event never repeats a line until it has used them all
        let pool = name == nil ? lines.filter { !$0.usesName } : lines
        let order = shuffledIndices(count: pool.count, seed: seed)
        return fill(pool[order[dayNumber % order.count]])
    }

    // MARK: - Lines

    /// {name}, {count} ("16 days"), {day} ("16") and {event} are filled in
    private struct Line {
        let title: String
        let body: String
        var usesName: Bool { title.contains("{name}") || body.contains("{name}") }

        init(_ title: String, _ body: String) {
            self.title = title
            self.body = body
        }
    }

    private static let lines: [Line] = [
        // No name
        Line("{count}", "since {event}"),
        Line("yayy {count} 🎉", "since {event}"),
        Line("quick update", "{count} since {event}. do with that what you will"),
        Line("psst", "{count} since {event}"),
        Line("still counting", "{count} since {event}"),
        Line("{count} of whatever this is", "since {event}. carry on"),
        Line("small announcement", "it's day {day} since {event}"),
        Line("who's counting?", "you are. {count} since {event}"),
        Line("okay so", "{count} since {event}. noted."),
        Line("the clock says", "{count} since {event}"),
        Line("day {day}", "of life after {event}"),
        Line("just so you know", "{event} was {count} ago"),
        Line("fun fact", "{event} happened {count} ago"),
        Line("look at the time", "{count} since {event} 👀"),
        Line("no thoughts just numbers", "{count} since {event}"),
        Line("a reminder you didn't ask for", "{count} since {event}"),

        // With the name
        Line("yayy {name}", "{count} since {event}"),
        Line("{name}, it's been {count}", "since {event}. just saying."),
        Line("{count}, {name}", "since {event}. who's counting? (you are)"),
        Line("psst {name}", "{count} since {event}"),
        Line("look at you, {name}", "{count} since {event}"),
        Line("hey {name} 👀", "remember {event}? {count} ago"),
        Line("quick update, {name}", "{count} since {event}"),
        Line("{name}, small announcement", "it's day {day} since {event}"),
        Line("still counting, {name}", "{count} since {event}"),
        Line("okay {name}", "{count} since {event}. noted."),
        Line("{name} {name} {name}", "{count} since {event}. that's it. that's the notification"),
        Line("not to be dramatic {name}", "but it's been {count} since {event} 💅")
    ]

    private static func milestoneLines(for days: Int) -> (plain: Line, named: Line)? {
        switch days {
        case 0:
            return (Line("day one", "the count for {event} has started"),
                    Line("day one, {name}", "the count for {event} has started"))
        case 7:
            return (Line("one whole week", "7 days since {event}. look at that"),
                    Line("one whole week, {name}", "7 days since {event}. look at that"))
        case 30:
            return (Line("30 days!!", "a whole month since {event}"),
                    Line("30 days, {name}!!", "a whole month since {event}"))
        case 100:
            return (Line("triple digits", "100 days since {event}. wild."),
                    Line("triple digits, {name}", "100 days since {event}. wild."))
        case let d where d >= 365 && d % 365 == 0:
            let years = d / 365
            let span = years == 1 ? "a year" : "\(years) years"
            return (Line("it's been \(span)", "{count} since {event}. wild."),
                    Line("{name}, it's been \(span)", "{count} since {event}. wild."))
        default:
            return nil
        }
    }

    // MARK: - Helpers

    private struct Filler {
        let name: String
        let event: String
        let days: Int

        func callAsFunction(_ line: Line) -> NotificationCopy {
            NotificationCopy(title: fill(line.title), body: fill(line.body))
        }

        private func fill(_ text: String) -> String {
            text.replacingOccurrences(of: "{name}", with: name)
                .replacingOccurrences(of: "{count}", with: "\(days) \(days == 1 ? "day" : "days")")
                .replacingOccurrences(of: "{day}", with: "\(days)")
                .replacingOccurrences(of: "{event}", with: event)
        }
    }

    /// First word of the stored name, lowercased; nil if no name is set
    private static func firstName(from userName: String) -> String? {
        let first = userName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .first
            .map { $0.lowercased() }
        return first?.isEmpty == false ? first : nil
    }

    /// FNV-1a: stable across launches, unlike Swift's Hasher
    private static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    /// The same shuffle every time for a given seed
    private static func shuffledIndices(count: Int, seed: UInt64) -> [Int] {
        var generator = SplitMix64(state: seed)
        return Array(0..<count).shuffled(using: &generator)
    }

    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state &+= 0x9e3779b97f4a7c15
            var z = state
            z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
            z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
            return z ^ (z >> 31)
        }
    }
}

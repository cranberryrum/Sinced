//
//  Sinced2Tests.swift
//  Sinced2Tests
//
//  Created by Aditya Kolte on 31/10/25.
//

import Foundation
import Testing
@testable import Sinced2

struct EventsFileTests {

    /// One readable event plus one record with no title (can't be decoded)
    private let fileWithUnreadableRecord = Data("""
    [
      { "id": "6F1D1D5C-6C55-4D0A-9E43-8B8E1E2B0F01", "title": "Coffee", "startedAt": "2026-01-01T00:00:00Z" },
      { "id": "6F1D1D5C-6C55-4D0A-9E43-8B8E1E2B0F02", "startedAt": "2026-02-01T00:00:00Z", "fromTheFuture": true }
    ]
    """.utf8)

    @Test func skipsUnreadableRecordsWhenDecoding() throws {
        let (events, skipped) = try EventsFile.decode(fileWithUnreadableRecord)
        #expect(events.map(\.title) == ["Coffee"])
        #expect(skipped == 1)
    }

    @Test func savingKeepsUnreadableRecords() throws {
        var (events, _) = try EventsFile.decode(fileWithUnreadableRecord)
        events.append(SinceEvent(title: "Gym"))

        let saved = try EventsFile.encode(events, keepingUnreadableFrom: fileWithUnreadableRecord)

        let records = try #require(try JSONSerialization.jsonObject(with: saved) as? [[String: Any]])
        #expect(records.count == 3)
        #expect(records.contains { $0["fromTheFuture"] as? Bool == true })
        let (reloaded, skipped) = try EventsFile.decode(saved)
        #expect(reloaded.map(\.title) == ["Coffee", "Gym"])
        #expect(skipped == 1)
    }

    @Test func savingCleanFileIsUnchanged() throws {
        // Whole seconds: ISO 8601 dates drop fractions
        let events = [SinceEvent(title: "Gym", startedAt: Date(timeIntervalSince1970: 1_000_000))]
        let saved = try EventsFile.encode(events, keepingUnreadableFrom: nil)
        let (reloaded, skipped) = try EventsFile.decode(saved)
        #expect(reloaded == events)
        #expect(skipped == 0)
    }

    @Test func backUpWritesOneCopy() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let fileURL = folder.appendingPathComponent("events.json")

        for _ in 0..<5 { EventsFile.backUp(fileWithUnreadableRecord, nextTo: fileURL) }

        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        #expect(files == ["events.unreadable.json"])
    }
}

struct DurationTextTests {

    @Test func roundsDownInsteadOfToNearest() {
        let day: TimeInterval = 86_400
        let now = Date(timeIntervalSince1970: 1_793_000_000)
        #expect(SincedDurationText.text(for: 47 * day, now: now) == "1 month")
        #expect(SincedDurationText.text(for: 20 * day, now: now) == "20 days")
        #expect(SincedDurationText.text(for: 20 * day + 23 * 3600, units: 2, now: now) == "20 days, 23 hours")
        #expect(SincedDurationText.text(for: 30, now: now) == "30 seconds")
    }
}

struct UndoResetTests {

    @Test func backdatedResetIsUndoableOnlyWithoutWindow() {
        let previousStart = Date(timeIntervalSince1970: 0)
        let resetAt = Date(timeIntervalSince1970: 1_000_000)
        var event = SinceEvent(title: "Coffee", startedAt: resetAt)
        event.history = [Reset(at: resetAt, previousStart: previousStart)]
        let now = resetAt.addingTimeInterval(3600)

        #expect(event.undoableReset(at: now) == nil)
        #expect(event.undoableReset(at: now, requiringWindow: false) != nil)
    }
}

/// The rules that keep people's history safe on disk
@Suite(.serialized)
struct EventsFileSafetyTests {
    private let folder: URL
    private var fileURL: URL { folder.appendingPathComponent("events.json") }

    init() throws {
        folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("EventsFileSafetyTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    @Test func oneUnreadableResetKeepsTheRestOfTheHistory() throws {
        let data = Data("""
        [{ "id": "6F1D1D5C-6C55-4D0A-9E43-8B8E1E2B0F01", "title": "Coffee", "startedAt": "2026-03-01T00:00:00Z",
           "history": [
             { "id": "6F1D1D5C-6C55-4D0A-9E43-8B8E1E2B0F11", "at": "2026-03-01T00:00:00Z", "previousStart": "2026-02-01T00:00:00Z" },
             { "id": "not a uuid", "at": "2026-02-01T00:00:00Z", "previousStart": "2026-01-01T00:00:00Z" },
             { "note": "no date, can't be used" }
           ] }]
        """.utf8)
        let (events, _) = try EventsFile.decode(data)
        let event = try #require(events.first)
        // The bad id gets a fresh one; only the entry with no date is dropped
        #expect(event.history.count == 2)
        #expect(event.pastRuns.count == 2)
    }

    @Test func savingKeepsTheLastGoodFile() throws {
        try EventsFile.save([SinceEvent(title: "First")], to: fileURL)
        try EventsFile.save([SinceEvent(title: "Second")], to: fileURL)

        let previous = try Data(contentsOf: EventsFile.lastGoodURL(for: fileURL))
        #expect(try EventsFile.decode(previous).events.map(\.title) == ["First"])
    }

    @Test func aDamagedFileIsKeptAndTheLastGoodOneIsUsed() throws {
        try EventsFile.save([SinceEvent(title: "Coffee")], to: fileURL)
        try EventsFile.save([SinceEvent(title: "Coffee"), SinceEvent(title: "Gym")], to: fileURL)
        let damaged = Data("[{ this is not json".utf8)
        try damaged.write(to: fileURL)

        #expect(EventsFile.load(from: fileURL).map(\.title) == ["Coffee"])

        let kept = try FileManager.default.contentsOfDirectory(atPath: folder.path)
            .filter { $0.hasPrefix("events.damaged-") }
        #expect(kept.count == 1)
        #expect(try Data(contentsOf: folder.appendingPathComponent(kept[0])) == damaged)
    }

    @Test func aFileThatCantBeReadIsNeverOverwritten() throws {
        try EventsFile.save([SinceEvent(title: "Coffee")], to: fileURL)
        let original = try Data(contentsOf: fileURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: fileURL.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: fileURL.path) }

        #expect(EventsFile.load(from: fileURL).isEmpty)
        #expect(throws: EventsFileError.self) {
            try EventsFile.save([SinceEvent(title: "New")], to: fileURL)
        }

        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: fileURL.path)
        #expect(try Data(contentsOf: fileURL) == original)
    }

    @Test func noFileYetStartsEmptyAndCanBeSaved() throws {
        #expect(EventsFile.load(from: fileURL).isEmpty)
        try EventsFile.save([SinceEvent(title: "Coffee")], to: fileURL)
        #expect(EventsFile.load(from: fileURL).map(\.title) == ["Coffee"])
    }
}

struct MilestoneTests {
    @Test func stopsThenHundredsAndYears() {
        #expect(Milestones.next(after: 0) == 1)
        #expect(Milestones.next(after: 63) == 90)
        #expect(Milestones.next(after: 100) == 180)
        #expect(Milestones.next(after: 730) == 800)
        #expect(Milestones.next(after: 1000) == 1095)
        #expect(Milestones.reached(at: 0) == 0)
        #expect(Milestones.reached(at: 63) == 60)
        #expect(Milestones.reached(at: 100) == 100)
        #expect(Milestones.previous(before: 90) == 60)
    }

    @Test func goalLineWording() {
        let start = Date(timeIntervalSince1970: 0)
        let now = start.addingTimeInterval(63 * 86400 + 60)
        var event = SinceEvent(title: "Gym", startedAt: start)
        #expect(event.goalLine(at: now).text == "90d milestone in 26d 23h")
        event.goalDays = 100
        #expect(event.goalLine(at: now).text == "37 days to your 100-day goal")
        event.goalDays = 64
        #expect(event.goalLine(at: now).text == "Your 64-day goal is tomorrow")
        event.goalDays = 60
        #expect(event.goalLine(at: now).text == "60-day goal reached · set the next")
    }
}

struct ShareMessageTests {
    private let start = Date(timeIntervalSince1970: 0)

    @Test func streakInTheCardsUnit() {
        let now = start.addingTimeInterval(62 * 86400 + 100)
        var event = SinceEvent(title: " No sugar ", startedAt: start)
        #expect(ShareMessage.text(for: event, at: now) ==
                "62 days since “No sugar”.\nCounting mine with Sinced: https://apps.apple.com/app/id6799975298")
        event.widgetTimeUnit = .hours
        #expect(ShareMessage.streak(for: event, at: now) == "1488 hours")
        event.widgetTimeUnit = .days
        #expect(ShareMessage.streak(for: event, at: start.addingTimeInterval(5 * 3600)) == "5 hours")
        #expect(ShareMessage.streak(for: event, at: start.addingTimeInterval(30)) == "1 minute")
    }

    @Test func milestoneAndGoalWording() {
        let event = SinceEvent(title: "Started the gym", startedAt: start)
        #expect(ShareMessage.text(for: event, moment: .milestone(days: 100)).hasPrefix("Just hit 100 days since “Started the gym”."))
        #expect(ShareMessage.text(for: event, moment: .goal(days: 365)).hasPrefix("Reached my 1-year goal: “Started the gym”."))
    }
}

struct CelebrationCountTests {
    @Test func climbsAtMostThirtyNumbers() {
        func make(_ days: Int) -> MilestoneCelebration {
            MilestoneCelebration(eventID: UUID(), title: "Gym", theme: .steps, days: days, isGoal: false, isComeback: false)
        }
        #expect(make(7).countFrom == 0)
        #expect(make(30).countFrom == 0)
        #expect(make(100).countFrom == 70)
        #expect(make(365).countFrom == 335)
    }
}

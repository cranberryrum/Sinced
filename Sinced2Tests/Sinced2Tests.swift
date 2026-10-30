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

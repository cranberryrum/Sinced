//
//  EventsFile.swift
//  Sinced2
//
//  Reads and writes events.json for both the app and the widget, so a record
//  this build can't decode (damaged, or written by a newer version) is kept
//  in the file instead of being dropped on the next save.
//
//  Three more rules keep people's history safe:
//  - A file that exists but can't be read right now is never overwritten.
//  - A file that isn't valid JSON is kept aside, and the app falls back to
//    the copy saved before the last write.
//  - Every save first keeps that copy of the last good file.
//

import Foundation

enum EventsFileError: Error {
    /// The file is there but couldn't be read, so writing would destroy it
    case existingFileUnreadable
}

enum EventsFile {
    // MARK: Loading and saving

    /// Every event that can be read. Never throws: a file that can't be used
    /// gives an empty list, and `save` then refuses to overwrite it.
    static func load(from fileURL: URL) -> [SinceEvent] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }

        // Exists but can't be read, e.g. a widget refresh before the phone is
        // first unlocked. Show nothing for now; saving is blocked.
        guard let data = try? Data(contentsOf: fileURL) else { return [] }

        if let (events, skipped) = try? decode(data) {
            if skipped > 0 { backUp(data, nextTo: fileURL) }
            return events
        }

        // Not readable as a list of events at all. Keep it, then fall back to
        // the last good copy.
        keepDamagedCopy(data, of: fileURL)
        if let backup = try? Data(contentsOf: lastGoodURL(for: fileURL)),
           let (events, _) = try? decode(backup) {
            return events
        }
        return []
    }

    /// Write events, keeping the previous good file as a backup first
    static func save(_ events: [SinceEvent], to fileURL: URL) throws {
        var existing: Data?
        if FileManager.default.fileExists(atPath: fileURL.path) {
            guard let data = try? Data(contentsOf: fileURL) else {
                throw EventsFileError.existingFileUnreadable
            }
            existing = data
        }

        let data = try encode(events, keepingUnreadableFrom: existing)

        // Only a file that reads correctly becomes the backup, so a damaged
        // one never replaces the last good copy
        if let existing, existing != data, (try? decode(existing)) != nil {
            try? existing.write(to: lastGoodURL(for: fileURL), options: .atomic)
        }
        try data.write(to: fileURL, options: .atomic)
    }

    // MARK: Encoding

    /// Decode the events that can be read, skipping any that can't
    static func decode(_ data: Data) throws -> (events: [SinceEvent], skipped: Int) {
        let results = try decoder.decode([LossyDecodable<SinceEvent>].self, from: data)
        let events = results.compactMap(\.value)
        return (events, results.count - events.count)
    }

    /// Encode events, carrying over any records in `existing` that couldn't be
    /// decoded so saving never removes data the app simply can't read
    static func encode(_ events: [SinceEvent], keepingUnreadableFrom existing: Data?) throws -> Data {
        let data = try encoder.encode(events)
        let unreadable = existing.map(unreadableRecords) ?? []
        guard !unreadable.isEmpty,
              let encoded = try JSONSerialization.jsonObject(with: data) as? [Any] else {
            return data
        }
        return try JSONSerialization.data(
            withJSONObject: encoded + unreadable,
            options: [.prettyPrinted, .withoutEscapingSlashes]
        )
    }

    // MARK: Copies

    /// Keep one copy of a file that couldn't be fully read. Loads happen on
    /// every widget refresh, so only write when the contents have changed.
    static func backUp(_ data: Data, nextTo fileURL: URL) {
        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("events.unreadable.json")
        if let existing = try? Data(contentsOf: backupURL), existing == data { return }
        try? data.write(to: backupURL, options: .atomic)
    }

    /// The file as it was before the most recent save
    static func lastGoodURL(for fileURL: URL) -> URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("events.previous.json")
    }

    /// A damaged file is kept under a name of its own, never overwritten
    private static func keepDamagedCopy(_ data: Data, of fileURL: URL) {
        let url = fileURL.deletingLastPathComponent()
            .appendingPathComponent("events.damaged-\(fingerprint(of: data)).json")
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Short and stable across launches (FNV-1a), so the same damaged file
    /// is only ever kept once
    private static func fingerprint(of data: Data) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in data {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 16)
    }

    /// The raw JSON of each record in `data` that doesn't decode as an event
    private static func unreadableRecords(in data: Data) -> [Any] {
        guard let records = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let results = try? decoder.decode([LossyDecodable<SinceEvent>].self, from: data),
              records.count == results.count else { return [] }
        return zip(records, results).compactMap { record, result in
            result.value == nil ? record : nil
        }
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }
}

/// Decodes a value if possible, otherwise records nil instead of throwing
struct LossyDecodable<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

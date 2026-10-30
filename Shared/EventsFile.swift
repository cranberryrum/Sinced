//
//  EventsFile.swift
//  Sinced2
//
//  Reads and writes events.json for both the app and the widget, so a record
//  this build can't decode (damaged, or written by a newer version) is kept
//  in the file instead of being dropped on the next save.
//

import Foundation

enum EventsFile {
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

    /// Keep one copy of a file that couldn't be fully read. Loads happen on
    /// every widget refresh, so only write when the contents have changed.
    static func backUp(_ data: Data, nextTo fileURL: URL) {
        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("events.unreadable.json")
        if let existing = try? Data(contentsOf: backupURL), existing == data { return }
        try? data.write(to: backupURL, options: .atomic)
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
private struct LossyDecodable<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

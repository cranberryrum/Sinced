//
//  StorageManager.swift
//  Sinced2
//
//  Handles JSON-based storage with AppGroup support for widget sharing
//

import Foundation
import UIKit
import WidgetKit

/// Manages persistent storage of events using JSON in AppGroup container
class StorageManager {
    static let shared = StorageManager()
    
    // AppGroup identifier for sharing data with widget
    private let appGroupIdentifier = "group.com.adityakolte.sinced2.x7q3"
    
    private let fileName = "events.json"
    
    private init() {}
    
    /// Returns the file URL for storing events
    private var fileURL: URL {
        // Try to use AppGroup container for widget sharing
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            
            // Ensure the container directory exists
            try? FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
            
            let fileURL = containerURL.appendingPathComponent(fileName)
            return fileURL
        }
        
        // Fallback to documents directory
        print("StorageManager: WARNING - AppGroup not available, falling back to documents directory")
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }
    
    /// Load all events from storage.
    /// Records that can't be decoded are skipped rather than failing the whole
    /// list, and the original file is backed up first so nothing is lost when
    /// the remaining events are saved again.
    func loadEvents() -> [SinceEvent] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let results = try decoder.decode([LossyDecodable<SinceEvent>].self, from: data)
            let events = results.compactMap(\.value)
            if events.count < results.count {
                print("StorageManager: Skipped \(results.count - events.count) unreadable events")
                backUpUnreadableFile(data)
            }
            return events
        } catch {
            print("StorageManager: Error loading events: \(error)")
            if let data = try? Data(contentsOf: fileURL) {
                backUpUnreadableFile(data)
            }
            return []
        }
    }
    
    /// Keep a copy of an events file that couldn't be fully read
    private func backUpUnreadableFile(_ data: Data) {
        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("events.unreadable-\(Int(Date().timeIntervalSince1970)).json")
        try? data.write(to: backupURL, options: .atomic)
    }
    
    /// Save events to storage
    func saveEvents(_ events: [SinceEvent]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(events)
            try data.write(to: fileURL, options: [.atomic])
            
            
            // Notify widget to update
            WidgetCenter.shared.reloadAllTimelines()
            ControlCenter.shared.reloadAllControls()
        } catch {
            print("StorageManager: Error saving events: \(error.localizedDescription)")
        }
    }
    
    /// Force widget to reload immediately
    func forceWidgetReload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Add a new event
    func addEvent(_ event: SinceEvent) {
        var events = loadEvents()
        var newEvent = event
        
        // Ensure image is widget-safe
        if let imageData = newEvent.imageData,
           let recompressed = recompressImageIfNeeded(imageData) {
            newEvent.imageData = recompressed
        }
        
        events.append(newEvent)
        saveEvents(events)
    }
    
    /// Update an existing event
    func updateEvent(_ event: SinceEvent) {
        var events = loadEvents()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            var updatedEvent = event
            
            // Ensure image is widget-safe
            if let imageData = updatedEvent.imageData,
               let recompressed = recompressImageIfNeeded(imageData) {
                updatedEvent.imageData = recompressed
            }
            
            events[index] = updatedEvent
            saveEvents(events)
        }
    }
    
    /// Delete an event
    func deleteEvent(_ event: SinceEvent) {
        var events = loadEvents()
        events.removeAll { $0.id == event.id }
        saveEvents(events)
    }
    
    /// Archive/unarchive an event
    func toggleArchive(_ event: SinceEvent) {
        var events = loadEvents()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isArchived.toggle()
            saveEvents(events)
        }
    }
    
    /// Reset an event with optional note
    func resetEvent(_ event: SinceEvent, at date: Date = Date(), note: String? = nil) {
        var events = loadEvents()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            let reset = Reset(at: date, note: note, previousStart: events[index].startedAt)
            events[index].history.insert(reset, at: 0)
            events[index].startedAt = date
            saveEvents(events)
        }
    }
    
    /// Get a specific event by ID (useful for widgets)
    func getEvent(byId id: UUID) -> SinceEvent? {
        // Archived events are hidden in the app, so hide them on the widget too
        return loadEvents().first { $0.id == id && !$0.isArchived }
    }
    
    /// Fix large images that exceed widget memory limits
    /// Call this on app launch to migrate old images
    func fixLargeImages() {
        var events = loadEvents()
        var needsSave = false
        
        for i in 0..<events.count {
            if let imageData = events[i].imageData {
                if let recompressed = recompressImageIfNeeded(imageData) {
                    events[i].imageData = recompressed
                    needsSave = true
                }
            }
        }
        
        if needsSave {
            saveEvents(events)
        }
    }
    
    /// Recompress image if it's too large for widget
    private func recompressImageIfNeeded(_ imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        
        // Check if image exceeds safe widget size
        let imageArea = image.size.width * image.size.height
        let maxArea: CGFloat = 526750 // Widget memory limit
        
        // If image is safe, no need to recompress
        if imageArea < maxArea {
            return nil
        }
        
        
        // Reprocess to safe size
        return processImageForWidget(image)
    }
    
    /// Process image to widget-safe size (512x512 max, 60% quality)
    private func processImageForWidget(_ image: UIImage) -> Data? {
        let size = min(image.size.width, image.size.height)
        let origin = CGPoint(
            x: (image.size.width - size) / 2,
            y: (image.size.height - size) / 2
        )
        
        guard let cgImage = image.cgImage?.cropping(to: CGRect(origin: origin, size: CGSize(width: size, height: size))) else {
            return image.jpegData(compressionQuality: 0.6)
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        
        // Resize to max 512x512
        let maxSize: CGFloat = 512
        let scale = maxSize / size
        let newSize = CGSize(width: size * scale, height: size * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        croppedImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: 0.6)
    }
}

/// Decodes a value if possible, otherwise records nil instead of throwing
private struct LossyDecodable<Value: Decodable>: Decodable {
    let value: Value?
    
    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

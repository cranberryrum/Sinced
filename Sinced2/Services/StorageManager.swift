//
//  StorageManager.swift
//  Sinced2
//
//  Handles JSON-based storage with AppGroup support for widget sharing
//

import AppIntents
import Foundation

/// Manages persistent storage of events using JSON in AppGroup container
class StorageManager {
    static let shared = StorageManager()
    
    // AppGroup identifier for sharing data with widget
    private let appGroupIdentifier = "group.com.kolteaditya.sinced2"
    
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
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(fileName)
    }
    
    /// Load all events from storage. A file that can't be used gives an
    /// empty list, and saving is then refused so it's never overwritten
    /// (see `EventsFile`).
    func loadEvents() -> [SinceEvent] {
        EventsFile.load(from: fileURL)
    }
    
    /// Save events to storage. Returns false, and tells the person, if it
    /// couldn't be saved; callers reload from disk, so the screen shows
    /// what was actually kept.
    @discardableResult
    func saveEvents(_ events: [SinceEvent]) -> Bool {
        do {
            try EventsFile.save(events, to: fileURL)
        } catch {
            print("StorageManager: couldn't save events: \(error)")
            DispatchQueue.main.async {
                HapticManager.shared.warning()
                ToastManager.shared.show(
                    "Couldn't save that change. Try again.",
                    icon: "exclamationmark.triangle.fill",
                    duration: 3
                )
            }
            return false
        }

        // Notify widget to update
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
        // Siri matches spoken event names against this list
        SincedShortcuts.updateAppShortcutParameters()
        return true
    }
    
    /// Force widget to reload immediately
    func forceWidgetReload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Add a new event
    @discardableResult
    func addEvent(_ event: SinceEvent) -> Bool {
        var events = loadEvents()
        var newEvent = event
        
        // Ensure image is widget-safe
        if let imageData = newEvent.imageData,
           let recompressed = recompressImageIfNeeded(imageData) {
            newEvent.imageData = recompressed
        }
        
        events.append(newEvent)
        return saveEvents(events)
    }
    
    /// Update an existing event
    @discardableResult
    func updateEvent(_ event: SinceEvent) -> Bool {
        var events = loadEvents()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            var updatedEvent = event
            
            // Ensure image is widget-safe
            if let imageData = updatedEvent.imageData,
               let recompressed = recompressImageIfNeeded(imageData) {
                updatedEvent.imageData = recompressed
            }
            
            events[index] = updatedEvent
            return saveEvents(events)
        }
        return false
    }

    /// Reorder active (non-archived) events
    func moveActiveEvents(fromOffsets: IndexSet, toOffset: Int) {
        let allEvents = loadEvents()
        let activeEvents = allEvents.filter { !$0.isArchived }
        let archivedEvents = allEvents.filter { $0.isArchived }

        var reorderedActive = activeEvents
        move(&reorderedActive, fromOffsets: fromOffsets, toOffset: toOffset)

        // Save active events in new order, keep archived events after
        saveEvents(reorderedActive + archivedEvents)
    }

    /// Put the active events in the order given, keeping archived ones after.
    /// Only the order comes from the screen: each event's data is what's on
    /// disk, so a widget reset made a moment ago isn't saved over, and an
    /// event the screen didn't know about isn't dropped.
    @discardableResult
    func saveActiveEvents(_ activeEvents: [SinceEvent]) -> Bool {
        let stored = loadEvents()
        let position = Dictionary(
            activeEvents.enumerated().map { ($1.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let active = stored.enumerated()
            .filter { !$0.element.isArchived }
            .sorted { a, b in
                let pa = position[a.element.id] ?? Int.max
                let pb = position[b.element.id] ?? Int.max
                return pa != pb ? pa < pb : a.offset < b.offset
            }
            .map(\.element)
        return saveEvents(active + stored.filter(\.isArchived))
    }

    private func move<T>(_ array: inout [T], fromOffsets: IndexSet, toOffset: Int) {
        let elements = fromOffsets.map { array[$0] }
        for index in fromOffsets.sorted(by: >) {
            array.remove(at: index)
        }
        let adjustedToOffset = toOffset - fromOffsets.filter { $0 < toOffset }.count
        array.insert(contentsOf: elements, at: adjustedToOffset)
    }
    
    /// Delete an event
    @discardableResult
    func deleteEvent(_ event: SinceEvent) -> Bool {
        var events = loadEvents()
        events.removeAll { $0.id == event.id }
        return saveEvents(events)
    }
    
    /// Archive/unarchive an event
    @discardableResult
    func toggleArchive(_ event: SinceEvent) -> Bool {
        var events = loadEvents()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isArchived.toggle()
            return saveEvents(events)
        }
        return false
    }
    
    /// Reset an event with optional note
    @discardableResult
    func resetEvent(_ event: SinceEvent, at date: Date = Date(), note: String? = nil) -> Bool {
        var events = loadEvents()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            let reset = Reset(at: date, note: note, previousStart: events[index].startedAt)
            events[index].history.insert(reset, at: 0)
            events[index].startedAt = date
            return saveEvents(events)
        }
        return false
    }
    
    /// Get a specific event by ID (useful for widgets)
    func getEvent(byId id: UUID) -> SinceEvent? {
        let events = loadEvents()
        return events.first { $0.id == id }
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

// Import UIKit for image processing
import UIKit

// Import WidgetKit for timeline reload
import WidgetKit

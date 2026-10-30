//
//  EventViewModel.swift
//  Sinced2
//
//  ViewModel for managing event state with reactive updates
//

import Foundation
import SwiftUI
import Combine

/// ObservableObject that manages event state and business logic
class EventViewModel: ObservableObject {
    @Published var events: [SinceEvent] = []
    @Published var archivedEvents: [SinceEvent] = []
    @Published var hasCompletedOnboarding: Bool = false
    @Published var userName: String = ""
    /// Event to open from a notification tap or widget tap
    @Published var eventToOpen: SinceEvent?
    
    private let storageManager = StorageManager.shared
    private let notificationManager = NotificationManager.shared
    private var timer: Timer?
    
    init() {
        loadEvents()
        loadOnboardingState()
        loadUserName()
        startTimer()
        
        // Refresh all notification schedules on app launch
        refreshAllNotifications()
    }
    
    /// Load events from storage
    func loadEvents() {
        let allEvents = storageManager.loadEvents()
        events = allEvents.filter { !$0.isArchived }
        archivedEvents = allEvents.filter { $0.isArchived }
    }
    
    /// Add a new event
    func addEvent(_ event: SinceEvent) {
        storageManager.addEvent(event)
        loadEvents()
        triggerHaptic()
        
        // Schedule reminders if enabled
        if event.reminderSettings.isEnabled {
            refreshAllNotifications()
        }
    }
    
    /// Update an existing event
    func updateEvent(_ event: SinceEvent) {
        storageManager.updateEvent(event)
        loadEvents()
        
        // Reschedule notifications with new settings
        refreshAllNotifications()
    }
    
    /// Delete an event
    func deleteEvent(_ event: SinceEvent) {
        // Cancel any scheduled notifications first
        notificationManager.cancelReminders(for: event)
        
        storageManager.deleteEvent(event)
        loadEvents()
        
        // Give the freed reminder slots to other events
        refreshAllNotifications()
    }
    
    /// Archive an event
    func archiveEvent(_ event: SinceEvent) {
        // Cancel notifications for archived events
        notificationManager.cancelReminders(for: event)
        
        storageManager.toggleArchive(event)
        loadEvents()
        
        // Restores reminders if the event was unarchived
        refreshAllNotifications()
    }
    
    /// Bring an archived event back to the home screen
    func unarchiveEvent(_ event: SinceEvent) {
        guard event.isArchived else { return }
        archiveEvent(event)
        triggerHaptic()
    }

    /// Reorder active events
    func moveEvent(fromOffsets: IndexSet, toOffset: Int) {
        events.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    /// Persist the current active event order
    func persistActiveEventOrder() {
        storageManager.saveActiveEvents(events)
    }
    
    /// Reset an event
    func resetEvent(_ event: SinceEvent, at date: Date = Date(), note: String? = nil) {
        storageManager.resetEvent(event, at: date, note: note)
        loadEvents()
        triggerHaptic()
        
        // Reschedule notifications after reset (day counts start over)
        refreshAllNotifications()
    }
    
    /// Put back the run that was just reset, if it's still within the undo window
    @discardableResult
    func undoReset(_ event: SinceEvent) -> Bool {
        // Only offered by the banner right after a reset, which may be backdated
        guard storageManager.undoRecentReset(eventID: event.id, requiringWindow: false) else { return false }
        loadEvents()
        triggerHaptic()
        refreshAllNotifications()
        return true
    }
    
    /// Complete onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    /// Update the stored user name
    func updateUserName(_ name: String) {
        userName = name
        UserDefaults.standard.set(name, forKey: "userName")
        // Queued reminders use the name, so rebuild them
        NotificationManager.shared.refreshAllReminders()
    }
    
    /// Load onboarding state
    private func loadOnboardingState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    /// Load the stored user name
    private func loadUserName() {
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
    }
    
    /// Start timer to refresh UI every minute
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    /// Trigger light haptic feedback
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Refresh all notification schedules
    func refreshAllNotifications() {
        notificationManager.refreshAllReminders()
    }
    
    /// Open an event's detail sheet if it still exists and isn't archived
    func openEvent(id: UUID) {
        loadEvents()
        eventToOpen = events.first { $0.id == id }
    }
    
    deinit {
        timer?.invalidate()
    }
}



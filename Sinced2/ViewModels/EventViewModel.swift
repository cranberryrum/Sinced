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
    @Published var hasCompletedOnboarding: Bool = false
    @Published var userName: String = ""
    
    private let storageManager = StorageManager.shared
    private let notificationManager = NotificationManager.shared
    private var timer: Timer?
    
    init() {
        // Fix large images for widget compatibility
        storageManager.fixLargeImages()
        loadEvents()
        loadOnboardingState()
        loadUserName()
        startTimer()
        
        // Refresh all notification schedules on app launch
        refreshAllNotifications()
    }
    
    /// Load events from storage
    func loadEvents() {
        events = storageManager.loadEvents().filter { !$0.isArchived }
    }
    
    /// Add a new event
    func addEvent(_ event: SinceEvent) {
        storageManager.addEvent(event)
        loadEvents()
        triggerHaptic()
        
        // Schedule reminders if enabled
        if event.reminderSettings.isEnabled {
            notificationManager.scheduleReminders(for: event)
        }
    }
    
    /// Update an existing event
    func updateEvent(_ event: SinceEvent) {
        storageManager.updateEvent(event)
        loadEvents()
        
        // Reschedule notifications with new settings
        notificationManager.scheduleReminders(for: event)
    }
    
    /// Delete an event
    func deleteEvent(_ event: SinceEvent) {
        // Cancel any scheduled notifications first
        notificationManager.cancelReminders(for: event)
        
        storageManager.deleteEvent(event)
        loadEvents()
    }
    
    /// Archive an event
    func archiveEvent(_ event: SinceEvent) {
        // Cancel notifications for archived events
        notificationManager.cancelReminders(for: event)
        
        storageManager.toggleArchive(event)
        loadEvents()
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
        
        // Reschedule notifications after reset (message will update)
        if let updatedEvent = events.first(where: { $0.id == event.id }),
           updatedEvent.reminderSettings.isEnabled {
            notificationManager.scheduleReminders(for: updatedEvent)
        }
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
    private func refreshAllNotifications() {
        let allEvents = storageManager.loadEvents()
        notificationManager.refreshAllReminders(events: allEvents)
    }
    
    deinit {
        timer?.invalidate()
    }
}



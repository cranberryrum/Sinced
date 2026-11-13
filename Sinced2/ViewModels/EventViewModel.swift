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
    /// A reset made from a widget, Control Center or Siri that the app is
    /// asking about, in case it was a mistake
    @Published private(set) var outsideReset: OutsideResetOffer?
    /// A home card to ring briefly, to show where to look (set when a widget
    /// tap lands on Home instead of opening the event)
    @Published var focusedEventID: UUID?
    
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
    
    /// Add a new event. Returns false if it couldn't be saved.
    @discardableResult
    func addEvent(_ event: SinceEvent) -> Bool {
        let saved = storageManager.addEvent(event)
        loadEvents()
        guard saved else { return false }
        triggerHaptic()
        
        // Schedule reminders if enabled
        if event.reminderSettings.isEnabled {
            refreshAllNotifications()
        }
        return true
    }
    
    /// Update an existing event. Returns false if it couldn't be saved.
    @discardableResult
    func updateEvent(_ event: SinceEvent) -> Bool {
        let saved = storageManager.updateEvent(event)
        loadEvents()
        
        // Reschedule notifications with new settings
        refreshAllNotifications()
        return saved
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
        // A reset made here replaces any from outside that was being asked about
        checkOutsideResets()
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
        // Nothing left to ask about for this event
        OutsideResets.forget(eventID: event.id)
        checkOutsideResets()
        return true
    }
    
    /// Complete onboarding
    func completeOnboarding() {
        guard !hasCompletedOnboarding else { return }
        // Fades from the name step into the app
        withAnimation(.easeOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    /// Update the stored user name
    func updateUserName(_ name: String) {
        userName = name
        UserDefaults.standard.set(name, forKey: "userName")
        SharedSettings.userName = name
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
        // Names saved before the widget needed them
        if SharedSettings.userName != userName { SharedSettings.userName = userName }
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
    
    // MARK: - Resets made outside the app

    /// Offer to undo the newest reset made outside the app that can still be
    /// undone. Older or already-answered ones are dropped.
    func checkOutsideResets() {
        let now = Date()
        var offer: OutsideResetOffer?
        for entry in OutsideResets.all().sorted(by: { $0.at > $1.at }) {
            guard now.timeIntervalSince(entry.at) < OutsideResets.askWithin,
                  let event = events.first(where: { $0.id == entry.eventID }),
                  let reset = event.undoableReset(at: now, requiringWindow: false),
                  abs(reset.at.timeIntervalSince(entry.at)) < 1,
                  let previousStart = reset.previousStart else {
                // Undone, reset again, edited, deleted or too old
                OutsideResets.forget(eventID: entry.eventID)
                continue
            }
            offer = OutsideResetOffer(
                eventID: event.id,
                title: event.title,
                theme: event.cardTheme,
                resetAt: reset.at,
                lostRun: reset.at.timeIntervalSince(previousStart)
            )
            break
        }
        guard offer != outsideReset else { return }
        withAnimation(.spring(duration: 0.4, bounce: 0)) { outsideReset = offer }
    }

    /// It was a mistake: put the run back
    func undoOutsideReset() {
        guard let offer = outsideReset,
              let event = events.first(where: { $0.id == offer.eventID }) else { return }
        OutsideResets.forget(eventID: offer.eventID)
        withAnimation(.spring(duration: 0.35, bounce: 0)) { outsideReset = nil }
        // The card's count rolls back up as the screen settles
        let restored = withAnimation(.spring(duration: 0.6, bounce: 0)) { undoReset(event) }
        if restored {
            HapticManager.shared.success()
            // After the drop, so two things don't move at the bottom at once
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                ToastManager.shared.show(
                    "\(StreakText.text(for: offer.lostRun)) back on \(event.title)",
                    icon: "arrow.uturn.backward",
                    duration: 2.4
                )
            }
        }
        checkOutsideResets()
    }

    /// It was meant: stop asking
    func dismissOutsideReset() {
        guard let offer = outsideReset else { return }
        OutsideResets.forget(eventID: offer.eventID)
        withAnimation(.spring(duration: 0.3, bounce: 0)) { outsideReset = nil }
        // Any other one comes up after this one has gone
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.checkOutsideResets()
        }
    }
    
    /// Open an event's detail sheet if it still exists and isn't archived.
    /// If it was just reset outside the app, land on Home instead: ring its
    /// card and ask about the reset there, rather than opening the event
    /// page with the question fighting the sheet for attention.
    func openEvent(id: UUID) {
        loadEvents()
        checkOutsideResets()
        if outsideReset?.eventID == id {
            focusedEventID = id
            return
        }
        eventToOpen = events.first { $0.id == id }
    }
    
    deinit {
        timer?.invalidate()
    }
}

/// What the app shows when asking about a reset made outside it
struct OutsideResetOffer: Equatable {
    let eventID: UUID
    let title: String
    /// The event's card theme, which colours the strip
    let theme: CardTheme
    let resetAt: Date
    /// The run the reset ended, which undo brings back
    let lostRun: TimeInterval
}

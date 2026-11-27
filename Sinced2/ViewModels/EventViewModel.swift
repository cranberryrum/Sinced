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
    /// The milestone moment on screen, if any
    @Published private(set) var celebration: MilestoneCelebration?
    /// Asks Home to open this event's edit sheet with the goal dial open
    @Published var goalEditRequest: UUID?
    
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
        #if DEBUG
        // Launch with -SincedDemoHistory to give the first counter a few months
        // of resets, in memory only, to see the calendar on its page
        if ProcessInfo.processInfo.arguments.contains("-SincedDemoHistory"), !events.isEmpty {
            let day: TimeInterval = 86400
            var cursor = Date().addingTimeInterval(-23 * day - 3 * 3600)
            let current = cursor
            let notes = [0: "Friday drinks with the team", 1: "Deadline week", 3: "Flight at 6 am", 4: "Visiting home"]
            var history: [Reset] = []
            for (i, length) in [3, 11, 6, 18, 9, 14].enumerated() {
                let start = cursor.addingTimeInterval(-Double(length) * day)
                history.append(Reset(at: cursor, note: notes[i], previousStart: start))
                cursor = start
            }
            events[0].startedAt = current
            events[0].history = history
        }
        #endif
    }

    /// Add a new event. Returns false if it couldn't be saved.
    @discardableResult
    func addEvent(_ event: SinceEvent) -> Bool {
        let saved = storageManager.addEvent(event)
        loadEvents()
        guard saved else { return false }
        triggerHaptic()
        // A backdated event shouldn't celebrate the milestones it starts past
        MilestoneLedger.setBaseline(for: event)
        
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
            // After the screen settles, so two things don't move at once
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                ToastManager.shared.show(
                    "Streak restored",
                    subtitle: "\(StreakText.text(for: offer.lostRun)) back on \(event.title)",
                    icon: "arrow.uturn.backward",
                    kind: .success
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
    
    // MARK: - Milestones

    /// Show the biggest milestone (or goal) reached since the app last looked,
    /// across all events. One moment per open, never right after the
    /// "was it a mistake?" strip, and never during onboarding.
    func checkMilestones() {
        guard hasCompletedOnboarding, outsideReset == nil, celebration == nil else { return }
        #if DEBUG
        // Launch with -SincedDemoMilestone to see the celebration on the first counter
        if ProcessInfo.processInfo.arguments.contains("-SincedDemoMilestone"), !demoMilestoneShown, let first = events.first {
            demoMilestoneShown = true
            celebration = MilestoneCelebration(eventID: first.id, title: first.title, theme: first.cardTheme, days: 30, isGoal: false, isComeback: false)
            return
        }
        #endif
        guard let found = MilestoneLedger.nextCelebration(in: events) else { return }
        withAnimation(.easeOut(duration: 0.35)) { celebration = found }
    }

    #if DEBUG
    private var demoMilestoneShown = false
    #endif

    /// True while home is playing the milestone on its card
    @Published var spotlightShowing = false

    func closeCelebration() {
        // Remembered for the next app open, when a tip might be welcome
        if let celebration { SupportPrompter.shared.noteCelebration(celebration) }
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.3)) {
            spotlightShowing = false
            celebration = nil
        }
    }

    /// Tapping the celebrating card: home comes back, then the event opens
    /// from its card as usual
    func openCelebratedEvent() {
        guard let id = celebration?.eventID else { return }
        closeCelebration()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
            self?.eventToOpen = self?.events.first { $0.id == id }
        }
    }

    /// "Set the next goal": close the moment, then open the goal dial
    func setNextGoal() {
        guard let id = celebration?.eventID else { return }
        closeCelebration()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.goalEditRequest = id
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
        // A milestone reached since the app last looked takes priority:
        // check now, because a widget tap arrives before the app's own check
        // on becoming active, and the event page would cover the moment
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

/// Which milestone each event's current run has already celebrated, so each
/// one shows exactly once. Kept on this device only, like the rest of the
/// app's settings.
enum MilestoneLedger {
    private struct Entry: Codable {
        /// The run this applies to
        var runStart: Date
        /// Biggest milestone already shown (or passed silently)
        var level: Int
    }

    private static let key = "milestoneLedger"
    private static var defaults: UserDefaults { .standard }

    private static func load() -> [String: Entry] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([String: Entry].self, from: data) else { return [:] }
        return entries
    }

    private static func save(_ entries: [String: Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }

    /// What the event has reached right now: the biggest milestone, or its goal
    private static func level(of event: SinceEvent, at date: Date) -> Int {
        let days = event.daysElapsed(at: date)
        let goal = event.goalDays ?? 0
        return max(Milestones.reached(at: days), goal > 0 && days >= goal ? goal : 0)
    }

    /// Count everything already reached as seen, without celebrating
    static func setBaseline(for event: SinceEvent, at date: Date = Date()) {
        var entries = load()
        entries[event.id.uuidString] = Entry(runStart: event.startedAt, level: level(of: event, at: date))
        save(entries)
    }

    /// The single biggest new milestone across events, marked as shown
    static func nextCelebration(in events: [SinceEvent], at date: Date = Date()) -> MilestoneCelebration? {
        var entries = load()
        var best: (event: SinceEvent, level: Int, comeback: Bool)?

        for event in events {
            let key = event.id.uuidString
            let reached = level(of: event, at: date)
            guard var entry = entries[key] else {
                // First look at an event from before this version: no backlog
                entries[key] = Entry(runStart: event.startedAt, level: reached)
                continue
            }

            var comeback = false
            if abs(entry.runStart.timeIntervalSince(event.startedAt)) >= 1 {
                // A reset started a new run: its milestones count again.
                // Any other change (an undo, an edited start date) is silent.
                let startedByReset = event.history.first.map { abs($0.at.timeIntervalSince(event.startedAt)) < 1 } ?? false
                if startedByReset, event.startedAt > entry.runStart {
                    entry = Entry(runStart: event.startedAt, level: 0)
                    comeback = true
                } else {
                    entry = Entry(runStart: event.startedAt, level: reached)
                }
                entries[key] = entry
            }

            if reached > entry.level, reached > (best?.level ?? 0) {
                best = (event, reached, comeback || event.hasBeenReset)
            }
        }

        guard let best else {
            save(entries)
            return nil
        }
        // Everything this event reached is now seen, so only the biggest shows
        entries[best.event.id.uuidString]?.level = best.level
        save(entries)

        let goal = best.event.goalDays ?? 0
        return MilestoneCelebration(
            eventID: best.event.id,
            title: best.event.title,
            theme: best.event.cardTheme,
            days: best.level,
            isGoal: goal > 0 && best.level == goal,
            isComeback: best.comeback
        )
    }
}

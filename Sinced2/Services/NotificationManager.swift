//
//  NotificationManager.swift
//  Sinced2
//
//  Handles push notification scheduling and permissions
//

import Foundation
import UserNotifications
import UIKit
import Combine

/// Manager for handling local push notifications
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    private static let notificationsEnabledKey = "notificationsEnabled"
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var notificationsEnabled: Bool = UserDefaults.standard.object(forKey: NotificationManager.notificationsEnabledKey) as? Bool ?? true
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override private init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Request notification permissions from the user
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.checkAuthorizationStatus()
                completion(granted)
            }
            
            if let error = error {
                print("NotificationManager: Authorization error - \(error.localizedDescription)")
            }
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Open app settings for notification permissions
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Schedule Notifications
    
    /// iOS keeps at most 64 pending local notifications per app; leave some headroom.
    private static let maxPendingNotifications = 60
    private static let identifierPrefix = "sinced-"
    
    private var pendingRefresh: DispatchWorkItem?
    
    /// Schedule reminders for an event based on its settings.
    /// All events share the system's pending-notification budget, so this
    /// rebuilds the whole schedule rather than just this event.
    func scheduleReminders(for event: SinceEvent) {
        refreshAllReminders()
    }
    
    /// Upcoming fire dates for an event, soonest first
    private func upcomingFireDates(for event: SinceEvent, limit: Int, from now: Date) -> [Date] {
        let calendar = Calendar.current
        let settings = event.reminderSettings
        var dates: [Date] = []
        
        switch settings.reminderType {
        case .daily:
            var dayOffset = 0
            while dates.count < limit {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now),
                      let fireDate = calendar.date(bySettingHour: settings.dailyHour, minute: settings.dailyMinute, second: 0, of: day) else { break }
                if fireDate > now { dates.append(fireDate) }
                dayOffset += 1
            }
            
        case .weekly:
            let weekdays = Set(settings.weeklyDays.map(\.rawValue))
            guard !weekdays.isEmpty else { return [] }
            var dayOffset = 0
            while dates.count < limit {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { break }
                dayOffset += 1
                guard weekdays.contains(calendar.component(.weekday, from: day)) else { continue }
                let (hour, minute) = weeklyReminderTime(for: event, on: day)
                guard let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { break }
                if fireDate > now { dates.append(fireDate) }
            }
        }
        
        return dates
    }
    
    /// A "random" time between 9:00 and 20:59 that is stable for a given event
    /// and day, so rebuilding the schedule never moves (or duplicates) a reminder.
    private func weeklyReminderTime(for event: SinceEvent, on day: Date) -> (hour: Int, minute: Int) {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        let key = "\(event.id.uuidString)-\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        // FNV-1a: deterministic across launches, unlike Swift's Hasher
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        let minutesAfterNine = Int(hash % 720)
        return (9 + minutesAfterNine / 60, minutesAfterNine % 60)
    }
    
    /// Create notification content for an event as of the moment it will be delivered
    private func createNotificationContent(for event: SinceEvent, firingAt fireDate: Date) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Day count is for the delivery date; the line is picked per event and day
        let copy = NotificationCopy.make(
            for: event,
            firingAt: fireDate,
            userName: UserDefaults.standard.string(forKey: "userName") ?? ""
        )
        content.title = copy.title
        content.body = copy.body
        
        // Use custom notification sound
        content.sound = UNNotificationSound(named: UNNotificationSoundName("NotifSound.wav"))
        content.badge = nil
        
        // Add event ID to userInfo for deep linking
        content.userInfo = ["eventId": event.id.uuidString]
        
        // Set thread identifier for grouping
        content.threadIdentifier = "sinced-reminders"
        
        return content
    }
    
    /// Generate a unique identifier for a notification
    private func notificationIdentifier(for event: SinceEvent, fireDate: Date) -> String {
        return "\(Self.identifierPrefix)\(event.id.uuidString)-\(Int(fireDate.timeIntervalSince1970))"
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel all reminders for a specific event, including ones already in
    /// Notification Center (so they can't be tapped after a delete/archive)
    func cancelReminders(for event: SinceEvent) {
        let baseIdentifier = "\(Self.identifierPrefix)\(event.id.uuidString)"
        
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(baseIdentifier) }
                .map { $0.identifier }
            self?.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
        notificationCenter.getDeliveredNotifications { [weak self] notifications in
            let identifiersToRemove = notifications
                .map { $0.request.identifier }
                .filter { $0.hasPrefix(baseIdentifier) }
            self?.notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }
    
    /// Cancel all scheduled notifications
    func cancelAllReminders() {
        pendingRefresh?.cancel()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Refresh All Notifications
    
    /// Rebuild the notification schedule for all events.
    /// Each reminder is a one-shot notification whose day count is computed for
    /// its own delivery date, so call this whenever the app becomes active to
    /// keep the schedule topped up.
    func refreshAllReminders() {
        // Coalesce bursts of calls (e.g. update + settings save) into one rebuild.
        // Events are read when the rebuild runs, so it never uses a stale list.
        pendingRefresh?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.rebuildSchedule(events: StorageManager.shared.loadEvents())
        }
        pendingRefresh = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }
    
    private func rebuildSchedule(events: [SinceEvent]) {
        notificationCenter.removeAllPendingNotificationRequests()
        
        guard notificationsEnabled else { return }
        
        let reminderEvents = events.filter { !$0.isArchived && $0.reminderSettings.isEnabled }
        let now = Date()
        
        // Share the budget by date rather than per event: take the soonest
        // reminders across all events, so busy schedules stay covered for as
        // long as possible.
        let upcoming = reminderEvents
            .flatMap { event in
                upcomingFireDates(for: event, limit: Self.maxPendingNotifications, from: now)
                    .map { (event: event, fireDate: $0) }
            }
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(Self.maxPendingNotifications)
        
        for (event, fireDate) in upcoming {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: notificationIdentifier(for: event, fireDate: fireDate),
                content: createNotificationContent(for: event, firingAt: fireDate),
                trigger: trigger
            )
            notificationCenter.add(request) { error in
                if let error = error {
                    print("NotificationManager: Error scheduling reminder - \(error.localizedDescription)")
                }
            }
        }
    }
    
    func setNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: NotificationManager.notificationsEnabledKey)
        
        if enabled {
            refreshAllReminders()
        } else {
            cancelAllReminders()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let eventIdString = userInfo["eventId"] as? String,
           let eventId = UUID(uuidString: eventIdString) {
            // Post notification for app to handle navigation
            NotificationCenter.default.post(
                name: .didTapEventNotification,
                object: nil,
                userInfo: ["eventId": eventId]
            )
        }
        
        completionHandler()
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let didTapEventNotification = Notification.Name("didTapEventNotification")
}


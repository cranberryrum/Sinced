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
    
    /// Schedule reminders for an event based on its settings
    func scheduleReminders(for event: SinceEvent) {
        // First, cancel any existing notifications for this event
        cancelReminders(for: event)
        
        guard notificationsEnabled, event.reminderSettings.isEnabled else {
            print("NotificationManager: Reminders disabled for event \(event.title)")
            return
        }
        
        switch event.reminderSettings.reminderType {
        case .daily:
            scheduleDailyReminder(for: event)
        case .weekly:
            scheduleWeeklyReminders(for: event)
        }
    }
    
    /// Schedule a daily reminder at the user's selected time
    private func scheduleDailyReminder(for event: SinceEvent) {
        // Get the user's selected time from reminder settings
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.reminderSettings.dailyReminderTime)
        let minute = calendar.component(.minute, from: event.reminderSettings.dailyReminderTime)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let content = createNotificationContent(for: event)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let identifier = notificationIdentifier(for: event, suffix: "daily")
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationManager: Error scheduling daily reminder - \(error.localizedDescription)")
            } else {
                print("NotificationManager: Scheduled daily reminder for \(event.title) at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    /// Schedule weekly reminders for selected days
    private func scheduleWeeklyReminders(for event: SinceEvent) {
        for weekday in event.reminderSettings.weeklyDays {
            // Generate a random hour between 9 AM and 8 PM
            let randomHour = Int.random(in: 9...20)
            let randomMinute = Int.random(in: 0...59)
            
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday.rawValue
            dateComponents.hour = randomHour
            dateComponents.minute = randomMinute
            
            let content = createNotificationContent(for: event)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let identifier = notificationIdentifier(for: event, suffix: "weekly-\(weekday.rawValue)")
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("NotificationManager: Error scheduling weekly reminder - \(error.localizedDescription)")
                } else {
                    print("NotificationManager: Scheduled weekly reminder for \(event.title) on \(weekday.fullName) at \(randomHour):\(randomMinute)")
                }
            }
        }
    }
    
    /// Create notification content for an event
    private func createNotificationContent(for event: SinceEvent) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Calculate days since event
        let elapsed = event.elapsedTime
        let days = Int(elapsed / 86400)
        let dayText = days == 1 ? "day" : "days"
        
        // Format: "10 days" as title, "Since no smoking" as body
        content.title = "\(days) \(dayText)"
        content.body = "Since \(event.title.lowercased())"
        
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
    private func notificationIdentifier(for event: SinceEvent, suffix: String) -> String {
        return "sinced-\(event.id.uuidString)-\(suffix)"
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel all reminders for a specific event
    func cancelReminders(for event: SinceEvent) {
        let baseIdentifier = "sinced-\(event.id.uuidString)"
        
        // Get all pending notifications and filter by event ID
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(baseIdentifier) }
                .map { $0.identifier }
            
            self?.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("NotificationManager: Cancelled \(identifiersToRemove.count) reminders for event \(event.title)")
        }
    }
    
    /// Cancel all scheduled notifications
    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("NotificationManager: Cancelled all reminders")
    }
    
    // MARK: - Refresh All Notifications
    
    /// Refresh all notifications based on current event settings
    func refreshAllReminders(events: [SinceEvent]) {
        guard notificationsEnabled else {
            cancelAllReminders()
            return
        }
        
        // Cancel all first
        cancelAllReminders()
        
        // Reschedule for events with enabled reminders
        for event in events where event.reminderSettings.isEnabled {
            scheduleReminders(for: event)
        }
    }
    
    // MARK: - Debug
    
    /// Print all pending notifications (for debugging)
    func printPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print("NotificationManager: \(requests.count) pending notifications:")
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("  - \(request.identifier): \(trigger.dateComponents)")
                }
            }
        }
    }
    
    func setNotificationsEnabled(_ enabled: Bool, events: [SinceEvent]) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: NotificationManager.notificationsEnabledKey)
        
        if enabled {
            refreshAllReminders(events: events)
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


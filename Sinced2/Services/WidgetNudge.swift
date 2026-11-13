//
//  WidgetNudge.swift
//  Sinced2
//
//  Knows whether a Sinced widget is installed, and nudges people who
//  haven't added one towards the guide
//

import Combine
import SwiftUI
import UserNotifications
import WidgetKit

/// Whether any Sinced widget is on the Home Screen or Lock Screen
final class WidgetStatus: ObservableObject {
    static let shared = WidgetStatus()

    /// nil until iOS has answered once
    @Published private(set) var hasWidget: Bool?

    private static let sawNoWidgetKey = "widgetGuide.sawNoWidget"
    private static let celebratedKey = "widgetGuide.celebrated"

    private init() {}

    /// Ask iOS which widgets are installed. Call when the app becomes active.
    func refresh(then completion: (() -> Void)? = nil) {
        WidgetCenter.shared.getCurrentConfigurations { result in
            // On failure keep the last answer rather than guessing
            let installed = (try? result.get()).map { !$0.isEmpty }
            DispatchQueue.main.async {
                if let installed {
                    self.apply(installed)
                }
                completion?()
            }
        }
    }

    private func apply(_ installed: Bool) {
        let defaults = UserDefaults.standard
        if installed {
            // Someone who had none and now has one just followed the guide
            if defaults.bool(forKey: Self.sawNoWidgetKey), !defaults.bool(forKey: Self.celebratedKey) {
                defaults.set(true, forKey: Self.celebratedKey)
                HapticManager.shared.success()
                ToastManager.shared.show("Widget added", icon: "checkmark.circle.fill", duration: 2.4)
            }
        } else {
            defaults.set(true, forKey: Self.sawNoWidgetKey)
        }

        guard hasWidget != installed else { return }
        withAnimation(.spring(duration: 0.4, bounce: 0)) {
            hasWidget = installed
        }
    }
}

/// Requests to show the widget guide from outside the UI
/// (a notification tap or the sinced://widget-guide link)
final class WidgetGuideRouter: ObservableObject {
    static let shared = WidgetGuideRouter()

    /// Stays true until the home screen picks it up, so a tap that
    /// launches the app cold isn't lost
    @Published var isRequested = false

    private init() {}
}

/// One local notification, about a day after the first event, for people
/// who allow notifications and still have no widget
enum WidgetNudge {
    static let notificationIdentifier = "widget-guide-nudge"
    static let userInfoKey = "open"
    static let userInfoValue = "widgetGuide"

    private static let introShownKey = "widgetGuide.introShown"
    private static let fireDateKey = "widgetGuide.nudgeFireDate"
    private static let finishedKey = "widgetGuide.nudgeFinished"

    private static var defaults: UserDefaults { .standard }

    /// The guide is offered once on its own, right after the first event
    static var introShown: Bool {
        get { defaults.bool(forKey: introShownKey) }
        set { defaults.set(newValue, forKey: introShownKey) }
    }

    /// Bring the pending nudge in line with what's true now. Safe to call
    /// often; rebuilding reminders clears every pending notification, so
    /// that calls this too.
    static func sync(hasEvents: Bool) {
        let center = UNUserNotificationCenter.current()
        guard !defaults.bool(forKey: finishedKey) else { return }
        // Don't decide anything until iOS has said whether a widget exists
        guard let hasWidget = WidgetStatus.shared.hasWidget else { return }

        if hasWidget {
            center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
            defaults.set(true, forKey: finishedKey)
            return
        }
        guard hasEvents else { return }

        let now = Date()
        let fireDate: Date
        if let stored = defaults.object(forKey: fireDateKey) as? Date {
            fireDate = stored
        } else {
            fireDate = preferredFireDate(after: now)
            defaults.set(fireDate, forKey: fireDateKey)
        }

        // It was delivered, or the moment passed without permission. Either
        // way this only ever happens once.
        guard fireDate > now else {
            defaults.set(true, forKey: finishedKey)
            return
        }

        guard NotificationManager.shared.notificationsEnabled else {
            center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
            return
        }

        let title = StorageManager.shared.loadEvents().first { !$0.isArchived }?.title
        center.getNotificationSettings { settings in
            // Never ask for permission just for this
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            if let title, !title.isEmpty {
                content.title = "Keep \u{201C}\(title)\u{201D} in sight"
            } else {
                content.title = "Keep your count in sight"
            }
            content.body = "Add the Sinced widget to your Home Screen. Tap to see how."
            content.sound = .default
            content.userInfo = [userInfoKey: userInfoValue]

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            // Same identifier every time, so adding again replaces rather than duplicates
            center.add(UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger))
        }
    }

    /// A day from now, moved out of the night
    private static func preferredFireDate(after now: Date) -> Date {
        let calendar = Calendar.current
        let candidate = now.addingTimeInterval(24 * 3600)
        let hour = calendar.component(.hour, from: candidate)
        if hour < 10 {
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: candidate) ?? candidate
        }
        if hour >= 21 {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: nextDay) ?? candidate
        }
        return candidate
    }
}

//
//  SharedSettings.swift
//  Shared (app + widget)
//
//  The few settings the widget extension needs too, kept in the App Group
//

import Foundation

enum SharedSettings {
    private static let defaults = UserDefaults(suiteName: "group.com.kolteaditya.sinced2")

    /// The person's name, used in some reminders. The app writes it here as
    /// well as in its own settings, so the widget can rewrite reminders.
    static var userName: String {
        get { defaults?.string(forKey: "userName") ?? "" }
        set { defaults?.set(newValue, forKey: "userName") }
    }
}

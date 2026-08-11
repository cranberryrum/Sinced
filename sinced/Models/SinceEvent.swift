//
//  SinceEvent.swift
//  sinced
//
//  Data model for tracking time since events
//

import Foundation
import SwiftUI

/// Card theme for event cards on home screen
enum CardTheme: String, Codable, CaseIterable, Identifiable {
    case mosaic = "Mosaic"
    case eyes = "Eyes"
    case circles = "Circles"
    case clouds = "Clouds"
    case puffs = "Puffs"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    /// Background color for the theme
    var backgroundColor: Color {
        switch self {
        case .mosaic: return Color(hex: "F1622A")
        case .eyes: return Color(hex: "FA96A1")
        case .circles: return Color(hex: "4D4AFD")
        case .clouds: return Color(hex: "4B800E")
        case .puffs: return Color(hex: "C09CF9")
        case .custom: return Color.clear
        }
    }
    
    /// Badge/pill background color
    var badgeBackgroundColor: Color {
        switch self {
        case .mosaic: return Color(hex: "243721")
        case .eyes: return Color(hex: "F03234")
        case .circles: return Color(hex: "2C2B45")
        case .clouds: return Color(hex: "BDD47E")
        case .puffs: return Color(hex: "2A1C57")
        case .custom: return Color.white
        }
    }
    
    /// Badge/pill text color
    var badgeTextColor: Color {
        switch self {
        case .mosaic: return .white
        case .eyes: return Color(hex: "FA96A1")
        case .circles: return .white
        case .clouds: return Color(hex: "4B800E")
        case .puffs: return Color(hex: "C09CF9")
        case .custom: return .black
        }
    }
    
    /// SVG asset name in Assets catalog
    var svgAssetName: String? {
        switch self {
        case .mosaic: return "EventCardSquareSVG/Mosaic"
        case .eyes: return "EventCardSquareSVG/Eyes"
        case .circles: return "EventCardSquareSVG/Circles"
        case .clouds: return "EventCardSquareSVG/Clouds"
        case .puffs: return "EventCardSquareSVG/Puffs"
        case .custom: return nil
        }
    }
    
    /// SVG asset name for widget
    var widgetSvgName: String? {
        switch self {
        case .mosaic: return "EventCardSquareSVG/Mosaic"
        case .eyes: return "EventCardSquareSVG/Eyes"
        case .circles: return "EventCardSquareSVG/Circles"
        case .clouds: return "EventCardSquareSVG/Clouds"
        case .puffs: return "EventCardSquareSVG/Puffs"
        case .custom: return nil
        }
    }
    
    /// Square SVG asset name for centered home tiles
    var squareSvgAssetName: String? {
        switch self {
        case .mosaic: return "EventCardSquareSVG/Mosaic"
        case .eyes: return "EventCardSquareSVG/Eyes"
        case .circles: return "EventCardSquareSVG/Circles"
        case .clouds: return "EventCardSquareSVG/Clouds"
        case .puffs: return "EventCardSquareSVG/Puffs"
        case .custom: return nil
        }
    }
    
    /// Display themes (excludes custom)
    static var displayThemes: [CardTheme] {
        [.mosaic, .eyes, .circles, .clouds, .puffs]
    }
}

/// Time unit for widget display
enum WidgetTimeUnit: String, Codable, CaseIterable {
    case hours = "Hours"
    case days = "Days"
    case months = "Months"
    case years = "Years"
}

/// Reminder frequency type
enum ReminderType: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
}

/// Days of the week for weekly reminders
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

/// Reminder settings for an event
struct ReminderSettings: Codable, Hashable {
    var isEnabled: Bool
    var reminderType: ReminderType
    var weeklyDays: [Weekday] // Only used when reminderType is .weekly
    var dailyReminderTime: Date // Time of day for daily reminders (only hour/minute components used)
    
    init(isEnabled: Bool = false, reminderType: ReminderType = .daily, weeklyDays: [Weekday] = [.monday], dailyReminderTime: Date? = nil) {
        self.isEnabled = isEnabled
        self.reminderType = reminderType
        self.weeklyDays = weeklyDays
        // Default to 9:00 AM if no time specified
        if let time = dailyReminderTime {
            self.dailyReminderTime = time
        } else {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            self.dailyReminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }
    
    // Custom decoding to handle migration from old format without dailyReminderTime
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        reminderType = try container.decode(ReminderType.self, forKey: .reminderType)
        weeklyDays = try container.decode([Weekday].self, forKey: .weeklyDays)
        // Handle migration: default to 9 AM if not present
        if let time = try? container.decode(Date.self, forKey: .dailyReminderTime) {
            dailyReminderTime = time
        } else {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            dailyReminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case isEnabled, reminderType, weeklyDays, dailyReminderTime
    }
}

/// Represents a single event that the user is tracking time since
struct SinceEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var startedAt: Date
    var colorHex: String?
    var goalDays: Int?
    var history: [Reset]
    var isArchived: Bool
    var imageData: Data? // Optional 1:1 image for widget
    var widgetTimeUnit: WidgetTimeUnit // Time unit for widget display
    var reminderSettings: ReminderSettings // Reminder notification settings
    var cardTheme: CardTheme // Theme for the large card on home screen
    
    /// Computed property for time elapsed since the event started
    var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startedAt)
    }
    
    /// Returns a formatted relative time string (e.g., "3h 22m", "2d 5h")
    var relativeTimeString: String {
        let elapsed = elapsedTime
        let minutes = Int(elapsed / 60)
        let hours = minutes / 60
        let days = hours / 24
        
        if days > 0 {
            let remainingHours = hours % 24
            if remainingHours > 0 {
                return "\(days)d \(remainingHours)h"
            }
            return "\(days)d"
        } else if hours > 0 {
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            }
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Returns a detailed time string (e.g., "3 days, 4 hours")
    var detailedTimeString: String {
        let elapsed = elapsedTime
        let minutes = Int(elapsed / 60)
        let hours = minutes / 60
        let days = hours / 24
        
        var components: [String] = []
        
        if days > 0 {
            components.append("\(days) day\(days == 1 ? "" : "s")")
        }
        
        let remainingHours = hours % 24
        if remainingHours > 0 {
            components.append("\(remainingHours) hour\(remainingHours == 1 ? "" : "s")")
        }
        
        let remainingMinutes = minutes % 60
        if remainingMinutes > 0 && days == 0 {
            components.append("\(remainingMinutes) minute\(remainingMinutes == 1 ? "" : "s")")
        }
        
        if components.isEmpty {
            return "Less than a minute"
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Returns a simple formatted start date string
    var smartFormattedStartDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        let currentYear = calendar.component(.year, from: now)
        let startedYear = calendar.component(.year, from: startedAt)
        
        let formatter = DateFormatter()
        if currentYear == startedYear {
            formatter.dateFormat = "d MMM"
        } else {
            formatter.dateFormat = "d MMM yyyy"
        }
        return formatter.string(from: startedAt)
    }
    
    /// Initializer with defaults
    init(
        id: UUID = UUID(),
        title: String,
        startedAt: Date = Date(),
        colorHex: String? = nil,
        goalDays: Int? = nil,
        history: [Reset] = [],
        isArchived: Bool = false,
        imageData: Data? = nil,
        widgetTimeUnit: WidgetTimeUnit = .days,
        reminderSettings: ReminderSettings = ReminderSettings(),
        cardTheme: CardTheme = .mosaic
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.colorHex = colorHex
        self.goalDays = goalDays
        self.history = history
        self.isArchived = isArchived
        self.imageData = imageData
        self.widgetTimeUnit = widgetTimeUnit
        self.reminderSettings = reminderSettings
        self.cardTheme = cardTheme
    }
    
    /// Smallest meaningful time unit for a freshly created event, so a new
    /// event never opens on "0 DAYS". Users can still change the unit later.
    static func defaultUnit(for startedAt: Date, now: Date = Date()) -> WidgetTimeUnit {
        let elapsed = now.timeIntervalSince(startedAt)
        if elapsed < 86_400 { return .hours }              // < 1 day
        if elapsed < 86_400 * 60 { return .days }          // < ~2 months
        if elapsed < 86_400 * 365 * 2 { return .months }   // < 2 years
        return .years
    }

    /// Generate notification title (e.g., "10 days")
    func notificationTitle() -> String {
        let elapsed = elapsedTime
        let days = Int(elapsed / 86400)
        let dayText = days == 1 ? "day" : "days"
        return "\(days) \(dayText)"
    }
    
    /// Generate notification body (e.g., "Since no smoking")
    func notificationBody() -> String {
        return "Since \(title.lowercased())"
    }
    
    /// Generate motivational notification message based on elapsed time (legacy, kept for compatibility)
    func notificationMessage() -> String {
        return "\(notificationTitle()) - \(notificationBody())"
    }
    
    /// Calculate next milestone information
    func nextMilestone() -> (days: Int, timeRemaining: String)? {
        let milestones = [1, 7, 30, 90, 365]
        let daysSince = Int(elapsedTime / 86400)
        
        guard let nextMilestone = milestones.first(where: { $0 > daysSince }) else {
            return nil
        }
        
        let totalSecondsRemaining = Double(nextMilestone) * 86400 - elapsedTime
        let daysRemaining = Int(totalSecondsRemaining / 86400)
        let hoursRemaining = Int((totalSecondsRemaining.truncatingRemainder(dividingBy: 86400)) / 3600)
        
        if daysRemaining > 0 {
            return (nextMilestone, "\(daysRemaining)d \(hoursRemaining)h")
        } else {
            return (nextMilestone, "\(hoursRemaining)h")
        }
    }
    
    /// Get widget display time based on selected unit
    func widgetTimeValue() -> String {
        let elapsed = elapsedTime
        
        switch widgetTimeUnit {
        case .hours:
            let hours = Int(elapsed / 3600)
            return "\(hours) \(hours == 1 ? "hour" : "hours")"
        case .days:
            let days = Int(elapsed / 86400)
            return "\(days) \(days == 1 ? "day" : "days")"
        case .months:
            let months = Int(elapsed / (86400 * 30))
            return "\(months) \(months == 1 ? "month" : "months")"
        case .years:
            let years = Int(elapsed / (86400 * 365))
            return "\(years) \(years == 1 ? "year" : "years")"
        }
    }
    
    /// Get large card display time in uppercase format (e.g., "200 HOURS")
    func largeCardTimeValue() -> String {
        let elapsed = elapsedTime
        
        switch widgetTimeUnit {
        case .hours:
            let hours = Int(elapsed / 3600)
            return "\(hours) \(hours == 1 ? "HOUR" : "HOURS")"
        case .days:
            let days = Int(elapsed / 86400)
            return "\(days) \(days == 1 ? "DAY" : "DAYS")"
        case .months:
            let months = Int(elapsed / (86400 * 30))
            return "\(months) \(months == 1 ? "MONTH" : "MONTHS")"
        case .years:
            let years = Int(elapsed / (86400 * 365))
            return "\(years) \(years == 1 ? "YEAR" : "YEARS")"
        }
    }
}

/// Represents a reset event in the timeline
struct Reset: Identifiable, Codable, Hashable {
    let id: UUID
    var at: Date
    var note: String?
    
    /// Returns formatted reset date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: at)
    }
    
    init(id: UUID = UUID(), at: Date = Date(), note: String? = nil) {
        self.id = id
        self.at = at
        self.note = note
    }
}


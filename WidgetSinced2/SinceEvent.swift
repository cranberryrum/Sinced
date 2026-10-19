//
//  SinceEvent.swift
//  Sinced2
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
        // Shown only if a custom photo is missing; keeps white text readable
        case .custom: return Color(hex: "313131")
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
    
    /// SVG asset name in Assets catalog (for widget, uses simple names from WidgetAssets.xcassets)
    var svgAssetName: String? {
        switch self {
        case .mosaic: return "Mosaic"
        case .eyes: return "Eyes"
        case .circles: return "Circles"
        case .clouds: return "Clouds"
        case .puffs: return "Puffs"
        case .custom: return nil
        }
    }
    
    /// SVG asset name for widget (simple names from WidgetAssets.xcassets)
    var widgetSvgName: String? {
        switch self {
        case .mosaic: return "Mosaic"
        case .eyes: return "Eyes"
        case .circles: return "Circles"
        case .clouds: return "Clouds"
        case .puffs: return "Puffs"
        case .custom: return nil
        }
    }
    
    /// Square SVG asset name for centered home tiles
    var squareSvgAssetName: String? {
        switch self {
        case .mosaic: return "Mosaic"
        case .eyes: return "Eyes"
        case .circles: return "Circles"
        case .clouds: return "Clouds"
        case .puffs: return "Puffs"
        case .custom: return nil
        }
    }
    
    /// Display themes (excludes custom)
    static var displayThemes: [CardTheme] {
        [.mosaic, .eyes, .circles, .clouds, .puffs]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
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
    /// Wall-clock time for daily reminders. Stored as hour/minute (not a Date)
    /// so the reminder stays at e.g. 9:00 after a time zone change.
    var dailyHour: Int
    var dailyMinute: Int
    
    /// The daily reminder time as a Date today (for pickers and formatting)
    var dailyReminderTime: Date {
        Calendar.current.date(bySettingHour: dailyHour, minute: dailyMinute, second: 0, of: Date()) ?? Date()
    }
    
    init(isEnabled: Bool = false, reminderType: ReminderType = .daily, weeklyDays: [Weekday] = [.monday], dailyReminderTime: Date? = nil) {
        self.isEnabled = isEnabled
        self.reminderType = reminderType
        self.weeklyDays = weeklyDays
        // Default to 9:00 AM if no time specified
        if let time = dailyReminderTime {
            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            self.dailyHour = components.hour ?? 9
            self.dailyMinute = components.minute ?? 0
        } else {
            self.dailyHour = 9
            self.dailyMinute = 0
        }
    }
    
    // Tolerant decoding: missing or unknown values fall back to defaults
    // instead of failing (and losing) the whole event list.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .isEnabled)) ?? false
        let typeRaw = (try? container.decodeIfPresent(String.self, forKey: .reminderType)) ?? nil
        reminderType = typeRaw.flatMap(ReminderType.init(rawValue:)) ?? .daily
        let dayValues = (try? container.decodeIfPresent([Int].self, forKey: .weeklyDays)) ?? nil
        let days = (dayValues ?? []).compactMap(Weekday.init(rawValue:))
        weeklyDays = days.isEmpty ? [.monday] : days
        
        if let hour = try? container.decodeIfPresent(Int.self, forKey: .dailyHour),
           let minute = try? container.decodeIfPresent(Int.self, forKey: .dailyMinute) {
            dailyHour = hour
            dailyMinute = minute
        } else if let legacyTime = try? container.decodeIfPresent(Date.self, forKey: .dailyReminderTime) {
            // Migration from builds that stored an absolute Date
            let components = Calendar.current.dateComponents([.hour, .minute], from: legacyTime)
            dailyHour = components.hour ?? 9
            dailyMinute = components.minute ?? 0
        } else {
            dailyHour = 9
            dailyMinute = 0
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(reminderType, forKey: .reminderType)
        try container.encode(weeklyDays, forKey: .weeklyDays)
        try container.encode(dailyHour, forKey: .dailyHour)
        try container.encode(dailyMinute, forKey: .dailyMinute)
    }
    
    private enum CodingKeys: String, CodingKey {
        case isEnabled, reminderType, weeklyDays, dailyReminderTime, dailyHour, dailyMinute
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
        // Never negative, even if a start date ends up in the future
        return max(0, Date().timeIntervalSince(startedAt))
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
    
    /// Older builds saved each reset with `at` = when the reset streak had
    /// started, instead of when the reset happened. History is newest first,
    /// and each reset happened when the next (newer) streak started, so the
    /// real reset time can be recovered from its neighbour.
    private static func migrateLegacyResets(_ history: [Reset], currentStart: Date) -> [Reset] {
        var migrated = history
        for index in migrated.indices where migrated[index].previousStart == nil {
            let nextStreakStart = index == 0
                ? currentStart
                : (migrated[index - 1].previousStart ?? migrated[index - 1].at)
            migrated[index].previousStart = migrated[index].at
            migrated[index].at = nextStreakStart
        }
        return migrated
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, startedAt, colorHex, goalDays, history, isArchived
        case imageData, widgetTimeUnit, reminderSettings, cardTheme
    }
    
    // Tolerant decoding: only id/title/startedAt are required. Anything else
    // that's missing or unrecognised (e.g. a field added in a later version)
    // falls back to its default instead of failing the whole event list.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        colorHex = (try? container.decodeIfPresent(String.self, forKey: .colorHex)) ?? nil
        goalDays = (try? container.decodeIfPresent(Int.self, forKey: .goalDays)) ?? nil
        history = Self.migrateLegacyResets(
            (try? container.decodeIfPresent([Reset].self, forKey: .history)) ?? [],
            currentStart: startedAt
        )
        isArchived = (try? container.decodeIfPresent(Bool.self, forKey: .isArchived)) ?? false
        imageData = (try? container.decodeIfPresent(Data.self, forKey: .imageData)) ?? nil
        let unitRaw = (try? container.decodeIfPresent(String.self, forKey: .widgetTimeUnit)) ?? nil
        widgetTimeUnit = unitRaw.flatMap(WidgetTimeUnit.init(rawValue:)) ?? .days
        reminderSettings = (try? container.decodeIfPresent(ReminderSettings.self, forKey: .reminderSettings)) ?? ReminderSettings()
        let themeRaw = (try? container.decodeIfPresent(String.self, forKey: .cardTheme)) ?? nil
        cardTheme = themeRaw.flatMap(CardTheme.init(rawValue:)) ?? .mosaic
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
    /// When the reset happened
    var at: Date
    var note: String?
    /// When the streak that was reset had started (nil for entries saved by older builds)
    var previousStart: Date?
    
    /// Returns formatted reset date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: at)
    }
    
    init(id: UUID = UUID(), at: Date = Date(), note: String? = nil, previousStart: Date? = nil) {
        self.id = id
        self.at = at
        self.note = note
        self.previousStart = previousStart
    }
}


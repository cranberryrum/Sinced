//
//  ShareMessage.swift
//  Sinced2
//
//  The words that go out with a shared card: the streak, the event, and a
//  link to Sinced. Short enough to read in a chat bubble, written in the
//  first person because the person sharing is the one saying it.
//

import UIKit
import LinkPresentation

enum ShareMessage {
    /// What a milestone or goal share is celebrating
    enum Moment: Equatable {
        case milestone(days: Int)
        case goal(days: Int)
    }

    /// e.g. "62 days since “No sugar”. Counting mine with Sinced:
    /// https://apps.apple.com/app/id6799975298"
    static func text(for event: SinceEvent, moment: Moment? = nil, at date: Date = Date()) -> String {
        let title = "“\(event.title.trimmingCharacters(in: .whitespacesAndNewlines))”"
        let line: String
        switch moment {
        case let .goal(days):
            line = "Reached my \(Milestones.goalAdjective(days)) goal: \(title)."
        case let .milestone(days):
            line = "Just hit \(Milestones.label(days)) since \(title)."
        case nil:
            line = "\(streak(for: event, at: date)) since \(title)."
        }
        return "\(line)\nCounting mine with Sinced: \(AppStoreLinks.listing.absoluteString)"
    }

    /// The streak in the unit the card shows: "62 days", "5 hours", "3 months"
    static func streak(for event: SinceEvent, at date: Date = Date()) -> String {
        let elapsed = max(0, date.timeIntervalSince(event.startedAt))
        let (seconds, unit): (TimeInterval, String) = {
            switch event.widgetTimeUnit {
            case .hours: return (3600, "hour")
            case .days: return (86400, "day")
            case .months: return (86400 * 30, "month")
            case .years: return (86400 * 365, "year")
            }
        }()
        let count = Int(elapsed / seconds)
        // "0 days since…" reads oddly in a message; fall back to hours or minutes
        if count == 0 {
            let hours = Int(elapsed / 3600)
            if hours > 0 { return "\(hours) \(hours == 1 ? "hour" : "hours")" }
            let minutes = max(1, Int(elapsed / 60))
            return "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
        }
        return "\(count) \(count == 1 ? unit : unit + "s")"
    }
}

/// The message as a share item. Messages, WhatsApp and Mail get the full
/// text; the link preview in the share sheet's header shows the event name.
final class ShareMessageItem: NSObject, UIActivityItemSource {
    private let message: String
    private let subject: String
    private let image: UIImage

    init(message: String, subject: String, image: UIImage) {
        self.message = message
        self.subject = subject
        self.image = image
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        message
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        message
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        subject
    }

    /// The card and the event name at the top of the share sheet
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = subject
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}

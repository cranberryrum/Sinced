//
//  ReviewPrompter.swift
//  Sinced2
//
//  Asks for an App Store rating at happy moments, and never right after a reset
//

import StoreKit
import UIKit

enum AppStoreLinks {
    static let appID = "6799975298"
    static let listing = URL(string: "https://apps.apple.com/app/id\(appID)")!
    static let writeReview = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!
}

@MainActor
enum ReviewPrompter {
    private static let launchCountKey = "reviewPrompter.launchCount"
    private static let lastPromptKey = "reviewPrompter.lastPromptAt"
    private static let lastVersionKey = "reviewPrompter.lastPromptVersion"

    private static let minimumLaunches = 3
    private static let milestoneRun: TimeInterval = 7 * 24 * 3600
    private static let quietAfterReset: TimeInterval = 48 * 3600
    private static let minimumGap: TimeInterval = 120 * 24 * 3600

    private static var defaults: UserDefaults { .standard }

    /// Call once per cold launch
    static func noteLaunch() {
        defaults.set(defaults.integer(forKey: launchCountKey) + 1, forKey: launchCountKey)
    }

    /// The app came to the foreground: ask if someone has a run worth celebrating
    static func considerOnForeground(events: [SinceEvent]) {
        guard events.contains(where: { $0.elapsedTime >= milestoneRun }) else { return }
        ask(events: events)
    }

    /// A card was just shared, which is about as happy as it gets
    static func considerAfterShare(events: [SinceEvent]) {
        ask(events: events)
    }

    private static func ask(events: [SinceEvent]) {
        guard defaults.integer(forKey: launchCountKey) >= minimumLaunches else { return }

        // Someone who slipped up recently isn't in the mood
        let now = Date()
        let recentlyReset = events.contains { event in
            event.history.contains { now.timeIntervalSince($0.at) < quietAfterReset }
        }
        guard !recentlyReset else { return }

        // Once per version, and well spaced out
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        guard defaults.string(forKey: lastVersionKey) != version else { return }
        if let last = defaults.object(forKey: lastPromptKey) as? Date,
           now.timeIntervalSince(last) < minimumGap { return }

        // Let the screen settle before the system sheet appears
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else { return }
            // Don't interrupt a sheet (reset, add event, share)
            let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
            guard root?.presentedViewController == nil else { return }

            AppStore.requestReview(in: scene)
            defaults.set(Date(), forKey: lastPromptKey)
            defaults.set(version, forKey: lastVersionKey)
        }
    }
}

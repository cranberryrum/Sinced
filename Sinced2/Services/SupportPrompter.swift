//
//  SupportPrompter.swift
//  Sinced2
//
//  Now and then, asks for a tip in a bottom sheet, always tied to a real
//  moment: a milestone of a week or more, a goal reached, or a shared card.
//  The moment is remembered, and the ask comes on the *next* app open, so it
//  never piles on top of the celebration itself.
//
//  Rules, all of which must hold:
//  - Sinced first seen 7+ days ago and opened 5+ times
//  - Never tipped, never tapped "Don't ask again"
//  - At most 6 asks ever, at least 20 days apart (6 asks over ~120 days)
//  - No reset in the last 48 hours, and no review prompt in the last 3 days
//  - Opened normally on Home: not from a widget, notification or link, and
//    nothing else on screen (a sheet, the milestone moment, the reset strip)
//
//  Everything is stored on this device only.
//

import Combine
import SwiftUI

@MainActor
final class SupportPrompter: ObservableObject {
    static let shared = SupportPrompter()

    /// What the ask is about; shapes its headline
    struct Moment: Codable, Equatable {
        enum Kind: String, Codable { case milestone, goal, share }
        let kind: Kind
        let title: String
        let days: Int
        let recordedAt: Date
    }

    struct Ask: Identifiable {
        let id = UUID()
        let moment: Moment
    }

    /// The ask on screen
    @Published var ask: Ask?
    /// The thank-you after tipping from the ask, shown once the ask has closed
    @Published var thanks: TipJar.Thanks?
    /// Set by the tab view: asks only appear over Home
    var homeVisible = true

    private var queuedThanks: TipJar.Thanks?
    /// When this visit to the app began (came from the background)
    private var sessionStart = Date()
    /// This visit began with a widget, notification or link: they came to do something
    private var arrivedWithPurpose = false
    private var pendingCheck: Task<Void, Never>?

    static let maxAsks = 6
    private static let minimumGap: TimeInterval = 20 * 24 * 3600
    private static let minimumAge: TimeInterval = 7 * 24 * 3600
    private static let minimumLaunches = 5
    private static let quietAfterReset: TimeInterval = 48 * 3600
    private static let quietAfterReview: TimeInterval = 3 * 24 * 3600
    private static let momentShelfLife: TimeInterval = 10 * 24 * 3600
    private static let milestoneMinimum = 7

    private enum Key {
        static let firstSeen = "supportPrompter.firstSeen"
        static let askCount = "supportPrompter.askCount"
        static let lastAsk = "supportPrompter.lastAskAt"
        static let optedOut = "supportPrompter.optedOut"
        static let moment = "supportPrompter.pendingMoment"
    }

    private var defaults: UserDefaults { .standard }

    private init() {
        if defaults.object(forKey: Key.firstSeen) == nil {
            defaults.set(Date(), forKey: Key.firstSeen)
        }
    }

    // MARK: - Moments

    /// A milestone moment just closed
    func noteCelebration(_ celebration: MilestoneCelebration) {
        guard celebration.isGoal || celebration.days >= Self.milestoneMinimum else { return }
        remember(Moment(kind: celebration.isGoal ? .goal : .milestone, title: celebration.title,
                        days: celebration.days, recordedAt: Date()))
    }

    /// A card was shared or saved
    func noteShare(title: String) {
        // A milestone is the better reason; don't replace one
        if let existing = pendingMoment, existing.kind != .share { return }
        remember(Moment(kind: .share, title: title, days: 0, recordedAt: Date()))
    }

    private func remember(_ moment: Moment) {
        guard let data = try? JSONEncoder().encode(moment) else { return }
        defaults.set(data, forKey: Key.moment)
    }

    private var pendingMoment: Moment? {
        guard let data = defaults.data(forKey: Key.moment) else { return nil }
        return try? JSONDecoder().decode(Moment.self, from: data)
    }

    // MARK: - Visits

    func noteBackground() {
        sessionStart = Date()
        arrivedWithPurpose = false
        pendingCheck?.cancel()
    }

    /// Opened from a widget, notification or link
    func noteArrivedWithPurpose() {
        arrivedWithPurpose = true
    }

    // MARK: - Asking

    /// Call when the app comes to the foreground, after milestones are checked
    func consider(viewModel: EventViewModel) {
        #if DEBUG
        // Launch with -SincedDemoSupportAsk to see the sheet now
        if ProcessInfo.processInfo.arguments.contains("-SincedDemoSupportAsk"), ask == nil {
            let title = viewModel.events.first?.title ?? "No sugar"
            remember(Moment(kind: .milestone, title: title, days: 30, recordedAt: .distantPast))
            schedule(viewModel: viewModel, ignoringRules: true)
            return
        }
        #endif
        guard isEligible(events: viewModel.events) else { return }
        schedule(viewModel: viewModel, ignoringRules: false)
    }

    private func schedule(viewModel: EventViewModel, ignoringRules: Bool) {
        pendingCheck?.cancel()
        pendingCheck = Task { [weak self, weak viewModel] in
            // Let Home settle, and let any milestone or reset strip claim the screen first
            try? await Task.sleep(for: .seconds(1.5))
            guard let self, let viewModel, !Task.isCancelled else { return }
            guard viewModel.hasCompletedOnboarding,
                  viewModel.celebration == nil, viewModel.outsideReset == nil,
                  viewModel.eventToOpen == nil, !AddFlow.shared.isPresented,
                  self.homeVisible, !self.arrivedWithPurpose, !Self.somethingPresented,
                  let moment = self.pendingMoment else { return }
            if !ignoringRules {
                guard self.isEligible(events: viewModel.events) else { return }
            }
            await TipJar.shared.loadProducts()
            guard TipJar.shared.loadState == .loaded || ignoringRules else { return }
            self.ask = Ask(moment: moment)
        }
    }

    private func isEligible(events: [SinceEvent]) -> Bool {
        let now = Date()
        guard let moment = pendingMoment,
              moment.recordedAt < sessionStart,
              now.timeIntervalSince(moment.recordedAt) < Self.momentShelfLife else { return false }

        guard !TipJar.shared.hasTipped, !defaults.bool(forKey: Key.optedOut) else { return false }

        let firstSeen = defaults.object(forKey: Key.firstSeen) as? Date ?? now
        guard now.timeIntervalSince(firstSeen) >= Self.minimumAge,
              ReviewPrompter.launchCount >= Self.minimumLaunches else { return false }

        guard defaults.integer(forKey: Key.askCount) < Self.maxAsks else { return false }
        if let last = defaults.object(forKey: Key.lastAsk) as? Date,
           now.timeIntervalSince(last) < Self.minimumGap { return false }

        if let review = ReviewPrompter.lastPromptAt,
           now.timeIntervalSince(review) < Self.quietAfterReview { return false }

        let recentlyReset = events.contains { event in
            event.history.contains { now.timeIntervalSince($0.at) < Self.quietAfterReset }
        }
        return !recentlyReset
    }

    private static var somethingPresented: Bool {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let root = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        return root?.presentedViewController != nil
    }

    // MARK: - From the sheet

    /// The sheet appeared: count the ask and use up its moment
    func recordAsk() {
        defaults.set(defaults.integer(forKey: Key.askCount) + 1, forKey: Key.askCount)
        defaults.set(Date(), forKey: Key.lastAsk)
        defaults.removeObject(forKey: Key.moment)
    }

    func optOut() {
        defaults.set(true, forKey: Key.optedOut)
    }

    /// A tip went through from the ask: thank them once the ask has closed
    func queueThanks(_ thanks: TipJar.Thanks) {
        queuedThanks = thanks
    }

    func askDidClose() {
        guard let queued = queuedThanks else { return }
        queuedThanks = nil
        thanks = queued
    }
}

//
//  OutsideResetBanner.swift
//  Sinced2
//
//  Asks about a reset made from a widget, Control Center, the Action button
//  or Siri, the next time the app is opened. The screen lifts like a card to
//  uncover a strip in the event's own colours, then settles back after a few
//  seconds. Missing it costs nothing: the event page still offers
//  "Undo last reset".
//

import SwiftUI

extension View {
    /// Lifts this screen to reveal an undo strip for `offer`. After a few
    /// seconds the screen drops back and `onTimeout` is called.
    func outsideResetReveal(
        _ offer: OutsideResetOffer?,
        after delay: Duration = .seconds(0.35),
        onUndo: @escaping () -> Void,
        onTimeout: @escaping () -> Void
    ) -> some View {
        modifier(OutsideResetReveal(offer: offer, delay: delay, onUndo: onUndo, onTimeout: onTimeout))
    }
}

// MARK: - The lift

private struct OutsideResetReveal: ViewModifier {
    let offer: OutsideResetOffer?
    let delay: Duration
    let onUndo: () -> Void
    let onTimeout: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var bottomInset: CGFloat = 0
    /// What's on screen. Trails `offer` so the screen can settle before it lifts.
    @State private var shown: OutsideResetOffer?
    /// 1 → 0 over the time the strip stays up; drains the Undo pill
    @State private var timeLeft: CGFloat = 1
    /// Seconds still to show, and when the clock last started
    @State private var remaining: Double = Self.visibleFor
    @State private var runningSince: Date?
    /// A finger resting on the strip stops the clock while they read
    @State private var isHeld = false

    /// Long enough to read and decide, short enough not to get in the way
    static let visibleFor: Double = 6

    /// The clock only runs while someone can actually see the strip
    private var clockRuns: Bool {
        shown != nil && !isHeld && scenePhase == .active && !UIAccessibility.isVoiceOverRunning
    }

    private struct ClockKey: Hashable {
        let eventID: UUID?
        let runs: Bool
    }
    /// The strip's own content
    static let contentHeight: CGFloat = 52
    private static let topPadding: CGFloat = 12
    private static let cornerRadius: CGFloat = 44

    private var isLifted: Bool { shown != nil && !reduceMotion }

    /// Below the strip, only what the home indicator needs. It's a thin line,
    /// so the strip sits close above it instead of leaving the inset empty.
    private var bottomPadding: CGFloat { max(0, bottomInset - 20) }

    private var lift: CGFloat {
        isLifted ? Self.topPadding + Self.contentHeight + bottomPadding : 0
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            // What the lifted screen uncovers: the event's colours, edge to edge
            if let shown {
                ResetStripBackground(theme: shown.theme)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if let shown, !reduceMotion {
                strip(for: shown)
                    // Covered by the card as it drops, rather than vanishing first
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
            }

            content
                .mask {
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: isLifted ? Self.cornerRadius : 0,
                        bottomTrailingRadius: isLifted ? Self.cornerRadius : 0,
                        style: .continuous
                    )
                    .ignoresSafeArea()
                }
                // A lifted card: a hair smaller, casting a shadow on the colour below
                .scaleEffect(isLifted ? 0.985 : 1, anchor: .top)
                .shadow(color: .black.opacity(isLifted ? 0.18 : 0), radius: 20, y: 8)
                .offset(y: -lift)

            // Reduce Motion: the screen stays put and the strip fades in over it
            if let shown, reduceMotion {
                strip(for: shown)
                    .background(ResetStripBackground(theme: shown.theme).ignoresSafeArea())
                    .transition(.opacity)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { bottomInset = $0 }
        .task(id: offer?.eventID) {
            guard let offer else {
                // Answered or timed out: drop back, quicker than it rose
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0)) {
                    shown = nil
                }
                return
            }
            // Let the screen arrive first, so the lift reads as its own moment
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            timeLeft = 1
            remaining = Self.visibleFor
            runningSince = nil
            // Drawer feel: moves straight away, long gentle settle, no bounce
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0)) {
                shown = offer
            }
            HapticManager.shared.light()
        }
        // The countdown. Restarts whenever it pauses or resumes, carrying
        // over the time that was left.
        .task(id: ClockKey(eventID: shown?.eventID, runs: clockRuns)) {
            guard shown != nil else { return }
            guard clockRuns else {
                // Paused: bank the time that passed and freeze the pill where it is
                if let started = runningSince {
                    remaining = max(0, remaining - Date().timeIntervalSince(started))
                    runningSince = nil
                }
                var still = Transaction()
                still.disablesAnimations = true
                withTransaction(still) { timeLeft = CGFloat(remaining / Self.visibleFor) }
                return
            }
            runningSince = Date()
            // Time passing is constant motion, so linear
            withAnimation(.linear(duration: remaining)) { timeLeft = 0 }
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }
            onTimeout()
        }
    }

    private func strip(for offer: OutsideResetOffer) -> some View {
        ResetStrip(offer: offer, timeLeft: timeLeft, isHeld: $isHeld, onUndo: onUndo)
            .frame(height: Self.contentHeight)
            .padding(.top, Self.topPadding)
            .padding(.bottom, bottomPadding)
            .id(offer.eventID)
    }
}

// MARK: - The strip

private struct ResetStrip: View {
    let offer: OutsideResetOffer
    let timeLeft: CGFloat
    @Binding var isHeld: Bool
    let onUndo: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: ResetStripPalette { .init(theme: offer.theme) }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(offer.title) was reset")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.text.opacity(0.78))
                    .lineLimit(1)
                    .entering(appeared, delay: 0.12, reduceMotion: reduceMotion)

                Text(StreakText.label(for: offer.lostRun))
                    .font(.custom("GeistMono-Medium", size: 19))
                    .tracking(-0.4)
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .entering(appeared, delay: 0.16, reduceMotion: reduceMotion)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            // Resting a finger on the words pauses the countdown
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 40) {
            } onPressingChanged: { pressing in
                isHeld = pressing
            }
            .accessibilityElement(children: .combine)

            Button(action: onUndo) {
                Text("Undo")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.pillText)
                    .frame(width: 84, height: 40)
                    .background {
                        ZStack {
                            Capsule().fill(palette.pill)
                            // Empties as the time runs out
                            Capsule()
                                .fill(palette.pillText.opacity(0.16))
                                .scaleEffect(x: max(timeLeft, 0.001), y: 1, anchor: .leading)
                        }
                        .clipShape(Capsule())
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .entering(appeared, delay: 0.2, reduceMotion: reduceMotion)
            .accessibilityHint("Brings back your \(StreakText.text(for: offer.lostRun))")
        }
        .padding(.horizontal, 22)
        .onAppear { appeared = true }
    }
}

private extension View {
    /// Rises 8pt into place a beat after the lift starts. Items are 40ms
    /// apart so the strip assembles rather than appearing all at once.
    func entering(_ appeared: Bool, delay: Double, reduceMotion: Bool) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 8)
            .animation(.easeOut(duration: 0.26).delay(reduceMotion ? 0 : delay), value: appeared)
    }
}

// MARK: - Colours

/// A soft mesh of the theme's own colours, with a calm area under the text
private struct ResetStripBackground: View {
    let theme: CardTheme

    var body: some View {
        let p = ResetStripPalette(theme: theme)
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.55, 0], [1, 0],
                    [0, 0.5], [0.42, 0.62], [1, 0.45],
                    [0, 1], [0.6, 1], [1, 1]
                ],
                colors: [
                    p.calm, p.base, p.glow,
                    p.calm, p.calm, p.base,
                    p.deep, p.calm, p.glow
                ],
                smoothsColors: true
            )
            // Keeps the words readable whatever the glow does around them
            LinearGradient(
                colors: [p.calm.opacity(0.7), p.calm.opacity(0)],
                startPoint: .leading,
                endPoint: UnitPoint(x: 0.75, y: 0.5)
            )
            GrainOverlay(intensity: 0.07)
        }
    }
}

/// Colours for one theme. `calm` sits under the text and is chosen to
/// contrast with `text`; `base`, `glow` and `deep` give the dreamy edges.
private struct ResetStripPalette {
    let calm: Color
    let base: Color
    let glow: Color
    let deep: Color
    let text: Color
    let pill: Color
    let pillText: Color

    init(theme: CardTheme) {
        switch theme {
        case .mosaic:
            (calm, base, glow, deep) = (Color(hex: "B8390A"), Color(hex: "F1622A"), Color(hex: "FFB347"), Color(hex: "5A1A06"))
            (text, pill, pillText) = (.white, .white, Color(hex: "5A1A06"))
        case .eyes:
            (calm, base, glow, deep) = (Color(hex: "FFC4CB"), Color(hex: "FA96A1"), Color(hex: "F03234"), Color(hex: "FFE3E6"))
            (text, pill, pillText) = (Color(hex: "3A0A12"), Color(hex: "3A0A12"), .white)
        case .circles:
            (calm, base, glow, deep) = (Color(hex: "2B28B8"), Color(hex: "4D4AFD"), Color(hex: "9DB0FF"), Color(hex: "14134A"))
            (text, pill, pillText) = (.white, .white, Color(hex: "1C1A6B"))
        case .clouds:
            (calm, base, glow, deep) = (Color(hex: "2F5A08"), Color(hex: "4B800E"), Color(hex: "BDD47E"), Color(hex: "142805"))
            (text, pill, pillText) = (.white, .white, Color(hex: "1E3A05"))
        case .puffs:
            (calm, base, glow, deep) = (Color(hex: "E3D3FF"), Color(hex: "C09CF9"), Color(hex: "8B5CF6"), Color(hex: "F3ECFF"))
            (text, pill, pillText) = (Color(hex: "2A1C57"), Color(hex: "2A1C57"), .white)
        case .waves:
            (calm, base, glow, deep) = (Color(hex: "0A5E5D"), Color(hex: "0E7C7B"), Color(hex: "8FE3CF"), Color(hex: "042F2F"))
            (text, pill, pillText) = (.white, .white, Color(hex: "053B3B"))
        case .blooms:
            (calm, base, glow, deep) = (Color(hex: "A52A5C"), Color(hex: "D23C77"), Color(hex: "FFD45E"), Color(hex: "5C0F30"))
            (text, pill, pillText) = (.white, .white, Color(hex: "6E1239"))
        case .steps:
            (calm, base, glow, deep) = (Color(hex: "1F1F24"), Color(hex: "3A2418"), Color(hex: "FF7A2F"), Color(hex: "121215"))
            (text, pill, pillText) = (.white, Color(hex: "FF7A2F"), Color(hex: "1F1F24"))
        case .custom:
            (calm, base, glow, deep) = (Color(hex: "2A2A2E"), Color(hex: "3A3A40"), Color(hex: "6E6E78"), Color(hex: "151517"))
            (text, pill, pillText) = (.white, .white, Color(hex: "1A1A1C"))
        }
    }
}

// MARK: - Words

/// How long a run lasted, in the words that matter for a streak: whole days
/// once it's at least a day ("62 days", not "2 months")
enum StreakText {
    static func text(for interval: TimeInterval) -> String {
        let days = Int(interval / 86400)
        guard days >= 1 else { return SincedDurationText.text(for: interval) }
        return "\(days) \(days == 1 ? "day" : "days")"
    }

    /// "62-day streak", "5-hour streak", "12-minute streak"
    static func label(for interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        let (value, unit): (Int, String) =
            seconds >= 86400 ? (seconds / 86400, "day")
            : seconds >= 3600 ? (seconds / 3600, "hour")
            : (max(1, seconds / 60), "minute")
        return "\(value)-\(unit) streak"
    }
}

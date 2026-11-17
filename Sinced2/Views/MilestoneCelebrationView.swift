//
//  MilestoneCelebrationView.swift
//  Sinced2
//
//  The full-screen moment shown the first time the app opens after a
//  milestone or a goal. Rare and earned, so it's allowed real delight: the
//  count climbs number by number with a haptic tick on each that builds as
//  it rises, soft glows in the event's colours drift behind it, and it lands
//  with a bloom of light.
//

import SwiftUI
import UIKit

struct MilestoneCelebration: Identifiable, Equatable {
    let eventID: UUID
    let title: String
    let theme: CardTheme
    let days: Int
    let isGoal: Bool
    let isComeback: Bool

    var id: String { "\(eventID)-\(days)" }

    /// Where the count starts climbing from. Every number gets its own tick,
    /// so the climb is at most 30 numbers: all the way up for short counts,
    /// the last stretch for long ones.
    var countFrom: Int { max(0, days - 30) }
}

struct MilestoneCelebrationView: View {
    let celebration: MilestoneCelebration
    let event: SinceEvent?
    let onClose: () -> Void
    let onSetNextGoal: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var count = 0
    @State private var landed = false
    @State private var step = 0
    @State private var dragY: CGFloat = 0
    @State private var sharing = false

    private var colors: CelebrationColors { .init(theme: celebration.theme) }
    private var words: String {
        Milestones.words(for: celebration.days, isGoal: celebration.isGoal, isComeback: celebration.isComeback)
    }

    var body: some View {
        ZStack {
            CelebrationBackground(colors: colors, landed: landed)
                .ignoresSafeArea()

            VStack(spacing: 6) {
                Text(celebration.title)
                    .font(.allo(17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .settle(step >= 1, reduceMotion)

                Text("\(count)")
                    .font(.allo(156, weight: .medium).monospacedDigit())
                    .tracking(-8)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText(value: Double(count)))
                    // A small pop as it lands on the milestone
                    .scaleEffect(landed && !reduceMotion ? 1 : 0.96)
                    .shadow(color: colors.main.opacity(landed ? 0.7 : 0), radius: 30)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: landed)

                Text(celebration.days == 1 ? "DAY" : "DAYS")
                    .font(.allo(16, weight: .medium).monospacedDigit())
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.9))
                    .settle(step >= 2, reduceMotion)

                Text(words)
                    .font(.allo(20, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .settle(step >= 3, reduceMotion)
            }
            .padding(.horizontal, 28)
            .offset(y: -36)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(Milestones.label(celebration.days)) since \(celebration.title). \(words)")

            VStack(spacing: 6) {
                Spacer()
                Button {
                    HapticManager.shared.light()
                    sharing = true
                } label: {
                    Text("Share")
                        .font(.allo(17, weight: .semibold))
                        .foregroundStyle(Color(hex: "141417"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Capsule().fill(.white))
                }
                .buttonStyle(PressableButtonStyle())

                Button(celebration.isGoal ? "Set the next goal" : "Keep going") {
                    HapticManager.shared.light()
                    celebration.isGoal ? onSetNextGoal() : onClose()
                }
                .font(.allo(16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .settle(step >= 4, reduceMotion)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.white.opacity(0.14)))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.trailing, 12)
            .accessibilityLabel("Close")
            .settle(step >= 4, reduceMotion)
        }
        // Follows a downward drag 1:1; a flick or a long pull closes it
        .offset(y: dragY)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let y = value.translation.height
                    dragY = y > 0 ? y : y * 0.2
                }
                .onEnded { value in
                    if value.translation.height > 140 || value.predictedEndTranslation.height > 260 {
                        onClose()
                    } else {
                        withAnimation(.spring(duration: 0.35, bounce: 0)) { dragY = 0 }
                    }
                }
        )
        .sheet(isPresented: $sharing) {
            if let event {
                ShareSheetView(
                    event: event,
                    moment: celebration.isGoal ? .goal(days: celebration.days) : .milestone(days: celebration.days)
                )
            }
        }
        .task { await play() }
    }

    // MARK: - The climb

    private func play() async {
        let from = celebration.countFrom
        let to = celebration.days
        count = from

        if reduceMotion {
            count = to
            withAnimation(.easeOut(duration: 0.3)) { landed = true; step = 4 }
            HapticManager.shared.success()
            return
        }

        withAnimation(.easeOut(duration: 0.42)) { step = 1 }
        try? await Task.sleep(for: .seconds(0.35))

        // One tick per number. It starts unhurried and speeds up, and each
        // tick is a little firmer than the last, so the count and the haptics
        // build together toward the landing.
        let ticks = to - from
        let total = min(1.7, 0.5 + Double(ticks) * 0.045)
        let weights = (0..<ticks).map { i -> Double in
            let t = ticks > 1 ? Double(i) / Double(ticks - 1) : 1
            return 1.9 - 1.4 * t
        }
        let unit = total / weights.reduce(0, +)
        let haptic = UIImpactFeedbackGenerator(style: .rigid)
        haptic.prepare()

        for i in 0..<ticks {
            try? await Task.sleep(for: .seconds(weights[i] * unit))
            guard !Task.isCancelled else { return }
            let progress = ticks > 1 ? Double(i) / Double(ticks - 1) : 1
            withAnimation(.easeOut(duration: 0.12)) { count = from + i + 1 }
            if i < ticks - 1 {
                haptic.impactOccurred(intensity: 0.3 + 0.6 * progress)
                haptic.prepare()
            }
        }

        // Landing: the strongest beat, a bloom of light, then the words
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeOut(duration: 0.9)) { landed = true }
        try? await Task.sleep(for: .seconds(0.25))
        withAnimation(.easeOut(duration: 0.42)) { step = 2 }
        try? await Task.sleep(for: .seconds(0.08))
        withAnimation(.easeOut(duration: 0.42)) { step = 3 }
        try? await Task.sleep(for: .seconds(0.12))
        withAnimation(.easeOut(duration: 0.42)) { step = 4 }
    }
}

// MARK: - Background

/// The glow colours for each theme: `main` is the event's own colour and
/// `accent` the second colour it pairs with
struct CelebrationColors {
    let main: Color
    let accent: Color

    init(theme: CardTheme) {
        switch theme {
        case .mosaic: (main, accent) = (Color(hex: "F1622A"), Color(hex: "FFB347"))
        case .eyes: (main, accent) = (Color(hex: "FA7C8B"), Color(hex: "F03234"))
        case .circles: (main, accent) = (Color(hex: "4D4AFD"), Color(hex: "8FB0FF"))
        case .clouds: (main, accent) = (Color(hex: "6BB026"), Color(hex: "D2E68F"))
        case .puffs: (main, accent) = (Color(hex: "A77BFA"), Color(hex: "E3CCFF"))
        case .waves: (main, accent) = (Color(hex: "0EA5A3"), Color(hex: "8FE3CF"))
        case .blooms: (main, accent) = (Color(hex: "E0457F"), Color(hex: "FFD45E"))
        case .steps: (main, accent) = (Color(hex: "FF7A2F"), Color(hex: "FFC08A"))
        case .custom: (main, accent) = (Color(hex: "8E8EA0"), Color(hex: "DADAE6"))
        }
    }
}

/// A dark ground with large, heavily blurred glows in the event's colours
/// and a soft white haze behind the number. The glows drift slowly, and
/// bloom brighter when the count lands.
private struct CelebrationBackground: View {
    let colors: CelebrationColors
    let landed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                ZStack {
                    Color(hex: "060608")

                    // Pools of the event's colour at the edges, with real dark
                    // between them, like light leaking in from off screen
                    glow(colors.main, size: w * 1.1, blur: 70, opacity: 0.95,
                         x: w * 0.5 + sin(t * 0.21) * 34, y: -h * 0.06 + cos(t * 0.17) * 26)
                    glow(colors.accent, size: w * 0.8, blur: 70, opacity: 0.7,
                         x: w * 1.04 + cos(t * 0.19) * 26, y: h * 1.0 + sin(t * 0.23) * 28)
                    glow(colors.main, size: w * 0.65, blur: 65, opacity: 0.75,
                         x: -w * 0.08 + sin(t * 0.15) * 24, y: h * 0.62 + cos(t * 0.2) * 30)

                    // The soft white light behind the number, tinted by the event,
                    // that blooms brighter when the count lands
                    glow(colors.main, size: w * 0.62, blur: 60, opacity: landed ? 0.55 : 0.3,
                         x: w * 0.5, y: h * 0.42)
                    glow(.white, size: w * 0.42, blur: 55, opacity: landed ? 0.32 : 0.12,
                         x: w * 0.5 + sin(t * 0.13) * 14, y: h * 0.42 + cos(t * 0.11) * 12)

                    GrainOverlay(intensity: 0.08)
                }
                .animation(.easeOut(duration: 0.9), value: landed)
            }
        }
        .accessibilityHidden(true)
    }

    private func glow(_ color: Color, size: CGFloat, blur: CGFloat, opacity: Double, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: blur)
            .opacity(opacity)
            .position(x: x, y: y)
    }
}

private extension View {
    /// Rises 8pt into place; Reduce Motion keeps the fade and drops the movement
    func settle(_ shown: Bool, _ reduceMotion: Bool) -> some View {
        self
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 8)
    }
}

//
//  MilestoneSpotlight.swift
//  Sinced2
//
//  A milestone celebrated where the counter lives. Home dims and steps back,
//  the card that reached it lifts a little and counts up from 0 to the
//  milestone, each number rolling in with a tick that grows stronger, and
//  when it lands confetti bursts across the screen. Tap the card to open the
//  event as usual; tap anywhere else to carry on.
//

import SwiftUI
import UIKit
import Combine

struct MilestoneSpotlight: View {
    let celebration: MilestoneCelebration
    let event: SinceEvent
    /// Where the card sits on home, in window coordinates
    let cardFrame: CGRect?
    let onOpen: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dimmed = false
    @State private var lifted = false
    @State private var count = 0
    @State private var showsWords = false
    @State private var burst: Date?

    private var colors: CelebrationColors { .init(theme: celebration.theme) }
    private var words: String {
        Milestones.words(for: celebration.days, isGoal: celebration.isGoal, isComeback: celebration.isComeback)
    }

    var body: some View {
        GeometryReader { proxy in
            let screen = proxy.frame(in: .global)
            let card = placement(in: screen)
            ZStack(alignment: .topLeading) {
                // Everything else steps back
                Color.black
                    .opacity(dimmed ? 0.42 : 0)
                    .contentShape(Rectangle())
                    .onTapGesture { finish(onDismiss) }
                    .accessibilityLabel("Close")
                    .accessibilityAddTraits(.isButton)

                HomeEventCardView(
                    event: event,
                    countOverride: count,
                    subtitleOverride: showsWords ? "✦ \(words)" : nil
                )
                .frame(width: card.width, height: card.height)
                .scaleEffect(lifted ? 1.06 : 1)
                .shadow(color: .black.opacity(lifted ? 0.32 : 0.1), radius: lifted ? 26 : 9, y: lifted ? 18 : 8)
                // Only the card itself opens the event; the rest closes
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .onTapGesture {
                    HapticManager.shared.light()
                    finish(onOpen)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(event.title), \(Milestones.label(celebration.days)). \(words)")
                .accessibilityHint("Opens the counter")
                .accessibilityAddTraits(.isButton)
                .position(x: card.midX - screen.minX, y: card.midY - screen.minY)

                // Over everything, and never in the way of a tap
                if let burst {
                    ConfettiBurst(
                        start: burst,
                        origin: CGPoint(x: card.midX - screen.minX, y: card.midY - screen.minY),
                        size: screen.size,
                        colors: [colors.main, colors.accent, .white, Color(hex: "FFD45E"), Color(hex: "FF8FA3")]
                    )
                    .frame(width: screen.width, height: screen.height)
                    .allowsHitTesting(false)
                }
            }
        }
        .ignoresSafeArea()
        .transition(.opacity)
        .task { await play() }
    }

    /// The card's own place on home when it's in view; otherwise the middle
    /// of the screen, so the moment never plays off-screen
    private func placement(in screen: CGRect) -> CGRect {
        if let frame = cardFrame, frame.width > 0,
           frame.minY > screen.minY + 80, frame.maxY < screen.maxY - 110 {
            return frame
        }
        let side = min(screen.width * 0.56, 240)
        return CGRect(x: screen.midX - side / 2, y: screen.midY - side / 2 - 30, width: side, height: side)
    }

    private func play() async {
        // Home dims and the card lifts, its number dropping to 0 to start
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.45)) { dimmed = true }
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.25)) {
            lifted = !reduceMotion
        }
        withAnimation(.snappy(duration: 0.3)) { count = 0 }
        try? await Task.sleep(for: .seconds(0.45))
        guard !Task.isCancelled else { return }

        let days = celebration.days
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.2)) { count = days }
        } else {
            // Quick at first, slowing into the milestone. Long milestones
            // count in jumps, so it's never more than 40 ticks.
            let steps = min(days, 40)
            let total = 1.6
            let tick = UIImpactFeedbackGenerator(style: .rigid)
            tick.prepare()
            var elapsed = 0.0
            for k in 1...max(steps, 1) {
                let p = Double(k) / Double(max(steps, 1))
                let at = total * pow(p, 1.8)
                try? await Task.sleep(for: .seconds(max(0, at - elapsed)))
                elapsed = at
                guard !Task.isCancelled else { return }
                withAnimation(.snappy(duration: 0.22)) { count = Int((Double(days) * p).rounded()) }
                // Each number a little firmer than the last
                tick.impactOccurred(intensity: 0.3 + 0.6 * p)
            }
        }

        // Land: a firm tap, the words, and confetti across the screen
        guard !Task.isCancelled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(duration: 0.4, bounce: 0.35)) { showsWords = true }
        if !reduceMotion { burst = Date() }
        AccessibilityNotification.Announcement("\(event.title) reached \(Milestones.label(days)). \(words)").post()

        try? await Task.sleep(for: .seconds(3.6))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.25)) { showsWords = false }
    }

    private func finish(_ action: () -> Void) {
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.3)) {
            lifted = false
            dimmed = false
            count = celebration.days
        }
        action()
    }
}

/// Paper confetti thrown up from a point, tumbling as it falls off the
/// bottom of the screen, with a lighter second fall from the top edge.
/// Drawn in a Canvas, so it's one view however many pieces there are.
private struct ConfettiBurst: View {
    let start: Date
    let origin: CGPoint
    let size: CGSize
    let colors: [Color]

    @State private var pieces: [Piece] = []
    @State private var now = Date()

    struct Piece {
        var x: CGFloat, y: CGFloat
        var vx: CGFloat, vy: CGFloat
        var delay: Double
        var spin: Double, spinSpeed: Double
        var tilt: Double, tiltSpeed: Double
        var width: CGFloat, height: CGFloat
        var color: Int
        var round: Bool
    }

    var body: some View {
        let t = now.timeIntervalSince(start)
        Canvas { ctx, _ in
                for piece in pieces {
                    let life = t - piece.delay
                    guard life > 0 else { continue }
                    // Air slows the throw; gravity takes over
                    let drag = exp(-1.6 * life)
                    let x = piece.x + piece.vx * (1 - drag) / 1.6 + sin(life * 3 + piece.tilt) * 14
                    let y = piece.y + piece.vy * (1 - drag) / 1.6 + 520 * life * life * 0.5
                    guard y < size.height + 40 else { continue }
                    let fade = min(1, max(0, (3.6 - life) / 0.6))
                    // Turning over: the piece narrows and widens as it tumbles
                    let flip = abs(cos(piece.tiltSpeed * life + piece.tilt))
                    var c = ctx
                    c.opacity = fade
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(piece.spin + piece.spinSpeed * life))
                    let rect = CGRect(x: -piece.width / 2, y: -piece.height * flip / 2, width: piece.width, height: max(1, piece.height * flip))
                    let path = piece.round ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1.5)
                    c.fill(path, with: .color(colors[piece.color % colors.count]))
                }
        }
        // A frame clock for the fall; stops once every piece has gone
        .onReceive(Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()) { date in
            if date.timeIntervalSince(start) < 4.5 { now = date }
        }
        .onAppear { pieces = Self.make(origin: origin, size: size, colors: colors.count) }
        .task { if pieces.isEmpty { pieces = Self.make(origin: origin, size: size, colors: colors.count) } }
    }

    private static func make(origin: CGPoint, size: CGSize, colors: Int) -> [Piece] {
        var all: [Piece] = []
        // The pop: thrown up and out from the card
        for i in 0..<90 {
            let angle = -Double.pi / 2 + Double.random(in: -1.25...1.25)
            let speed = CGFloat.random(in: 420...1050)
            all.append(Piece(
                x: origin.x + .random(in: -20...20), y: origin.y + .random(in: -20...20),
                vx: CGFloat(cos(angle)) * speed, vy: CGFloat(sin(angle)) * speed,
                delay: Double.random(in: 0...0.08),
                spin: .random(in: 0...(2 * .pi)), spinSpeed: .random(in: -7...7),
                tilt: .random(in: 0...(2 * .pi)), tiltSpeed: .random(in: 5...11),
                width: .random(in: 7...11), height: .random(in: 12...18),
                color: i % colors, round: i % 7 == 0
            ))
        }
        // A softer fall from the top edge, just after
        for i in 0..<36 {
            all.append(Piece(
                x: .random(in: 0...size.width), y: -20,
                vx: .random(in: -60...60), vy: .random(in: 40...160),
                delay: Double.random(in: 0.25...0.9),
                spin: .random(in: 0...(2 * .pi)), spinSpeed: .random(in: -5...5),
                tilt: .random(in: 0...(2 * .pi)), tiltSpeed: .random(in: 4...9),
                width: .random(in: 6...9), height: .random(in: 10...15),
                color: (i + 2) % colors, round: i % 6 == 0
            ))
        }
        return all
    }
}

//
//  FloatingCardHost.swift
//  Sinced2
//
//  The add card's floating card, for anything else: it grows out of what
//  was tapped, sits 8pt in from the screen with the screen's own corner
//  radius, fits its content, rides above the keyboard, and folds back into
//  where it came from. Reset, reminders and delete on the event page use it.
//

import SwiftUI
import UIKit

/// Closes the card, then runs `then` once it has gone
typealias FloatingCardClose = (_ then: (() -> Void)?) -> Void

struct FloatingCardHost<Content: View>: View {
    /// What the card grows out of, in window coordinates
    let source: CGRect
    var sourceRadius: CGFloat = 20
    let onDismissed: () -> Void
    @ViewBuilder let content: (_ close: @escaping FloatingCardClose) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var open = false
    @State private var contentShown = false
    @State private var shellOpacity: Double = 0
    @State private var scrimShown = false
    @State private var height: CGFloat = 260
    @State private var keyboard: CGFloat = 0
    @State private var dragY: CGFloat = 0
    @State private var closing = false

    private let inset: CGFloat = 8
    private static func easeOut(_ d: Double) -> Animation { .timingCurve(0.23, 1, 0.32, 1, duration: d) }

    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            let width = proxy.size.width - inset * 2
            let frame = cardFrame(size: proxy.size, origin: origin)

            ZStack(alignment: .topLeading) {
                Color.black
                    .opacity(scrimShown ? 0.24 * (1 - min(1, max(0, dragY) / 500)) : 0)
                    .contentShape(Rectangle())
                    .onTapGesture { close(nil) }
                    .allowsHitTesting(scrimShown)
                    .accessibilityHidden(true)

                ZStack(alignment: .top) {
                    Color.white
                    content(close)
                        .padding(.top, 28)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 22)
                        .frame(width: width, alignment: .topLeading)
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { new in
                            if open { withAnimation(.spring(duration: 0.38, bounce: 0.06)) { height = new } } else { height = new }
                        }
                        .opacity(contentShown ? 1 : 0)
                        .blur(radius: contentShown || reduceMotion ? 0 : 6)
                }
                .frame(width: frame.width, height: frame.height, alignment: .top)
                .clipShape(RoundedRectangle(cornerRadius: open ? DisplayCorners.concentric(inset: inset) : sourceRadius, style: .continuous))
                .shadow(color: .black.opacity(contentShown ? 0.16 : 0), radius: 30, y: 16)
                .opacity(shellOpacity)
                .offset(x: frame.minX, y: frame.minY + dragY)
                .gesture(dismissDrag)
                .accessibilityAddTraits(.isModal)
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: appear)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            guard let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            withAnimation(.spring(duration: 0.38, bounce: 0)) { keyboard = max(0, AddEventOverlay.windowBounds.height - end.minY) }
        }
    }

    private func cardFrame(size: CGSize, origin: CGPoint) -> CGRect {
        guard open else {
            let s = source.offsetBy(dx: -origin.x, dy: -origin.y)
            return s.width > 0 ? s : CGRect(x: size.width / 2 - 60, y: size.height - 140, width: 120, height: 60)
        }
        let bottomGap = keyboard > 0 ? keyboard + inset : inset
        let h = min(height, size.height - AddEventOverlay.safeTop - 12 - bottomGap)
        return CGRect(x: inset, y: size.height - bottomGap - h, width: size.width - inset * 2, height: h)
    }

    private func appear() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(20))
            HapticManager.shared.light()
            if reduceMotion {
                open = true
                withAnimation(.easeOut(duration: 0.2)) { shellOpacity = 1; contentShown = true; scrimShown = true }
                return
            }
            withAnimation(.spring(duration: 0.46, bounce: 0.14)) { open = true }
            withAnimation(Self.easeOut(0.18)) { shellOpacity = 1 }
            withAnimation(Self.easeOut(0.3).delay(0.08)) { contentShown = true }
            withAnimation(Self.easeOut(0.3)) { scrimShown = true }
        }
    }

    private func close(_ then: (() -> Void)?) {
        guard !closing else { return }
        closing = true
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(Self.easeOut(0.12)) { contentShown = false }
        withAnimation(Self.easeOut(0.25)) { scrimShown = false }
        withAnimation(Self.easeOut(0.22).delay(reduceMotion ? 0 : 0.08)) { shellOpacity = 0 }
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.38, bounce: 0)) {
            if !reduceMotion { open = false }
            dragY = 0
        } completion: {
            onDismissed()
            then?()
        }
    }

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let y = value.translation.height
                dragY = y > 0 ? y : -pow(-y, 0.7)
            }
            .onEnded { value in
                if value.translation.height > 110 || (value.velocity.height > 700 && value.translation.height > 16) {
                    close(nil)
                } else {
                    withAnimation(.spring(duration: 0.4, bounce: 0.25)) { dragY = 0 }
                }
            }
    }
}

// MARK: - Pieces the cards share

/// The add card's sentence styling
enum CardText {
    static let connector = Color(hex: "a3a1a3")
    static let word = Color(hex: "1a1a1a")
    static let label = Color(hex: "8a888a")
    static let fill = Color(hex: "F2F2F4")
    static var connectorFont: Font { .allo(26, weight: .medium) }
    static var wordFont: Font { .allo(26, weight: .semibold) }
}

/// −/+ pill, borrowed from GO
struct StepperPill: View {
    let canDecrease: Bool
    let canIncrease: Bool
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            button("minus", step: -1, enabled: canDecrease)
            Rectangle().fill(Color.black.opacity(0.08)).frame(width: 1)
            button("plus", step: 1, enabled: canIncrease)
        }
        .frame(height: 40)
        .background(Capsule().fill(CardText.fill))
        .clipShape(Capsule())
    }

    private func button(_ icon: String, step: Int, enabled: Bool) -> some View {
        Button {
            HapticManager.shared.selection()
            onChange(step)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CardText.word.opacity(enabled ? 1 : 0.25))
                .frame(width: 46, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
        .accessibilityLabel(step < 0 ? "Earlier" : "Later")
    }
}

/// A wide pill that has to be held: a darker copy wipes across under the
/// finger, slow and linear while deciding, snapping back fast on release
struct HoldToConfirmButton: View {
    let title: String
    var holdingTitle = "Keep holding…"
    var color: Color = .primaryGreen
    var duration: Double = 1.2
    let onConfirm: () -> Void

    @State private var progress: CGFloat = 0
    @State private var ticks: Task<Void, Never>?
    @State private var done = false

    var body: some View {
        ZStack {
            Capsule().fill(color)
            Text(title)
                .font(.allo(16, weight: .semibold))
                .foregroundStyle(.white)
            // The filled copy, revealed from the leading edge
            ZStack {
                Capsule().fill(color.mix(with: .black, by: 0.32))
                Text(holdingTitle)
                    .font(.allo(16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .mask(alignment: .leading) {
                GeometryReader { proxy in
                    Rectangle().frame(width: proxy.size.width * progress)
                }
            }
        }
        .frame(height: 52)
        .scaleEffect(progress > 0 && !done ? 0.975 : 1)
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: duration, maximumDistance: 60) {
            done = true
            ticks?.cancel()
            HapticManager.shared.success()
            onConfirm()
        } onPressingChanged: { pressing in
            guard !done else { return }
            if pressing {
                withAnimation(.linear(duration: duration)) { progress = 1 }
                ticks?.cancel()
                ticks = Task { @MainActor in
                    // A ramp: taps start soft and far apart, then come faster
                    // and harder until the fill reaches the end
                    let haptic = UIImpactFeedbackGenerator(style: .rigid)
                    haptic.prepare()
                    let start = Date()
                    try? await Task.sleep(for: .seconds(0.06))
                    while !Task.isCancelled {
                        let p = min(1, Date().timeIntervalSince(start) / duration)
                        if p >= 0.98 { return }
                        haptic.impactOccurred(intensity: 0.2 + 0.8 * p * p)
                        // From 140ms between taps down to 35ms
                        try? await Task.sleep(for: .seconds(0.14 - 0.105 * p))
                    }
                }
            } else {
                ticks?.cancel()
                withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.22)) { progress = 0 }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onConfirm() }
    }
}

/// Grey secondary pill, next to a primary one
struct GhostPillButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.allo(16, weight: .semibold))
                .foregroundStyle(CardText.word)
                .padding(.horizontal, 22)
                .frame(height: 52)
                .background(Capsule().fill(CardText.fill))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

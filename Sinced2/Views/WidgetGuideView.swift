//
//  WidgetGuideView.swift
//  Sinced2
//
//  Shows how to add the Sinced widget, with a small phone that acts out
//  each step using the person's own event
//

import SwiftUI

// MARK: - Places a widget can go

enum WidgetGuidePlace: String, CaseIterable, Identifiable {
    case homeScreen = "Home Screen"
    case lockScreen = "Lock Screen"

    var id: String { rawValue }

    var steps: [String] {
        switch self {
        case .homeScreen:
            return [
                "Touch and hold an empty spot on your Home Screen until the apps jiggle.",
                "Tap Edit in the top corner, then Add Widget.",
                "Search for Sinced, pick a size, and tap Add Widget."
            ]
        case .lockScreen:
            return [
                "Touch and hold your Lock Screen, then tap Customize.",
                "Choose Lock Screen and tap the box under the clock.",
                "Pick Sinced, then tap Done."
            ]
        }
    }

    var tip: String {
        switch self {
        case .homeScreen:
            return "To choose which event it shows, touch and hold the widget and tap Edit Widget."
        case .lockScreen:
            return "Tap the widget while customizing to choose which event it shows."
        }
    }
}

// MARK: - Guide

struct WidgetGuideView: View {
    /// The event the little phone shows. A sample stands in when there are none.
    let event: SinceEvent

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var place: WidgetGuidePlace = .homeScreen
    @State private var step = 0
    /// Bumped to restart the auto-advance timer and the progress ring
    @State private var cycle = 0

    private static let stepDuration: TimeInterval = 3.2
    private static let lastStepDuration: TimeInterval = 4.4

    init(event: SinceEvent?) {
        self.event = event ?? SinceEvent(
            title: "I started",
            startedAt: Date().addingTimeInterval(-12 * 86400 - 3600),
            cardTheme: .mosaic
        )
    }

    private func duration(for index: Int) -> TimeInterval {
        index == place.steps.count - 1 ? Self.lastStepDuration : Self.stepDuration
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Keep it in sight")
                        .font(.roundedTitle2)
                        .multilineTextAlignment(.center)

                    Text("Add the widget and see your count without opening the app.")
                        .font(.roundedBody)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)

                Picker("Where", selection: $place) {
                    ForEach(WidgetGuidePlace.allCases) { place in
                        Text(place.rawValue).tag(place)
                    }
                }
                .pickerStyle(.segmented)

                WidgetGuideStage(place: place, step: step, event: event)

                VStack(spacing: 2) {
                    ForEach(Array(place.steps.enumerated()), id: \.offset) { index, text in
                        stepRow(index: index, text: text)
                    }
                }

                Text(place.tip)
                    .font(.roundedCaption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            // Clear of the fade behind Got it, so the tip is readable without scrolling
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            Button("Got it") {
                HapticManager.shared.light()
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(
                // Steps scroll out from under the button instead of being cut off
                LinearGradient(
                    colors: [Color(UIColor.systemBackground).opacity(0), Color(UIColor.systemBackground)],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.35)
                )
                .ignoresSafeArea()
            )
        }
        .grainBackground()
        .onChange(of: place) {
            withAnimation(.easeOut(duration: 0.25)) { step = 0 }
            cycle += 1
        }
        // Walk through the steps on a loop. Reduce Motion leaves it to taps.
        .task(id: cycle) {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(duration(for: step)))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    step = (step + 1) % place.steps.count
                }
            }
        }
    }

    private func stepRow(index: Int, text: String) -> some View {
        let isActive = index == step
        return Button {
            guard !isActive else { return }
            HapticManager.shared.selection()
            withAnimation(.easeOut(duration: 0.25)) { step = index }
            cycle += 1
        } label: {
            HStack(alignment: .top, spacing: 14) {
                StepBadge(
                    number: index + 1,
                    isActive: isActive,
                    // The ring shows how long until the next step plays
                    ringDuration: reduceMotion ? nil : duration(for: index)
                )
                .id("\(index)-\(isActive ? cycle : -1)")

                Text(text)
                    .font(.roundedBody)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 3)
                    .opacity(isActive ? 1 : 0.45)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(index + 1) of \(place.steps.count). \(text)")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

/// Numbered circle for a step, with a ring that fills while the step plays
private struct StepBadge: View {
    let number: Int
    let isActive: Bool
    let ringDuration: TimeInterval?

    @State private var progress: CGFloat = 0

    var body: some View {
        Text("\(number)")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(isActive ? .white : .secondary)
            .frame(width: 26, height: 26)
            .background(
                Circle().fill(isActive ? Color.primaryGreen : Color.black.opacity(0.06))
            )
            .padding(4)
            .overlay {
                if isActive, let ringDuration {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.primaryGreen.opacity(0.45), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(1)
                        .onAppear {
                            // Constant motion, so linear
                            withAnimation(.linear(duration: ringDuration)) { progress = 1 }
                        }
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - The little phone

private struct WidgetGuideStage: View {
    let place: WidgetGuidePlace
    let step: Int
    let event: SinceEvent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let height: CGFloat = 264
    private static let screenWidth: CGFloat = 200
    private static let bezel: CGFloat = 6

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.045)
            GrainOverlay()

            // Taller than the stage on purpose: the stage crops it mid-screen
            phone
                .offset(y: 24)
        }
        // Pinned to the top so the phone is cut off at the bottom, not the top
        .frame(maxWidth: .infinity)
        .frame(height: Self.height, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityHidden(true)
    }

    private var phone: some View {
        ZStack(alignment: .top) {
            screen
                .frame(width: Self.screenWidth, height: 420, alignment: .top)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .padding(Self.bezel)
                .background(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(Color(hex: "1A1A1C"))
                )
                .shadow(color: .black.opacity(0.22), radius: 22, y: 14)
        }
    }

    private var screen: some View {
        let isHome = place == .homeScreen
        return ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(hex: "3F7D50"), Color(hex: "1F3F29")],
                startPoint: .top,
                endPoint: .bottom
            )

            // Crossfade with a touch of blur so it reads as one screen changing
            GuideHomeScreen(step: step, event: event, isShowing: isHome)
                .opacity(isHome ? 1 : 0)
                .blur(radius: isHome || reduceMotion ? 0 : 4)

            GuideLockScreen(step: step, event: event, isShowing: !isHome)
                .opacity(isHome ? 0 : 1)
                .blur(radius: !isHome || reduceMotion ? 0 : 4)

            // Dynamic Island
            Capsule()
                .fill(.black)
                .frame(width: 58, height: 17)
                .frame(maxWidth: .infinity)
                .padding(.top, 9)

            GuideTouch(point: touchPoint, isVisible: step < 2)
        }
        .animation(.easeInOut(duration: 0.3), value: place)
    }

    /// Where the finger is for each step, in screen points
    private var touchPoint: CGPoint {
        switch (place, step) {
        case (.homeScreen, 0): return CGPoint(x: 143, y: 205)
        case (.homeScreen, _): return CGPoint(x: 72, y: 71)
        case (.lockScreen, 0): return CGPoint(x: 100, y: 166)
        case (.lockScreen, _): return CGPoint(x: 100, y: 133)
        }
    }
}

/// A fingertip that presses where the step says to
private struct GuideTouch: View {
    let point: CGPoint
    let isVisible: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if !reduceMotion {
                Circle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                    .phaseAnimator([false, true]) { ring, expanded in
                        ring
                            .scaleEffect(expanded ? 1.9 : 1)
                            .opacity(expanded ? 0 : 0.9)
                    } animation: { expanded in
                        // Ripple out, then snap back unseen
                        expanded ? .easeOut(duration: 1.1) : .linear(duration: 0.01)
                    }
            }

            Circle()
                .fill(Color.white.opacity(0.55))
                .overlay(Circle().stroke(Color.white.opacity(0.95), lineWidth: 1))
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        }
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .position(point)
        // Moving across the screen eases both ways; leaving is quicker than arriving
        .animation(.easeInOut(duration: 0.45), value: point)
        .animation(.easeOut(duration: isVisible ? 0.25 : 0.15), value: isVisible)
        .allowsHitTesting(false)
    }
}

// MARK: Home Screen

private struct GuideHomeScreen: View {
    let step: Int
    let event: SinceEvent
    let isShowing: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let icon: CGFloat = 31
    private let gap: CGFloat = 12

    private var isEditing: Bool { step < 2 }
    private var isJiggling: Bool { isShowing && isEditing && !reduceMotion }
    private var showsMenu: Bool { step == 1 }
    private var widgetPlaced: Bool { step == 2 }
    private var block: CGFloat { icon * 2 + gap }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Edit and Done appear while the Home Screen is being edited
            HStack {
                pill("Edit", highlighted: showsMenu)
                Spacer()
                pill("Done", highlighted: false)
            }
            .padding(.horizontal, 14)
            .padding(.top, 34)
            .opacity(isEditing ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: isEditing)

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isJiggling)) { context in
                grid(time: context.date.timeIntervalSinceReferenceDate)
            }
            .padding(.horizontal, 14)
            .padding(.top, 60)

            addWidgetMenu
                .padding(.leading, 14)
                .padding(.top, 55)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func grid(time: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: gap) {
            HStack(alignment: .top, spacing: gap) {
                // The widget lands where four apps were
                ZStack {
                    iconGrid(rows: 2, columns: 2, firstIndex: 0, time: time)
                        .scaleEffect(widgetPlaced && !reduceMotion ? 0.9 : 1)
                        .opacity(widgetPlaced ? 0 : 1)
                        .animation(.easeOut(duration: 0.16), value: widgetPlaced)

                    widget
                }
                .frame(width: block, height: block)

                iconGrid(rows: 2, columns: 2, firstIndex: 4, time: time)
            }

            iconGrid(rows: 1, columns: 4, firstIndex: 8, time: time)
            iconGrid(rows: 1, columns: 2, firstIndex: 12, time: time)
        }
    }

    private var widget: some View {
        // Their real card, drawn at full size and scaled so the type stays in proportion
        HomeEventCardView(event: event)
            .frame(width: block * 2, height: block * 2)
            .scaleEffect(0.5)
            .frame(width: block, height: block)
            .shadow(color: .black.opacity(0.28), radius: 8, y: 5)
            // Never from nothing: starts just under full size
            .scaleEffect(widgetPlaced || reduceMotion ? 1 : 0.86)
            .opacity(widgetPlaced ? 1 : 0)
            .animation(
                widgetPlaced
                    ? .spring(duration: 0.5, bounce: 0.28).delay(0.08)
                    : .easeOut(duration: 0.15),
                value: widgetPlaced
            )
    }

    private func iconGrid(rows: Int, columns: Int, firstIndex: Int, time: TimeInterval) -> some View {
        VStack(spacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(0..<columns, id: \.self) { column in
                        appIcon(index: firstIndex + row * columns + column, time: time)
                    }
                }
            }
        }
    }

    private func appIcon(index: Int, time: TimeInterval) -> some View {
        // Each app wobbles slightly out of step with its neighbours, like the real thing
        let phase = Double(index) * 1.7
        let speed = 2 * Double.pi / (0.26 + Double(index % 3) * 0.02)
        let angle = isJiggling ? sin(time * speed + phase) * 2.6 : 0

        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.white.opacity(0.16 + Double((index * 5) % 4) * 0.045))
            .frame(width: icon, height: icon)
            .rotationEffect(.degrees(angle))
            // Only settles when jiggling stops; each frame of the wobble is set directly
            .animation(.easeOut(duration: 0.2), value: isJiggling)
    }

    private func pill(_ title: String, highlighted: Bool) -> some View {
        Text(title)
            .font(.system(size: 8.5, weight: .semibold))
            .foregroundColor(highlighted ? .black : .white)
            .padding(.horizontal, 8)
            .frame(height: 16)
            .background(Capsule().fill(Color.white.opacity(highlighted ? 1 : 0.24)))
            .animation(.easeOut(duration: 0.2), value: highlighted)
    }

    private var addWidgetMenu: some View {
        HStack(spacing: 5) {
            Image(systemName: "plus.square.on.square")
                .font(.system(size: 8, weight: .semibold))
            Text("Add Widget")
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 9)
        .frame(height: 27)
        .frame(width: 98, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.white.opacity(0.96))
        )
        .shadow(color: .black.opacity(0.22), radius: 10, y: 5)
        // Opens out of the Edit button it belongs to
        .scaleEffect(showsMenu || reduceMotion ? 1 : 0.9, anchor: .topLeading)
        .opacity(showsMenu ? 1 : 0)
        .animation(.easeOut(duration: showsMenu ? 0.22 : 0.14).delay(showsMenu ? 0.2 : 0), value: showsMenu)
    }
}

// MARK: Lock Screen

private struct GuideLockScreen: View {
    let step: Int
    let event: SinceEvent
    let isShowing: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showsCustomize: Bool { step == 0 }
    private var showsEmptySlot: Bool { step == 1 }
    private var widgetPlaced: Bool { step == 2 }

    private var dayCount: String {
        let days = Int(max(0, Date().timeIntervalSince(event.startedAt)) / 86400)
        return "\(days) \(days == 1 ? "DAY" : "DAYS")"
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(Date.now, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 38)

            Text("9:41")
                .font(.system(size: 50, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, -3)

            slot
                .padding(.top, 2)

            Text("Customize")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .frame(height: 22)
                .background(Capsule().fill(Color.white.opacity(0.24)))
                .padding(.top, 44)
                .scaleEffect(showsCustomize || reduceMotion ? 1 : 0.95)
                .opacity(showsCustomize ? 1 : 0)
                // Arrives a beat after the press that summons it
                .animation(
                    .easeOut(duration: showsCustomize ? 0.25 : 0.14).delay(showsCustomize && isShowing ? 0.55 : 0),
                    value: showsCustomize
                )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var slot: some View {
        ZStack {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 8, weight: .bold))
                Text("Add Widgets")
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.85))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            )
            .opacity(showsEmptySlot ? 1 : 0)
            .animation(.easeOut(duration: showsEmptySlot ? 0.22 : 0.14), value: showsEmptySlot)

            VStack(alignment: .leading, spacing: 1) {
                Text(dayCount)
                    .font(.custom("GeistMono-Medium", size: 12))
                    .tracking(-0.3)
                    .foregroundColor(.white)
                Text("Since \(event.title)")
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.2))
            )
            .scaleEffect(widgetPlaced || reduceMotion ? 1 : 0.9)
            .opacity(widgetPlaced ? 1 : 0)
            .animation(
                widgetPlaced
                    ? .spring(duration: 0.5, bounce: 0.28).delay(0.08)
                    : .easeOut(duration: 0.15),
                value: widgetPlaced
            )
        }
        .frame(width: 150, height: 40)
    }
}

// MARK: - Home card

/// Sits above the events on the home screen until a widget is added or it's dismissed
struct WidgetGuideCard: View {
    let event: SinceEvent
    let onOpen: () -> Void
    let onDismiss: () -> Void

    private let thumbnail: CGFloat = 52

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                HomeEventCardView(event: event)
                    .frame(width: 148, height: 148)
                    .scaleEffect(thumbnail / 148)
                    .frame(width: thumbnail, height: thumbnail)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Add it to your Home Screen")
                        .font(.roundedHeadline)
                        .foregroundColor(.primary)

                    Text("See your count at a glance")
                        .font(.roundedSubheadline)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(14)
            // Room for the dismiss button
            .padding(.trailing, 26)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint("Shows how to add the widget")
        .overlay(alignment: .topTrailing) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.black.opacity(0.05)))
                    // Small glyph, full-size target
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Dismiss")
        }
    }
}

#Preview {
    WidgetGuideView(event: nil)
}

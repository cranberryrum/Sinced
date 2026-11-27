//
//  WidgetNudgeCard.swift
//  Sinced2
//
//  Sits above the counters on Home until a widget is added or it's put away.
//  A little Home Screen with an empty widget spot: right after the first
//  counter is made, that counter flies into the spot (Home plays the flight).
//  "Show me how" opens the card in place into the three steps, acted out on
//  the guide's little phone, so nobody has to leave Home.
//

import SwiftUI

struct WidgetNudgeCard: View {
    let event: SinceEvent
    /// Whether the counter sits in the preview's widget spot. Off while it flies in.
    let widgetPlaced: Bool
    /// Tapping the preview plays the flight again
    let onReplay: () -> Void
    /// Where the widget spot is, in Home's coordinate space, for the flight
    let onSlotFrame: (CGRect) -> Void
    let onLockScreen: () -> Void
    let onDismiss: () -> Void

    @State private var expanded = false
    @State private var step = 0
    /// Bumped to restart the auto-advance and the progress bar
    @State private var cycle = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let steps = WidgetGuidePlace.homeScreen.steps
    private static func duration(for step: Int) -> TimeInterval { step == steps.count - 1 ? 4.4 : 3.2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if expanded {
                    walkthrough
                        .transition(.opacity)
                } else {
                    window
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 16)

            title
                .padding(.horizontal, 6)
                .padding(.bottom, 16)

            buttons
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
        .overlay(alignment: .topTrailing) { closeButton }
        // Folding open and shut
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0), value: expanded)
        // Walk through the steps on a loop while open. Reduce Motion leaves it to taps.
        .task(id: expanded ? cycle : -1) {
            guard expanded, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.duration(for: step)))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.25)) { step = (step + 1) % Self.steps.count }
                cycle += 1
                return
            }
        }
    }

    // MARK: - Pieces

    private var title: some View {
        let word = { (s: String) in Text(s).foregroundColor(CardText.word).fontWeight(.semibold) }
        let line = expanded
            ? Text("Add ") + word(event.title) + Text(" to your Home Screen")
            : Text("Keep ") + word(event.title) + Text(" in sight")
        return VStack(alignment: .leading, spacing: 4) {
            line
                .font(.allo(19, weight: .medium))
                .foregroundStyle(CardText.connector)
                .contentTransition(.opacity)
            if expanded {
                Text(Self.steps[step])
                    .font(.allo(15))
                    .foregroundStyle(CardText.label)
                    .contentTransition(.opacity)
                    .id(step)
                    .transition(.opacity)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Prefer the Lock Screen?", action: onLockScreen)
                    .font(.allo(14, weight: .medium))
                    .foregroundStyle(CardText.word)
                    .underline()
                    .buttonStyle(.plain)
                    .padding(.top, 4)
            } else {
                Text("Add it to your Home Screen and see the count without opening Sinced.")
                    .font(.allo(15))
                    .foregroundStyle(CardText.label)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.2), value: step)
    }

    private var buttons: some View {
        HStack(spacing: 8) {
            Button(expanded ? "Not now" : "Later") {
                HapticManager.shared.light()
                if expanded { expanded = false } else { onDismiss() }
            }
            .buttonStyle(NudgeButtonStyle(primary: false))

            Button(expanded ? "Got it" : "Show me how") {
                HapticManager.shared.light()
                if !expanded {
                    step = 0
                    cycle += 1
                }
                expanded.toggle()
            }
            .buttonStyle(NudgeButtonStyle(primary: true))
        }
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.black.opacity(0.22)))
                // Small glyph, full-size target
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .padding(14)
        .accessibilityLabel("Dismiss")
    }

    /// A little Home Screen with an empty spot for the widget
    private var window: some View {
        let icon: CGFloat = 34, gap: CGFloat = 12
        let slot = icon * 2 + gap
        return HStack(alignment: .top, spacing: gap) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                // Their real card, drawn at full size and scaled so the type stays in proportion
                HomeEventCardView(event: event)
                    .frame(width: 176, height: 176)
                    .scaleEffect(slot / 176)
                    .frame(width: slot, height: slot)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
                    .scaleEffect(widgetPlaced || reduceMotion ? 1 : 0.96)
                    .opacity(widgetPlaced ? 1 : 0)
                    .animation(.easeOut(duration: widgetPlaced ? 0.25 : 0.01), value: widgetPlaced)
            }
            .frame(width: slot, height: slot)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(HomeSpace.name)) } action: { onSlotFrame($0) }

            VStack(spacing: gap) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<4, id: \.self) { column in
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.white.opacity(0.16 + Double((row * 4 + column) * 5 % 4) * 0.045))
                                .frame(width: icon, height: icon)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(wallpaper)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture(perform: onReplay)
        .accessibilityHidden(true)
    }

    /// The three steps acted out on the guide's little phone, with story-style progress
    private var walkthrough: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(0..<Self.steps.count, id: \.self) { index in
                    StepProgress(
                        state: index < step ? .done : index == step ? .playing : .waiting,
                        duration: reduceMotion ? nil : Self.duration(for: index)
                    )
                    .id("\(index)-\(index == step ? cycle : -1)")
                }
            }
            WidgetGuideStage(place: .homeScreen, step: step, event: event, height: 196)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.shared.selection()
                    withAnimation(.easeOut(duration: 0.25)) { step = (step + 1) % Self.steps.count }
                    cycle += 1
                }
        }
    }

    private var wallpaper: some View {
        LinearGradient(colors: [Color(hex: "3F7D50"), Color(hex: "1F3F29")], startPoint: .top, endPoint: .bottom)
    }
}

/// Home's coordinate space, shared by the counter cards, the nudge's widget spot and the flight
enum HomeSpace {
    static let name = "home"
}

/// One bar of the walkthrough's progress, filling while its step plays
private struct StepProgress: View {
    enum State { case done, playing, waiting }
    let state: State
    let duration: TimeInterval?

    @SwiftUI.State private var fill: CGFloat = 0

    var body: some View {
        Capsule()
            .fill(CardText.fill)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(CardText.word)
                    .scaleEffect(x: state == .done ? 1 : fill, anchor: .leading)
            }
            .frame(height: 3)
            .onAppear {
                guard state == .playing else { return }
                if let duration {
                    // Time passing, so linear
                    withAnimation(.linear(duration: duration)) { fill = 1 }
                } else {
                    fill = 1
                }
            }
            .accessibilityHidden(true)
    }
}

private struct NudgeButtonStyle: ButtonStyle {
    let primary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.allo(15.5, weight: .semibold))
            .foregroundStyle(primary ? Color.white : CardText.word)
            .padding(.horizontal, primary ? 0 : 20)
            .frame(maxWidth: primary ? .infinity : nil)
            .frame(height: 46)
            .background(Capsule().fill(primary ? CardText.word : CardText.fill))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

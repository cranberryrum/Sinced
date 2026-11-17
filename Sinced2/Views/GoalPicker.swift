//
//  GoalPicker.swift
//  Sinced2
//
//  The goal row in the add and edit sheet. It looks like the "Started on"
//  row above it: a label and a white pill. Tapping the pill slides a ruler
//  open underneath, with no box around it; the pill itself shows the value
//  while you drag.
//

import SwiftUI

struct GoalPicker: View {
    /// 0 means no goal
    @Binding var goal: Int
    @Binding var isOpen: Bool
    /// When the current run started, for "lands on" and stops already passed
    let startDate: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var daysSoFar: Int {
        Int(max(0, Date().timeIntervalSince(startDate)) / 86400)
    }

    private var summary: String {
        goal == 0 ? "None" : Milestones.label(goal)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text("Goal")
                    .font(.allo(16))
                    .foregroundColor(AddEventBottomSheet.labelColor)

                Spacer()

                Button {
                    HapticManager.shared.light()
                    withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0)) {
                        isOpen.toggle()
                    }
                } label: {
                    Text(summary)
                        .font(.allo(15))
                        .foregroundColor(goal == 0 && !isOpen ? AddEventBottomSheet.labelColor : Color(hex: "1a1a1a"))
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.16), value: goal)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(Capsule().fill(AddEventBottomSheet.fieldFill))
                        // Open: an accent outline marks the pill the ruler belongs to
                        .overlay(
                            Capsule().strokeBorder(
                                isOpen ? Color.primaryGreen : Color.black.opacity(0.08),
                                lineWidth: isOpen ? 1.5 : 1
                            )
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Goal")
                .accessibilityValue(summary)
                .accessibilityHint(isOpen ? "Closes the goal picker" : "Opens the goal picker")
            }

            if isOpen {
                GoalRuler(goal: $goal, daysSoFar: daysSoFar, startDate: startDate)
                    // Unfolds from the row above it
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .offset(y: -6))
                    )
            }
        }
    }
}

/// A borderless snapping scale with a fixed needle, and one caption under it
private struct GoalRuler: View {
    @Binding var goal: Int
    let daysSoFar: Int
    let startDate: Date

    @State private var centered: Int?
    private static let stopWidth: CGFloat = 52

    private var stops: [Int] { Milestones.goalStops }

    /// Stops already behind the current run can't be a goal
    private func isAllowed(_ stop: Int) -> Bool { stop == 0 || stop > daysSoFar }

    private var caption: String {
        guard goal > 0 else { return "No goal · milestones still celebrate" }
        let date = Calendar.current.date(byAdding: .day, value: goal, to: startDate) ?? startDate
        let left = goal - daysSoFar
        return "Lands on \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) · \(left) to go"
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(stops, id: \.self) { stop in
                            stopView(stop)
                                .frame(width: Self.stopWidth)
                                .id(stop)
                        }
                    }
                    .scrollTargetLayout()
                }
                // Native momentum, then lands exactly on a stop
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $centered, anchor: .center)
                .contentMargins(.horizontal, (proxy.size.width - Self.stopWidth) / 2, for: .scrollContent)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.primaryGreen)
                        .frame(width: 3, height: 22)
                        .allowsHitTesting(false)
                }
                // The ends fade into the sheet instead of being cut off
                .mask(
                    LinearGradient(
                        stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.2),
                                .init(color: .black, location: 0.8), .init(color: .clear, location: 1)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
            }
            .frame(height: 42)
            // A tick on the finger at each stop, like a physical dial
            .sensoryFeedback(.selection, trigger: centered)

            Text(caption)
                .font(.allo(12))
                .foregroundColor(AddEventBottomSheet.labelColor)
                .contentTransition(.opacity)
                .animation(.easeOut(duration: 0.16), value: caption)
                .accessibilityHidden(true)
        }
        .onAppear {
            // Opens on the current goal, or the first useful stop
            centered = goal > 0 ? goal : (stops.first { $0 > daysSoFar && $0 >= 30 } ?? 0)
            if goal == 0, let start = centered { goal = start }
        }
        .onChange(of: centered) { _, stop in
            guard let stop else { return }
            if isAllowed(stop) {
                goal = stop
            } else {
                // Landed on a stop already passed: move on to the next useful one
                let next = stops.first { $0 > daysSoFar } ?? 0
                withAnimation(.spring(duration: 0.3, bounce: 0)) { centered = next }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Goal")
        .accessibilityValue(goal == 0 ? "None" : "\(Milestones.label(goal)). \(caption)")
        .accessibilityAdjustableAction { direction in
            let allowed = stops.filter(isAllowed)
            guard let index = allowed.firstIndex(of: goal) else { return }
            let next = direction == .increment ? min(index + 1, allowed.count - 1) : max(index - 1, 0)
            withAnimation { centered = allowed[next] }
        }
    }

    private func stopView(_ stop: Int) -> some View {
        let isCurrent = stop == goal
        return VStack(spacing: 6) {
            Capsule()
                .fill(Color(hex: "BDBDC2"))
                .frame(width: 2, height: 14)
            Text(stop == 0 ? "None" : stop == 365 ? "1y" : stop == 730 ? "2y" : "\(stop)")
                .font(.allo(11, weight: .medium).monospacedDigit())
                .foregroundColor(isCurrent ? Color(hex: "1a1a1a") : Color(hex: "9A9AA0"))
                .animation(.easeOut(duration: 0.16), value: isCurrent)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        // Minor ticks between stops, for the feel of a scale
        .overlay(alignment: .topTrailing) {
            if stop != stops.last {
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(Color(hex: "D6D6DA")).frame(width: 1.5, height: 7)
                    }
                }
                .offset(x: 13, y: 4)
            }
        }
        .opacity(isAllowed(stop) ? 1 : 0.3)
    }
}

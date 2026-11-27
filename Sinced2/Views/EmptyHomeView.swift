//
//  EmptyHomeView.swift
//  Sinced2
//
//  Home with nothing added yet. A counter is already running, "since you
//  joined Sinced", ticking (and tapping) every second, so someone sees what a
//  counter is before being asked for one. Ideas below start the add card with
//  that name filled in.
//

import SwiftUI

struct EmptyHomeView: View {
    @ObservedObject var addFlow: AddFlow

    /// When this person first saw an empty home, which for a new install is
    /// right after onboarding
    @AppStorage("home.joinedAt") private var joinedAt: Double = 0
    @State private var ideas = NameIdeas.pick(5, avoiding: [])
    @State private var frames: [String: CGRect] = [:]
    @State private var tapped: String?
    @State private var appeared = false

    private static let somethingElse = "Something else"

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                LiveCounterCard(since: Date(timeIntervalSince1970: joinedAt))
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.96)

                (Text("That’s a counter. ").foregroundColor(Color(hex: "a3a1a3"))
                 + Text("What do you want to count?").foregroundColor(Color(hex: "1a1a1a")).fontWeight(.semibold))
                    .font(.allo(25, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.top, 26)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                WrapLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(ideas + [Self.somethingElse], id: \.self) { idea in
                        chip(idea)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .onAppear {
            if joinedAt == 0 { joinedAt = Date().timeIntervalSince1970 }
            withAnimation(.spring(duration: 0.55, bounce: 0.12).delay(0.1)) { appeared = true }
        }
        .onChange(of: addFlow.isPresented) { _, open in
            if !open { tapped = nil }
        }
    }

    private func chip(_ idea: String) -> some View {
        let other = idea == Self.somethingElse
        return Button {
            HapticManager.shared.light()
            tapped = idea
            if let frame = frames[idea] { addFlow.sourceFrame = frame }
            addFlow.present(name: other ? nil : idea)
        } label: {
            Text(idea)
                .font(.allo(15, weight: .medium))
                .foregroundStyle(other ? Color.white : Color(hex: "1a1a1a"))
                .padding(.horizontal, 15)
                .frame(height: 38)
                .background(Capsule().fill(other ? Color(hex: "1a1a1a") : Color.white))
                .overlay(Capsule().strokeBorder(Color.black.opacity(other ? 0 : 0.06), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
        // The add card grows out of the chip that was tapped
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames[idea] = $0 }
        .opacity(addFlow.hidesSource && tapped == idea ? 0 : 1)
    }
}

/// A themed card counting up from `since`: seconds, then minutes, hours and
/// days. Each time the number changes there's a light tap, so the first
/// minute feels alive and later ones stay quiet.
private struct LiveCounterCard: View {
    let since: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let reading = Self.reading(max(0, context.date.timeIntervalSince(since)))
            ZStack {
                CardTheme.waves.backgroundColor
                if let asset = CardTheme.waves.svgAssetName {
                    Image(asset).resizable().scaledToFill()
                }
                VStack(spacing: 6) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(reading.value)")
                            .font(.allo(72, weight: .semibold))
                            .contentTransition(.numericText(value: Double(reading.value)))
                        Text(reading.unit)
                            .font(.allo(26, weight: .semibold))
                            .contentTransition(.opacity)
                    }
                    .animation(.spring(duration: 0.45, bounce: 0.15), value: reading.value)
                    Text("Since you joined Sinced")
                        .font(.allo(15, weight: .medium))
                        .opacity(0.8)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 2)
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.55), trigger: reading.value)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(reading.value) \(reading.spoken) since you joined Sinced")
        }
    }

    private static func reading(_ t: TimeInterval) -> (value: Int, unit: String, spoken: String) {
        let s = Int(t)
        if s < 60 { return (s, "s", s == 1 ? "second" : "seconds") }
        if s < 3600 { return (s / 60, "m", s / 60 == 1 ? "minute" : "minutes") }
        if s < 86400 { return (s / 3600, "h", s / 3600 == 1 ? "hour" : "hours") }
        return (s / 86400, "d", s / 86400 == 1 ? "day" : "days")
    }
}

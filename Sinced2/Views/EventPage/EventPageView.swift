//
//  EventPageView.swift
//  Sinced2
//
//  One event, opened from its card on home (the card zooms into this page).
//  The event's own card leads, with one big number that rolls when it
//  changes; the goal meter sits under it; a sentence says what the numbers
//  mean; every run is a bar you can drag across. Reset, reminders and delete
//  open the add card's floating card.
//

import SwiftUI
import Combine

struct EventPageView: View {
    let event: SinceEvent
    @ObservedObject var viewModel: EventViewModel
    var onDeleteSuccess: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var localEvent: SinceEvent
    @State private var now = Date()
    /// Numbers start at zero and roll up as the page arrives
    @State private var arrived = false
    /// The run being dragged over in the chart, newest last; nil for the live one
    /// The reset picked on the calendar; the big number reads the run it ended
    @State private var selectedReset: UUID?
    @State private var scrollY: CGFloat = 0
    @State private var showingShare = false

    @StateObject private var editFlow = AddFlow()
    @State private var card: PageCard?
    @State private var cardSource: CGRect = .zero
    @State private var frames: [String: CGRect] = [:]

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    enum PageCard: Identifiable {
        case reset, reminders, delete
        var id: Self { self }
    }

    init(event: SinceEvent, viewModel: EventViewModel, onDeleteSuccess: ((String) -> Void)? = nil) {
        self.event = event
        self.viewModel = viewModel
        self.onDeleteSuccess = onDeleteSuccess
        _localEvent = State(initialValue: event)
    }

    // MARK: Numbers

    private var unit: WidgetTimeUnit { localEvent.widgetTimeUnit }
    private var runLength: TimeInterval { max(0, now.timeIntervalSince(localEvent.startedAt)) }
    private var days: Int { Int(runLength / 86400) }

    static func value(_ seconds: TimeInterval, in unit: WidgetTimeUnit) -> Int {
        switch unit {
        case .hours: return Int(seconds / 3600)
        case .days: return Int(seconds / 86400)
        case .months: return Int(seconds / (86400 * 30))
        case .years: return Int(seconds / (86400 * 365))
        }
    }

    static func word(_ unit: WidgetTimeUnit, _ n: Int) -> String {
        let w = unit.rawValue.lowercased().dropLast()
        return n == 1 ? String(w) : String(w) + "s"
    }

    private var shownRun: EventRun? {
        selectedReset.flatMap { id in localEvent.pastRuns.first { $0.id == id } }
    }

    private var heroValue: Int {
        guard arrived else { return 0 }
        return Self.value(shownRun?.duration(at: now) ?? runLength, in: unit)
    }

    private var bestBefore: TimeInterval { localEvent.pastRuns.map { $0.duration(at: now) }.max() ?? 0 }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    goalRow
                    sentence
                    runsBox
                    actions
                    Color.clear.frame(height: 96)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, y in scrollY = y }

            topNav
        }
        .overlay(alignment: .bottom) { dock }
        .background(GrainBackground().ignoresSafeArea())
        .overlay {
            if let card {
                FloatingCardHost(source: cardSource, sourceRadius: 26, onDismissed: { self.card = nil }) { close in
                    switch card {
                    case .reset: ResetCard(event: localEvent, viewModel: viewModel, close: close, onReset: showResetToast)
                    case .reminders: RemindersCard(event: $localEvent, viewModel: viewModel, close: close)
                    case .delete: DeleteCard(event: localEvent, close: close, onConfirm: finishDelete)
                    }
                }
                .id(card)
            }
        }
        .overlay {
            if editFlow.isPresented {
                AddEventOverlay(viewModel: viewModel, flow: editFlow)
            }
        }
        .sheet(isPresented: $showingShare) { ShareSheetView(event: localEvent) }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 280))
                withAnimation(.spring(duration: 0.9, bounce: 0.08)) { arrived = true }
            }
        }
        .onReceive(timer) { now = $0 }
        .onReceive(viewModel.$events) { events in
            guard let updated = events.first(where: { $0.id == localEvent.id }), updated != localEvent else { return }
            withAnimation(.spring(duration: 0.45, bounce: 0.05)) { localEvent = updated }
        }
        .preferredColorScheme(.light)
    }

    // MARK: Nav

    /// Solid once the card has scrolled away; light and blurred over it
    private var solid: CGFloat { min(1, max(0, (scrollY - 230) / 140)) }

    private var topNav: some View {
        HStack {
            navButton {
                Image(systemName: "arrow.left").font(.system(size: 16, weight: .semibold))
                    .frame(width: 38, height: 38)
            } action: { dismiss() }
            .accessibilityLabel("Back")

            Spacer()
            UnitSwitch(unit: unit, onLight: solid < 0.5) { setUnit($0) }
            Spacer()

            navButton {
                Text("Edit").font(.allo(15, weight: .medium)).padding(.horizontal, 14).frame(height: 38)
            } action: {
                HapticManager.shared.light()
                editFlow.presentEdit(localEvent, from: frames["edit"])
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames["edit"] = $0 }
        }
        .padding(.horizontal, Self.gutter)
        .padding(.bottom, 18)
        .background(alignment: .top) {
            ZStack {
                // Strongest at the top edge, nothing by the bottom, no white haze
                ProgressiveBlur(radius: 16)
                // Once the card has gone, a whisper of the page colour keeps the controls legible
                LinearGradient(colors: [Color(hex: "F3F2F0").opacity(0.7 * solid), .clear], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
        }
        .animation(.easeOut(duration: 0.2), value: solid > 0.5)
    }

    private func navButton<Label: View>(@ViewBuilder label: () -> Label, action: @escaping () -> Void) -> some View {
        let light = solid < 0.5
        return Button(action: action) {
            label()
                .foregroundStyle(light ? Color.white : CardText.word)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassCapsule()
    }

    // MARK: Hero

    private var hero: some View {
        // The pattern is an overlay so its size can never widen the page;
        // the card is exactly as wide as the screen
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 430)
            .overlay { EventThemeBackground(event: localEvent) }
            .overlay { heroCount }
            // Runs to the top of the screen, which supplies its own corners
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40, style: .continuous))
    }

    private var heroCount: some View {
            VStack(spacing: 4) {
                Text(heroValue.formatted())
                    .font(.allo(132, weight: .semibold).monospacedDigit())
                    .tracking(-5)
                    .contentTransition(.numericText(value: Double(heroValue)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                MorphText(text: Self.word(unit, heroValue), font: .allo(23, weight: .medium), color: .white)
                MorphText(
                    text: shownRun.map { "run · \($0.start.sincedShortDate) – \(($0.end ?? now).sincedShortDate)" } ?? "since \(localEvent.title.lowercased())",
                    font: .allo(16, weight: .medium),
                    color: .white.opacity(0.75)
                )
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.16), radius: 14, y: 2)
            .padding(.horizontal, Self.gutter)
            .padding(.top, 64)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(heroValue) \(Self.word(unit, heroValue)) since \(localEvent.title)")
    }

    /// One margin for everything that sits on the page
    static let gutter: CGFloat = 16

    // MARK: Goal meter

    private var goalRow: some View {
        let goal = localEvent.goalDays ?? 0
        let progress = goal > 0 ? min(1, runLength / (Double(goal) * 86400)) : 0
        let lit = arrived ? Int((progress * 28).rounded()) : 0
        let leftSeconds = max(0, Double(goal) * 86400 - runLength)
        let left = arrived ? Self.value(leftSeconds, in: unit) : 0
        let goalValue = arrived ? Self.value(Double(goal) * 86400, in: unit) : 0
        let singular = String(unit.rawValue.lowercased().dropLast())

        return Button {
            HapticManager.shared.light()
            editFlow.presentEdit(localEvent, openGoal: true, from: frames["goal"])
        } label: {
            VStack(spacing: 10) {
                GoalTicks(lit: lit, color: themeColor)

                HStack {
                    if goal == 0 {
                        Text("No goal yet").foregroundStyle(CardText.word)
                        Spacer()
                        Text("Set one").foregroundStyle(CardText.label)
                    } else if leftSeconds <= 0 {
                        Text("Goal reached").foregroundStyle(CardText.word)
                        Spacer()
                        Text("Set the next").foregroundStyle(CardText.label)
                    } else {
                        (Text(left.formatted()) + Text(" \(Self.word(unit, left)) to go"))
                            .foregroundStyle(CardText.word)
                            .contentTransition(.numericText(value: Double(left)))
                        Spacer()
                        (Text(goalValue.formatted()) + Text("-\(singular) goal"))
                            .foregroundStyle(CardText.label)
                            .contentTransition(.numericText(value: Double(goalValue)))
                    }
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold)).foregroundStyle(CardText.label)
                }
                .font(.allo(15, weight: .semibold).monospacedDigit())
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames["goal"] = $0 }
        .padding(.horizontal, Self.gutter)
        .padding(.top, 18)
        .accessibilityLabel(goal == 0 ? "No goal yet. Set one" : "\(Self.value(leftSeconds, in: unit)) \(Self.word(unit, Self.value(leftSeconds, in: unit))) to your \(goal)-day goal")
    }

    private var themeColor: Color {
        localEvent.cardTheme == .custom ? .primaryGreen : localEvent.cardTheme.backgroundColor
    }

    // MARK: Sentence

    private var sentence: some View {
        VStack(alignment: .leading, spacing: 10) {
            line1
                .contentTransition(.opacity)
            Button {
                open(.reminders, from: "remind")
            } label: {
                line2.multilineTextAlignment(.leading)
            }
            .buttonStyle(PressableButtonStyle())
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames["remind"] = $0 }
            .accessibilityHint("Changes reminders")
        }
        .font(.allo(24, weight: .medium))
        .foregroundStyle(CardText.connector)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Self.gutter)
        .padding(.top, 22)
    }

    private func bold(_ s: String) -> Text { Text(s).font(.allo(24, weight: .semibold)).foregroundColor(CardText.word) }

    /// A bold word that can be tapped, dotted underneath like a link
    private func link(_ s: String) -> Text { bold(s).underline(true, pattern: .dot, color: CardText.connector) }

    private var line1: Text {
        let best = bestBefore
        guard localEvent.hasBeenReset else { return Text("Your first run, and ") + bold("going strong") + Text(".") }
        if runLength >= best {
            let past = Int((runLength - best) / 86400)
            return Text("That’s your ") + bold("longest run") + Text(" yet, ") + bold("\(past) \(past == 1 ? "day" : "days")") + Text(" past your old best.")
        }
        // In whole days, the way the counter shows them
        let bestDays = Int(best / 86400)
        let toBeat = max(1, bestDays - days)
        return Text("Your best is ") + bold("\(bestDays) \(bestDays == 1 ? "day" : "days")") + Text(". ") + bold("\(toBeat) \(toBeat == 1 ? "day" : "days")") + Text(" to beat it.")
    }

    private var line2: Text {
        let r = localEvent.reminderSettings
        guard r.isEnabled else { return Text("No reminders. ") + link("Remind me") + Text("?") }
        let when: String
        switch r.reminderType {
        case .daily: when = "every day"
        case .weekly:
            let names = r.weeklyDays.map { Calendar.current.shortWeekdaySymbols[$0.rawValue - 1] }
            when = r.weeklyDays.count == 7 ? "every day" : "on " + names.formatted(.list(type: .and))
        }
        return Text("Remind me ") + link(when) + Text(" at ") + link(r.dailyReminderTime.formatted(date: .omitted, time: .shortened)) + Text(".")
    }

    // MARK: Runs

    private var runsBox: some View {
        RunsCalendarCard(event: localEvent, now: now, tint: themeColor, selected: $selectedReset)
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: 0) {
            actionRow("square.and.arrow.up", "Share the card", color: CardText.word, key: "share") { showingShare = true }
            DashedRule()
            actionRow("trash", "Delete or archive", color: Color(hex: "D8453B"), key: "delete") { open(.delete, from: "delete") }
        }
        .padding(.horizontal, Self.gutter)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
        .padding(.horizontal, Self.gutter)
        .padding(.top, 12)
    }

    private func actionRow(_ icon: String, _ title: String, color: Color, key: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.light()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 17, weight: .medium)).frame(width: 22)
                Text(title).font(.allo(16, weight: .medium))
                Spacer()
            }
            .foregroundStyle(color)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames[key] = $0 }
    }

    // MARK: Dock

    /// Just the action, hugging its words: a small glass capsule above the
    /// home bar with the run's length tucked in beside it
    private var dock: some View {
        Button {
            open(.reset, from: "reset")
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.primaryGreen)
                Text("Reset")
                    .font(.allo(16, weight: .semibold))
                    .foregroundStyle(CardText.word)
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 1.5, height: 18)
                    .padding(.leading, 2)
                (Text("\(arrived ? days : 0)") + Text("d"))
                    .font(.allo(16, weight: .medium).monospacedDigit())
                    .foregroundStyle(CardText.label)
                    .contentTransition(.numericText(value: Double(arrived ? days : 0)))
            }
            .padding(.leading, 16)
            .padding(.trailing, 18)
            .frame(height: 52)
            .glassCapsule()
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames["reset"] = $0 }
        .padding(.bottom, 8)
        .accessibilityLabel("Reset, \(days) days this run")
    }


    // MARK: Actions

    private func open(_ which: PageCard, from key: String) {
        cardSource = frames[key] ?? .zero
        card = which
    }

    private func setUnit(_ new: WidgetTimeUnit) {
        guard new != unit else { return }
        HapticManager.shared.selection()
        withAnimation(.spring(duration: 0.5, bounce: 0.1)) { localEvent.widgetTimeUnit = new }
        viewModel.updateEvent(localEvent)
    }

    private func showResetToast() {
        let updated = viewModel.events.first { $0.id == localEvent.id } ?? localEvent
        let kept = updated.pastRuns.first.map { "Saved your run of \(StreakText.text(for: $0.duration()))" }
        ToastManager.shared.show(Toast(
            title: "Counter reset",
            subtitle: kept,
            icon: "arrow.counterclockwise",
            kind: .info,
            action: .init(title: "Undo") { [viewModel] in
                if viewModel.undoReset(updated) {
                    ToastManager.shared.show("Reset undone", icon: "arrow.uturn.backward", kind: .success)
                }
            },
            duration: 6
        ))
    }

    private func finishDelete(archive: Bool) {
        let title = localEvent.title
        if archive {
            viewModel.archiveEvent(localEvent)
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                ToastManager.shared.show("Archived “\(title)”", icon: "archivebox", kind: .info)
            }
        } else {
            viewModel.deleteEvent(localEvent)
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onDeleteSuccess?(title) }
        }
    }
}

// MARK: - Pieces

/// D / H / M / Y, with a sliding knob
private struct UnitSwitch: View {
    let unit: WidgetTimeUnit
    let onLight: Bool
    let onChange: (WidgetTimeUnit) -> Void
    @Namespace private var knob

    private let order: [(WidgetTimeUnit, String)] = [(.days, "D"), (.hours, "H"), (.months, "M"), (.years, "Y")]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(order, id: \.0) { u, letter in
                Button { onChange(u) } label: {
                    Text(letter)
                        .font(.allo(13, weight: .semibold))
                        .foregroundStyle(u == unit ? CardText.word : (onLight ? Color.white.opacity(0.8) : CardText.label))
                        .frame(width: 34, height: 30)
                        .contentShape(Capsule())
                        .background {
                            if u == unit {
                                Capsule().fill(Color.white)
                                    .shadow(color: .black.opacity(onLight ? 0 : 0.12), radius: 3, y: 1)
                                    .matchedGeometryEffect(id: "knob", in: knob)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(u.rawValue)
                .accessibilityAddTraits(u == unit ? .isSelected : [])
            }
        }
        .padding(4)
        .glassCapsule()
        .animation(.spring(duration: 0.35, bounce: 0.2), value: unit)
    }
}

/// The event's own card background: its pattern, or its photo
struct EventThemeBackground: View {
    let event: SinceEvent
    var body: some View {
        ZStack {
            if event.cardTheme == .custom, let data = event.imageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill().overlay(Color.black.opacity(0.18))
            } else {
                event.cardTheme.backgroundColor
                if let asset = event.cardTheme.squareSvgAssetName ?? event.cardTheme.svgAssetName {
                    Image(asset).resizable().scaledToFill()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

struct DashedRule: View {
    var vertical = false
    var body: some View {
        GeometryReader { proxy in
            Path { p in
                p.move(to: .zero)
                p.addLine(to: vertical ? CGPoint(x: 0, y: proxy.size.height) : CGPoint(x: proxy.size.width, y: 0))
            }
            .stroke(Color.black.opacity(0.1), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
        }
        .frame(width: vertical ? 1.5 : nil, height: vertical ? 40 : 1.5)
    }
}

/// 28 capsules growing taller toward the goal, lit in the event's colour
private struct GoalTicks: View {
    let lit: Int
    let color: Color
    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<28, id: \.self) { i in
                Capsule()
                    .fill(i < lit ? color : Color.black.opacity(0.09))
                    .frame(height: 40 * (0.26 + 0.74 * Double(i) / 27))
                    .animation(.spring(duration: 0.4).delay(Double(i) * 0.018), value: lit)
            }
        }
        .frame(height: 40)
    }
}

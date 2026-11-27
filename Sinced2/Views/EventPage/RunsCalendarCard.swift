//
//  RunsCalendarCard.swift
//  Sinced2
//
//  "Every run" as a month. Each run is a soft stripe in the card's own
//  colour, broken on the days it was reset; those days carry a small dot.
//  Tap one to read its note under the month and light up the run it ended.
//

import SwiftUI

struct RunsCalendarCard: View {
    let event: SinceEvent
    let now: Date
    /// The colour of the card's theme
    let tint: Color
    /// The reset that's picked, shared with the page so the big number reads that run
    @Binding var selected: UUID?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var month = RunsCalendarCard.monthIndex(Date())
    @State private var direction: CGFloat = 0

    private let cal = Calendar.current
    private static let row: CGFloat = 44

    // MARK: Days

    static func monthIndex(_ date: Date, _ cal: Calendar = .current) -> Int {
        let c = cal.dateComponents([.year, .month], from: date)
        return (c.year ?? 0) * 12 + (c.month ?? 1) - 1
    }

    private func key(_ date: Date) -> Int {
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 0) * 10000 + (c.month ?? 0) * 100 + (c.day ?? 0)
    }

    private func firstDay(of m: Int) -> Date {
        cal.date(from: DateComponents(year: m / 12, month: m % 12 + 1, day: 1)) ?? now
    }

    private var today: Date { cal.startOfDay(for: now) }
    private var firstDay: Date { cal.startOfDay(for: event.firstStartedAt) }
    private var currentStartDay: Date { cal.startOfDay(for: event.startedAt) }
    private var minMonth: Int { min(Self.monthIndex(event.firstStartedAt), maxMonth) }
    private var maxMonth: Int { Self.monthIndex(now) }

    /// The reset on each day; on a day with more than one, the last
    private var resetsByDay: [Int: Reset] {
        Dictionary(event.history.map { (key($0.at), $0) }, uniquingKeysWith: { a, b in a.at > b.at ? a : b })
    }

    private var selectedReset: Reset? { selected.flatMap { id in event.history.first { $0.id == id } } }

    // MARK: Body

    var body: some View {
        let resets = resetsByDay
        return VStack(alignment: .leading, spacing: 0) {
            header

            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                    Text(day).frame(maxWidth: .infinity)
                }
            }
            .font(.allo(12, weight: .medium))
            .foregroundStyle(CardText.connector)
            .padding(.top, 12)
            .accessibilityHidden(true)

            ZStack {
                grid(month, resets)
                    .id(month)
                    .transition(reduceMotion
                        ? .opacity
                        : .asymmetric(insertion: .offset(x: 28 * direction).combined(with: .opacity), removal: .opacity))
            }
            .frame(height: Self.row * 6)
            .padding(.top, 4)
            .clipped()
            .animation(.easeOut(duration: 0.2), value: selected)

            note(resets)
                .padding(.top, 8)

            DashedRule().padding(.top, 10)
            trio.padding(.top, 14)
        }
        .padding(EventPageView.gutter)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
        .padding(.horizontal, EventPageView.gutter)
        .padding(.top, 18)
        .onAppear { month = maxMonth }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Every run")
                .font(.allo(16, weight: .semibold))
                .foregroundStyle(CardText.word)
            Spacer(minLength: 8)
            HStack(spacing: 0) {
                chevron("chevron.left", label: "Previous month", enabled: month > minMonth) { go(-1) }
                Text(monthTitle)
                    .font(.allo(15, weight: .semibold))
                    .foregroundStyle(CardText.word)
                    .frame(minWidth: 84)
                    .contentTransition(.opacity)
                chevron("chevron.right", label: "Next month", enabled: month < maxMonth) { go(1) }
            }
            .padding(.trailing, -6)
        }
        .frame(height: 30)
    }

    private var monthTitle: String {
        let date = firstDay(of: month)
        let sameYear = month / 12 == maxMonth / 12
        return date.formatted(sameYear ? .dateTime.month(.wide) : .dateTime.month(.wide).year())
    }

    private func chevron(_ icon: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(enabled ? CardText.word : Color(hex: "dcdadc"))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func go(_ step: Int) {
        let next = month + step
        guard next >= minMonth, next <= maxMonth else { return }
        HapticManager.shared.selection()
        direction = CGFloat(step)
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.24)) {
            selected = nil
            month = next
        }
    }

    private var weekdays: [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    // MARK: Month

    /// Always six weeks, the neighbouring months faint, so every month is the same height
    private func grid(_ m: Int, _ resets: [Int: Reset]) -> some View {
        let first = firstDay(of: m)
        let lead = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        let start = cal.date(byAdding: .day, value: -lead, to: first) ?? first
        let picked = selectedReset
        return VStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let day = cal.date(byAdding: .day, value: week * 7 + col, to: start) ?? start
                        dayCell(day, col: col, month: m % 12 + 1, resets: resets, picked: picked)
                    }
                }
                .frame(height: Self.row)
            }
        }
    }

    private func isBand(_ day: Date, _ resets: [Int: Reset]) -> Bool {
        day >= firstDay && day <= today && resets[key(day)] == nil
    }

    @ViewBuilder
    private func dayCell(_ day: Date, col: Int, month m: Int, resets: [Int: Reset], picked: Reset?) -> some View {
        let inMonth = cal.component(.month, from: day) == m
        let reset = inMonth ? resets[key(day)] : nil
        let counting = day >= firstDay && day <= today
        let isToday = day == today
        let isPicked = reset != nil && reset?.id == picked?.id
        let band = inMonth && isBand(day, resets)

        ZStack {
            if band {
                let prev = cal.date(byAdding: .day, value: -1, to: day) ?? day
                let next = cal.date(byAdding: .day, value: 1, to: day) ?? day
                let capL = col == 0 || !isBand(prev, resets) || cal.component(.month, from: prev) != m
                let capR = col == 6 || isToday || !isBand(next, resets) || cal.component(.month, from: next) != m
                UnevenRoundedRectangle(
                    topLeadingRadius: capL ? 16 : 0, bottomLeadingRadius: capL ? 16 : 0,
                    bottomTrailingRadius: capR ? 16 : 0, topTrailingRadius: capR ? 16 : 0,
                    style: .continuous
                )
                .fill(tint.opacity(bandOpacity(day, picked: picked)))
                .frame(height: 32)
                .padding(.leading, capL ? 6 : 0)
                .padding(.trailing, capR ? 6 : 0)
            }

            Circle()
                .fill(isPicked ? CardText.word : Color.clear)
                .frame(width: 32, height: 32)

            Text("\(cal.component(.day, from: day))")
                .font(.allo(15, weight: isToday ? .bold : inMonth ? .medium : .regular).monospacedDigit())
                .foregroundStyle(
                    isPicked ? Color.white
                    : !inMonth ? Color(hex: "ebe9eb")
                    : counting ? CardText.word
                    : Color(hex: "cfcdcf")
                )

            if reset != nil {
                Circle()
                    .fill(tint)
                    .frame(width: 5, height: 5)
                    .scaleEffect(isPicked ? 1.3 : 1)
                    .offset(y: 19.5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { tap(reset) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayLabel(day, reset: reset))
        .accessibilityAddTraits(reset == nil ? [] : isPicked ? [.isButton, .isSelected] : .isButton)
        .accessibilityHidden(!inMonth)
    }

    /// Every run is a light stripe, this one a little stronger; a picked
    /// run stands out and the rest step back
    private func bandOpacity(_ day: Date, picked: Reset?) -> Double {
        if let picked, let start = picked.previousStart {
            let from = cal.startOfDay(for: start), to = cal.startOfDay(for: picked.at)
            return day > from && day < to ? 0.30 : 0.06
        }
        return day >= currentStartDay ? 0.22 : 0.13
    }

    private func tap(_ reset: Reset?) {
        let next: UUID? = reset.flatMap { $0.id == selected ? nil : $0.id }
        guard next != selected else { return }
        HapticManager.shared.selection()
        withAnimation(.spring(duration: 0.3, bounce: 0.1)) { selected = next }
    }

    private func dayLabel(_ day: Date, reset: Reset?) -> String {
        let date = day.formatted(.dateTime.weekday(.wide).day().month(.wide))
        guard let reset else { return date }
        if let note = reset.note, !note.isEmpty { return "Reset on \(date). \(note)" }
        return "Reset on \(date)"
    }

    // MARK: Note

    private func note(_ resets: [Int: Reset]) -> some View {
        let text = noteText()
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                if selectedReset != nil {
                    Circle().fill(tint).frame(width: 7, height: 7)
                }
                Text(text.title)
                    .font(.allo(15, weight: .semibold))
                    .foregroundStyle(CardText.word)
                    .lineLimit(1)
            }
            .frame(height: 22)
            Text(text.sub)
                .font(.allo(13.5, weight: .medium))
                .foregroundStyle(CardText.label)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
        .padding(.horizontal, 2)
        .id(text.title + text.sub)
        .transition(.blurReplace)
        .accessibilityElement(children: .combine)
    }

    private func noteText() -> (title: String, sub: String) {
        if let reset = selectedReset {
            let title = reset.note.flatMap { $0.isEmpty ? nil : "“\($0)”" } ?? "No note"
            guard let start = reset.previousStart else { return (title, "Reset on \(reset.at.sincedShortDate)") }
            let days = Int(reset.at.timeIntervalSince(start) / 86400)
            return (title, "\(Self.runPhrase(days)) · \(start.sincedShortDate) – \(reset.at.sincedShortDate)")
        }

        let name = firstDay(of: month).formatted(.dateTime.month(.wide))
        let isNow = month == maxMonth
        let days = Set(event.history.filter { Self.monthIndex($0.at, cal) == month }.map { cal.component(.day, from: $0.at) }).sorted()
        if days.isEmpty {
            if month == minMonth && !isNow { return ("You started on \(event.firstStartedAt.sincedShortDate)", "No resets that month") }
            if isNow { return ("No resets in \(name) yet", "This run began \(event.startedAt.sincedShortDate)") }
            return ("No resets in \(name)", "The whole month, unbroken")
        }
        let count = event.history.filter { Self.monthIndex($0.at, cal) == month }.count
        let ordinals = days.map(Self.ordinal)
        let list = ordinals.count == 1 ? ordinals[0] : ordinals.dropLast().joined(separator: ", ") + " and " + ordinals.last!
        return ("\(count) \(count == 1 ? "reset" : "resets") in \(name)", "On the \(list)")
    }

    /// "A 14-day run", "An 18-day run"
    static func runPhrase(_ days: Int) -> String {
        guard days > 0 else { return "A run of under a day" }
        let an = String(days).hasPrefix("8") || days == 11 || days == 18
        return "\(an ? "An" : "A") \(days)-day run"
    }

    private static let ordinalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        return f
    }()

    static func ordinal(_ n: Int) -> String { ordinalFormatter.string(from: NSNumber(value: n)) ?? "\(n)" }

    // MARK: Totals

    private var trio: some View {
        let longest = Int(event.bestRunDuration(at: now) / 86400)
        let past = event.pastRuns.map { $0.duration(at: now) }
        let average = past.isEmpty ? nil : Int(past.reduce(0, +) / Double(past.count) / 86400)
        // Longest counts this run too, so it never reads lower than the card
        let longestLabel = event.isOnBestRun(at: now) ? "Longest · this one" : "Longest run"
        return HStack(spacing: 0) {
            stat("\(longest)", unit: "d", label: longestLabel, first: true)
            DashedRule(vertical: true)
            stat(average.map(String.init) ?? "–", unit: average == nil ? "" : "d", label: "Average run")
            DashedRule(vertical: true)
            stat("\(event.history.count)", unit: "", label: "Resets")
        }
    }

    private func stat(_ value: String, unit: String, label: String, first: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text(value).font(.allo(26, weight: .semibold)) + Text(unit).font(.allo(15, weight: .semibold)))
                .foregroundStyle(CardText.word)
                .contentTransition(.numericText())
            Text(label)
                .font(.allo(12, weight: .medium))
                .foregroundStyle(CardText.label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, first ? 0 : 14)
        .accessibilityElement(children: .combine)
    }
}

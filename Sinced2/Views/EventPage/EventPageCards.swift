//
//  EventPageCards.swift
//  Sinced2
//
//  What the event page's floating card shows: reset, reminders, and delete
//  or archive. Each reads as a sentence, like the add card.
//

import SwiftUI

// MARK: - Reset

/// "Reset no caffeine, from now, with a note", then hold to confirm.
/// The −/+ steps the reset back in time for when it happened earlier.
struct ResetCard: View {
    let event: SinceEvent
    @ObservedObject var viewModel: EventViewModel
    let close: FloatingCardClose
    let onReset: () -> Void

    @State private var step = 0
    @State private var custom: Date?
    @State private var note = ""
    @FocusState private var noteFocused: Bool

    private var options: [(word: String, date: Date)] {
        let now = Date(), calendar = Calendar.current
        var list: [(String, Date)] = [("now", now), ("an hour ago", now.addingTimeInterval(-3600))]
        if let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now), morning < now.addingTimeInterval(-3600) {
            list.append(("this morning", morning))
        }
        list.append(("yesterday", now.addingTimeInterval(-86400)))
        list.append(("2 days ago", now.addingTimeInterval(-2 * 86400)))
        // Never before the run it's ending began
        return list.filter { $0.1 >= event.startedAt || $0.0 == "now" }
    }

    /// One step past the last preset is "a date", which opens the calendar
    private var picking: Bool { step >= options.count }

    private var chosen: (word: String, date: Date) {
        guard picking else { return options[step] }
        let date = custom ?? defaultCustom
        // Just the day; the calendar shows the time underneath
        let calendar = Calendar.current
        let word = calendar.isDateInToday(date) ? "today" : calendar.isDateInYesterday(date) ? "yesterday" : date.formatted(.dateTime.day().month(.abbreviated))
        return (word, date)
    }

    /// Where the calendar starts: a day before the last preset, or for a
    /// young run, halfway back to when it began
    private var defaultCustom: Date {
        let last = options.last?.date ?? Date(), start = min(event.startedAt, Date())
        let dayBefore = last.addingTimeInterval(-86400)
        return dayBefore > start ? dayBefore : start.addingTimeInterval(last.timeIntervalSince(start) / 2)
    }

    /// Anywhere from when this run began up to now
    private var pickerRange: ClosedRange<Date> { min(event.startedAt, Date())...Date() }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WrapLayout(spacing: 7, lineSpacing: 0) {
                Text("Reset").font(CardText.connectorFont).foregroundStyle(CardText.connector)
                Text(event.title.lowercased()).font(CardText.wordFont).foregroundStyle(CardText.word)
            }

            HStack(alignment: .center, spacing: 7) {
                Text("from").font(CardText.connectorFont).foregroundStyle(CardText.connector)
                MorphText(text: chosen.word, font: CardText.wordFont, color: CardText.word)
                Spacer(minLength: 8)
                StepperPill(canDecrease: !picking, canIncrease: step > 0) { s in
                    withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
                        step = min(options.count, max(0, step - s))
                    }
                }
            }
            .padding(.top, 4)

            if picking {
                DatePicker("", selection: Binding(get: { custom ?? defaultCustom }, set: { new in
                    withAnimation(MorphText.animation) { custom = new }
                }), in: pickerRange, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(.primaryGreen)
                .padding(.top, 6)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }

            HStack(alignment: .center, spacing: 7) {
                Text("with").font(CardText.connectorFont).foregroundStyle(CardText.connector)
                TextField("", text: $note, prompt: Text("a note").foregroundColor(Color(hex: "c4c2c4")))
                    .font(CardText.wordFont)
                    .foregroundStyle(CardText.word)
                    .tint(.primaryGreen)
                    .focused($noteFocused)
                    .submitLabel(.done)
                    .onSubmit { noteFocused = false }
                    .onChange(of: note) { _, value in
                        if value.count > 80 { note = String(value.prefix(80)) }
                    }
            }
            .padding(.top, 4)

            (Text("Your ") + Text(StreakText.text(for: max(0, chosen.date.timeIntervalSince(event.startedAt)))).foregroundColor(CardText.word).fontWeight(.semibold)
                + Text(" run is saved in your history. The first start, \(event.firstStartedAt.sincedShortDate), stays."))
                .font(.allo(14))
                .foregroundStyle(CardText.label)
                .contentTransition(.opacity)
                .padding(.top, 10)

            HStack(spacing: 10) {
                GhostPillButton(title: "Cancel") { close(nil) }
                HoldToConfirmButton(title: "Hold to reset", onConfirm: reset)
            }
            .padding(.top, 22)
        }
    }

    private func reset() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.resetEvent(event, at: min(chosen.date, Date()), note: trimmed.isEmpty ? nil : trimmed)
        close { onReset() }
    }
}

// MARK: - Reminders

/// "Remind me every day at 9:00 am", set with chips like the add card:
/// how often, then when. Changes save as they're made.
struct RemindersCard: View {
    @Binding var event: SinceEvent
    @ObservedObject var viewModel: EventViewModel
    let close: FloatingCardClose

    @ObservedObject private var notifications = NotificationManager.shared
    @State private var otherTime = false
    @State private var showingPermissionAlert = false

    private var r: ReminderSettings { event.reminderSettings }

    private enum Often: Hashable { case off, daily, someDays }
    private var often: Often { !r.isEnabled ? .off : r.reminderType == .daily ? .daily : .someDays }

    private static let times: [(hour: Int, minute: Int)] = [(8, 0), (9, 0), (12, 30), (18, 0), (21, 0)]

    private var summary: String {
        guard r.isEnabled else { return "never" }
        switch r.reminderType {
        case .daily:
            return "every day at " + Self.timeText(r.dailyHour, r.dailyMinute)
        case .weekly:
            let days = Set(r.weeklyDays)
            if days.count == 7 { return "every day" }
            if days == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "on weekdays" }
            if days == [.saturday, .sunday] { return "on weekends" }
            let picked = Weekday.allCases.filter(days.contains)
            if picked.count == 1, let day = picked.first { return "every " + day.fullName }
            let names = picked.map(\.shortName)
            return "on " + names.formatted(.list(type: .and))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WrapLayout(spacing: 7, lineSpacing: 0) {
                Text("Remind me").font(CardText.connectorFont).foregroundStyle(CardText.connector)
                MorphText(text: summary, font: CardText.wordFont, color: CardText.word)
            }

            // How often
            HStack(spacing: 8) {
                chip("Off", on: often == .off) { setOften(.off) }
                chip("Every day", on: often == .daily) { setOften(.daily) }
                chip("Some days", on: often == .someDays) { setOften(.someDays) }
            }
            .padding(.top, 16)

            // When
            if often == .daily {
                timeChips
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                if otherTime {
                    DatePicker("Time", selection: Binding(get: { r.dailyReminderTime }, set: { date in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                        update { $0.dailyHour = c.hour ?? 9; $0.dailyMinute = c.minute ?? 0 }
                    }), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .clipped()
                    .transition(.opacity)
                }
            } else if often == .someDays {
                dayCircles
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                Text("At a different time each day, between 9 am and 9 pm.")
                    .font(.allo(14))
                    .foregroundStyle(CardText.label)
                    .padding(.top, 12)
                    .transition(.opacity)
            }

            // Reminders can't arrive while notifications are off for the app
            if r.isEnabled && !notifications.notificationsEnabled {
                HStack(spacing: 6) {
                    Text("Notifications are off for Sinced.").foregroundStyle(CardText.label)
                    Button("Turn on") {
                        HapticManager.shared.light()
                        notifications.setNotificationsEnabled(true)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primaryGreen)
                }
                .font(.allo(14))
                .padding(.top, 12)
                .transition(.opacity)
            }

            Button { close(nil) } label: {
                Text("Done")
                    .font(.allo(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(Color.primaryGreen))
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 22)
        }
        .animation(.spring(duration: 0.4, bounce: 0.1), value: often)
        .animation(.spring(duration: 0.4, bounce: 0.1), value: otherTime)
        .alert("Notifications are off", isPresented: $showingPermissionAlert) {
            Button("Open Settings") { notifications.openSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To get reminders, turn on notifications for Sinced in Settings.")
        }
    }

    // MARK: Pieces

    private var timeChips: some View {
        let preset = Self.times.contains { $0.hour == r.dailyHour && $0.minute == r.dailyMinute }
        return WrapLayout(spacing: 8, lineSpacing: 8) {
            ForEach(Self.times, id: \.hour) { t in
                chip(Self.timeText(t.hour, t.minute), on: !otherTime && r.dailyHour == t.hour && r.dailyMinute == t.minute) {
                    otherTime = false
                    update { $0.dailyHour = t.hour; $0.dailyMinute = t.minute }
                }
            }
            // Any other time: shows the time once it's set, and opens a wheel
            chip(preset ? "Other" : Self.timeText(r.dailyHour, r.dailyMinute), on: otherTime || !preset) {
                HapticManager.shared.selection()
                otherTime.toggle()
            }
        }
    }

    private var dayCircles: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.allCases) { day in
                let on = r.weeklyDays.contains(day)
                Button {
                    update { s in
                        if on {
                            // Always keep at least one day
                            if s.weeklyDays.count > 1 { s.weeklyDays.removeAll { $0 == day } }
                        } else {
                            s.weeklyDays.append(day)
                            s.weeklyDays.sort { $0.rawValue < $1.rawValue }
                        }
                    }
                } label: {
                    Text(String(day.shortName.prefix(1)))
                        .font(.allo(15, weight: .semibold))
                        .foregroundStyle(on ? Color.white : Color(hex: "3a383a"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Circle().fill(on ? CardText.word : CardText.fill))
                        .animation(.easeOut(duration: 0.18), value: on)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(day.fullName)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    private func chip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MorphText(text: title, font: .allo(14, weight: .medium), color: on ? .white : Color(hex: "3a383a"))
                .padding(.horizontal, 13)
                .frame(height: 34)
                .background(Capsule().fill(on ? CardText.word : CardText.fill))
                .animation(.easeOut(duration: 0.18), value: on)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private static func timeText(_ hour: Int, _ minute: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return date.formatted(date: .omitted, time: .shortened).lowercased()
    }

    // MARK: Actions

    private func setOften(_ new: Often) {
        guard new != often else { return }
        otherTime = false
        switch new {
        case .off:
            update { $0.isEnabled = false }
        case .daily, .someDays:
            let type: ReminderType = new == .daily ? .daily : .weekly
            enable { $0.reminderType = type }
        }
    }

    /// Turning reminders on asks for notification permission first
    private func enable(_ change: @escaping (inout ReminderSettings) -> Void) {
        let turnOn = { update { change(&$0); $0.isEnabled = true } }
        guard !r.isEnabled else { update(change); return }
        switch notifications.authorizationStatus {
        case .notDetermined:
            notifications.requestAuthorization { granted in
                if granted { turnOn() } else { showingPermissionAlert = true }
            }
        case .denied:
            HapticManager.shared.light()
            showingPermissionAlert = true
        default:
            turnOn()
        }
    }

    /// Apply a change and save straight away
    private func update(_ change: (inout ReminderSettings) -> Void) {
        var updated = event
        change(&updated.reminderSettings)
        guard updated != event else { return }
        HapticManager.shared.selection()
        withAnimation(MorphText.animation) { event = updated }
        viewModel.updateEvent(updated)
    }
}

// MARK: - Delete or archive

/// Archive is the default, since it keeps everything; turning "Keep its
/// history" off makes it a delete, and the words and button say so
struct DeleteCard: View {
    let event: SinceEvent
    let close: FloatingCardClose
    let onConfirm: (_ archive: Bool) -> Void

    @State private var archive = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WrapLayout(spacing: 7, lineSpacing: 0) {
                MorphText(text: archive ? "Archive" : "Delete", font: CardText.connectorFont, color: CardText.connector)
                Text(event.title.lowercased() + "?").font(CardText.wordFont).foregroundStyle(CardText.word)
            }

            let runs = event.history.count + 1
            (Text("\(runs)").foregroundColor(CardText.word).fontWeight(.semibold) + Text(runs == 1 ? " run" : " runs") + Text(archive ? " and every note stay safe." : " and every note go for good."))
                .font(.allo(14))
                .foregroundStyle(CardText.label)
                .contentTransition(.opacity)
                .padding(.top, 8)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keep its history").font(.allo(15, weight: .medium)).foregroundStyle(CardText.word)
                    Text("Archive hides it from home and keeps everything.").font(.allo(13)).foregroundStyle(CardText.label)
                }
                Spacer(minLength: 8)
                Toggle("Keep its history", isOn: $archive.animation(.spring(duration: 0.35, bounce: 0.1)))
                    .labelsHidden()
                    .tint(CardText.word)
                    .sensoryFeedback(.selection, trigger: archive)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(CardText.fill))
            .padding(.top, 16)

            HStack(spacing: 10) {
                GhostPillButton(title: "Cancel") { close(nil) }
                Button {
                    archive ? HapticManager.shared.light() : HapticManager.shared.warning()
                    let keep = archive
                    close { onConfirm(keep) }
                } label: {
                    MorphText(text: archive ? "Archive" : "Delete for good", font: .allo(16, weight: .semibold), color: .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(archive ? Color.primaryGreen : Color(hex: "D8453B")))
                        .animation(.easeOut(duration: 0.2), value: archive)
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.top, 22)
        }
    }
}

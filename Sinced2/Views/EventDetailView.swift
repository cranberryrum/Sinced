//
//  EventDetailView.swift
//  Sinced2
//
//  Detailed view of a single event with reset and timeline
//

import SwiftUI
import Combine

struct EventDetailView: View {
    let event: SinceEvent
    @ObservedObject var viewModel: EventViewModel
    let onDeleteSuccess: ((String) -> Void)?
    @Environment(\.dismiss) var dismiss
    
    @State private var showingResetSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteSheet = false
    @State private var showingEditSheet = false
    @State private var currentTime = Date()
    @State private var localEvent: SinceEvent
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init(event: SinceEvent, viewModel: EventViewModel, onDeleteSuccess: ((String) -> Void)? = nil) {
        self.event = event
        self.viewModel = viewModel
        self.onDeleteSuccess = onDeleteSuccess
        self._localEvent = State(initialValue: event)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Event name
                        Text(localEvent.title)
                            .font(.roundedTitle)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            // Crossfade when renamed instead of snapping
                            .contentTransition(.opacity)
                        
                        // 2. Started on date
                        Text("Started on \(localEvent.smartFormattedStartDate)")
                            .font(.roundedSubheadline)
                            .foregroundColor(.secondary)
                            .contentTransition(.opacity)
                        
                        // 4. Native Segmented Control - Major prominence
                        VStack(spacing: 16) {
                            Picker("Time Unit", selection: Binding(
                                get: { localEvent.widgetTimeUnit },
                                set: { newValue in
                                    withAnimation(.smooth(duration: 0.35)) {
                                        localEvent.widgetTimeUnit = newValue
                                    }
                                    viewModel.updateEvent(localEvent)
                                }
                            )) {
                                ForEach(WidgetTimeUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 20)
                            
                            // Large Time Value with smooth ticker animation
                            AnimatedTimeDisplay(event: localEvent, currentTime: currentTime)
                                .padding(.vertical, 20)
                            
                            // Next Milestone inline (if applicable)
                            if let milestone = localEvent.nextMilestone() {
                                HStack(spacing: 6) {
                                    Image(systemName: "flag.fill")
                                        .font(.rounded(14))
                                        .foregroundColor(.lightBlue)
                                    
                                    Text("\(milestone.days)d milestone in \(milestone.timeRemaining)")
                                        .font(.roundedCallout)
                                        .foregroundColor(.lightBlue)
                                }
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal, 20)
                        
                        // Primary Action - Reset Timer
                        Button(action: {
                            showingResetSheet = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.rounded(18, weight: .semibold))
                                Text("Reset Timer")
                                    .font(.rounded(17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.primaryBlue)
                            )
                        }
                        .frame(maxWidth: geometry.size.width - 40)
                        .padding(.horizontal, 20)
                        
                        // Reminders Section
                        ReminderToggleSection(
                            event: $localEvent,
                            viewModel: viewModel
                        )
                        .padding(.horizontal, 20)
                        
                        // Secondary Actions - Compact row
                        HStack(spacing: 12) {
                            // Share
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.rounded(20))
                                        .foregroundColor(.green)
                                    Text("Share")
                                        .font(.roundedCaption)
                                        .foregroundColor(.green)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.green.opacity(0.1))
                                )
                            }
                            
                            // Delete
                            Button(action: {
                                HapticManager.shared.medium()
                                showingDeleteSheet = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "trash")
                                        .font(.rounded(20))
                                        .foregroundColor(.red)
                                    Text("Delete")
                                        .font(.roundedCaption)
                                        .foregroundColor(.red)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                        }
                        .frame(maxWidth: geometry.size.width - 40)
                        .padding(.horizontal, 20)
                    
                    // Timeline / History - Cleaner section
                    if !localEvent.history.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("History")
                                    .font(.roundedHeadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(localEvent.history.count) reset\(localEvent.history.count == 1 ? "" : "s")")
                                    .font(.roundedCaption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 10) {
                                ForEach(localEvent.history.prefix(5)) { reset in
                                    TimelineItemView(reset: reset)
                                        .frame(maxWidth: geometry.size.width - 40)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 16)
                    }
                    
                    Spacer(minLength: 60)
                }
                .frame(maxWidth: geometry.size.width)
            }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        HapticManager.shared.light()
                        showingEditSheet = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .overlay {
                if showingResetSheet {
                    Color.black
                        .opacity(0.12)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .sheet(isPresented: $showingResetSheet) {
                ResetSheetView(event: localEvent, viewModel: viewModel)
            }
            .sheet(isPresented: $showingEditSheet) {
                AddEventBottomSheet(
                    viewModel: viewModel,
                    isPresented: $showingEditSheet,
                    editingEvent: localEvent
                )
                .presentationDetents([.height(440)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheetView(event: localEvent)
            }
            .sheet(isPresented: $showingDeleteSheet) {
                DeleteConfirmationSheet(
                    eventTitle: localEvent.title,
                    onConfirmDelete: confirmDelete
                )
                .presentationDetents([.height(280), .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onReceive(viewModel.$events) { events in
            guard let updatedEvent = events.first(where: { $0.id == localEvent.id }),
                  updatedEvent != localEvent else { return }
            // Same motion as switching time units, so edits land smoothly
            // (the counter ticks to its new value via AnimatedTimeDisplay)
            withAnimation(.smooth(duration: 0.35)) {
                localEvent = updatedEvent
            }
        }
    }
    
    private func handleDelete() {
        let title = localEvent.title
        
        // Delete the event
        viewModel.deleteEvent(localEvent)
        
        // Dismiss immediately
        dismiss()
        
        // Show success toast on home page after dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDeleteSuccess?(title)
        }
    }
    
    private func confirmDelete() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showingDeleteSheet = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            handleDelete()
        }
    }
}

/// Timeline item for showing reset history
struct TimelineItemView: View {
    let reset: Reset
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline dot
            Circle()
                .fill(Color.primaryBlue)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reset.formattedDate)
                    .font(.roundedSubheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let note = reset.note, !note.isEmpty {
                    Text(note)
                        .font(.roundedCaption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
}

/// Reminders row for the event detail view. The toggle turns reminders on/off
/// right here; when on, the schedule is edited in place with native pop-up
/// controls instead of a separate sheet. Changes save immediately.
struct ReminderToggleSection: View {
    @Binding var event: SinceEvent
    let viewModel: EventViewModel
    
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingPermissionAlert = false
    
    private var settings: ReminderSettings { event.reminderSettings }
    
    var body: some View {
        VStack(spacing: 0) {
            // L1: always-visible toggle
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(settings.isEnabled ? Color.primaryBlue : Color.secondary.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: settings.isEnabled ? "bell.badge.fill" : "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(settings.isEnabled ? .white : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reminders")
                        .font(.roundedBody)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(statusText)
                        .font(.roundedCaption)
                        .foregroundColor(.secondary)
                        .contentTransition(.opacity)
                }
                
                Spacer()
                
                Toggle("Reminders", isOn: Binding(
                    get: { settings.isEnabled },
                    set: handleToggle
                ))
                .labelsHidden()
                .tint(.primaryBlue)
            }
            .padding(16)
            
            // Schedule, edited in place
            if settings.isEnabled {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.leading, 66)
                    
                    scheduleRow(title: "Repeat") {
                        repeatMenu
                    }
                    
                    Divider()
                        .padding(.leading, 66)
                    
                    if settings.reminderType == .daily {
                        scheduleRow(title: "Time") {
                            DatePicker(
                                "Time",
                                selection: Binding(
                                    get: { settings.dailyReminderTime },
                                    set: { newTime in
                                        let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                        update {
                                            $0.dailyHour = components.hour ?? 9
                                            $0.dailyMinute = components.minute ?? 0
                                        }
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        .transition(.opacity)
                    } else {
                        scheduleRow(title: "Days") {
                            weekdayMenu
                        }
                        .transition(.opacity)
                        
                        Text("Sent at a different time each day, between 9 AM and 9 PM.")
                            .font(.roundedCaption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 66)
                            .padding(.trailing, 16)
                            .padding(.bottom, 12)
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 6)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }
            
            // Event reminders can't fire while notifications are off app-wide
            if settings.isEnabled && !notificationManager.notificationsEnabled {
                HStack(spacing: 8) {
                    Text("Notifications are off for Sinced.")
                        .font(.roundedCaption)
                        .foregroundColor(.secondary)
                    
                    Button("Turn on") {
                        HapticManager.shared.light()
                        notificationManager.setNotificationsEnabled(true)
                    }
                    .font(.roundedCaption.weight(.semibold))
                    .foregroundColor(.primaryBlue)
                    
                    Spacer()
                }
                .padding(.leading, 66)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.smooth(duration: 0.3), value: settings.isEnabled)
        .animation(.smooth(duration: 0.3), value: settings.reminderType)
        .animation(.smooth(duration: 0.3), value: notificationManager.notificationsEnabled)
        .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                notificationManager.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive reminders, please enable notifications in Settings.")
        }
    }
    
    // MARK: - Pieces
    
    private func scheduleRow<Control: View>(title: String, @ViewBuilder control: () -> Control) -> some View {
        HStack {
            Text(title)
                .font(.roundedBody)
                .foregroundColor(.primary)
            
            Spacer()
            
            control()
        }
        .padding(.leading, 66) // Aligns with the "Reminders" title
        .padding(.trailing, 16) // Aligns controls with the toggle
        .padding(.vertical, 4)
        .frame(minHeight: 52)
    }
    
    /// Repeat menu with a custom label, so its trailing edge lines up with the
    /// toggle (the stock `.menu` picker adds its own inset)
    private var repeatMenu: some View {
        Menu {
            Picker("Repeat", selection: Binding(
                get: { settings.reminderType },
                set: { newType in update { $0.reminderType = newType } }
            )) {
                ForEach(ReminderType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
        } label: {
            menuLabel(settings.reminderType.rawValue)
        }
    }
    
    private func menuLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.roundedBody)
                .lineLimit(1)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.primaryBlue)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
    
    /// Multi-select weekday menu that stays open while days are toggled
    private var weekdayMenu: some View {
        Menu {
            ForEach(Weekday.allCases) { weekday in
                Toggle(weekday.fullName, isOn: Binding(
                    get: { settings.weeklyDays.contains(weekday) },
                    set: { isOn in toggleDay(weekday, isOn: isOn) }
                ))
                // Keep at least one day selected
                .disabled(settings.weeklyDays == [weekday])
            }
        } label: {
            menuLabel(weekdaySummary)
        }
        .menuActionDismissBehavior(.disabled)
    }
    
    // MARK: - Text
    
    private var statusText: String {
        guard settings.isEnabled else {
            return "Get daily or weekly motivation"
        }
        guard notificationManager.notificationsEnabled else {
            return "Paused"
        }
        switch settings.reminderType {
        case .daily:
            return "Daily at \(settings.dailyReminderTime.formatted(date: .omitted, time: .shortened))"
        case .weekly:
            return "Weekly on \(weekdaySummary)"
        }
    }
    
    private var weekdaySummary: String {
        let days = Set(settings.weeklyDays)
        if days.count == 7 { return "Every day" }
        if days == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "Weekdays" }
        if days == [.saturday, .sunday] { return "Weekends" }
        return Weekday.allCases
            .filter(days.contains)
            .map(\.shortName)
            .joined(separator: ", ")
    }
    
    // MARK: - Actions
    
    /// Apply a change to the reminder settings and save straight away
    private func update(_ change: (inout ReminderSettings) -> Void) {
        var updated = event
        change(&updated.reminderSettings)
        guard updated != event else { return }
        HapticManager.shared.selection()
        event = updated
        viewModel.updateEvent(updated)
    }
    
    private func toggleDay(_ weekday: Weekday, isOn: Bool) {
        update { settings in
            if isOn {
                if !settings.weeklyDays.contains(weekday) { settings.weeklyDays.append(weekday) }
            } else if settings.weeklyDays.count > 1 {
                settings.weeklyDays.removeAll { $0 == weekday }
            }
            settings.weeklyDays.sort { $0.rawValue < $1.rawValue }
        }
    }
    
    private func handleToggle(_ isOn: Bool) {
        guard isOn else {
            update { $0.isEnabled = false }
            return
        }
        
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            notificationManager.requestAuthorization { granted in
                if granted {
                    update { $0.isEnabled = true }
                } else {
                    showingPermissionAlert = true
                }
            }
        case .denied:
            HapticManager.shared.light()
            showingPermissionAlert = true
        default:
            update { $0.isEnabled = true }
        }
    }
}

#Preview {
    let sampleEvent = SinceEvent(
        title: "Coffee",
        startedAt: Date().addingTimeInterval(-3600 * 24 * 3),
        history: [
            Reset(at: Date().addingTimeInterval(-3600 * 24 * 10), note: "Had a latte at work")
        ]
    )
    
    EventDetailView(event: sampleEvent, viewModel: EventViewModel())
}


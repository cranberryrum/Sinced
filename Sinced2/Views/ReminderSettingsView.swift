//
//  ReminderSettingsView.swift
//  Sinced2
//
//  Apple-native UI for configuring event reminders
//

import SwiftUI

struct ReminderSettingsView: View {
    @Binding var event: SinceEvent
    let viewModel: EventViewModel
    let startEnabled: Bool // When opened from L1 toggle, this will be true
    @Environment(\.dismiss) var dismiss
    
    @State private var reminderEnabled: Bool
    @State private var reminderType: ReminderType
    @State private var selectedDays: Set<Weekday>
    @State private var dailyReminderTime: Date
    
    init(event: Binding<SinceEvent>, viewModel: EventViewModel, startEnabled: Bool = false) {
        self._event = event
        self.viewModel = viewModel
        self.startEnabled = startEnabled
        // If startEnabled is true (opened from L1 toggle), default to ON
        // Otherwise, use the event's current setting
        let shouldBeEnabled = startEnabled || event.wrappedValue.reminderSettings.isEnabled
        self._reminderEnabled = State(initialValue: shouldBeEnabled)
        self._reminderType = State(initialValue: event.wrappedValue.reminderSettings.reminderType)
        self._selectedDays = State(initialValue: Set(event.wrappedValue.reminderSettings.weeklyDays))
        self._dailyReminderTime = State(initialValue: event.wrappedValue.reminderSettings.dailyReminderTime)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Main Toggle Section
                Section {
                    Toggle(isOn: $reminderEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 20))
                                .foregroundColor(reminderEnabled ? .primaryBlue : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reminders")
                                    .font(.roundedBody)
                                    .foregroundColor(.primary)
                                
                                Text("Get motivated with progress updates")
                                    .font(.roundedCaption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(.primaryBlue)
                }
                
                // MARK: - Frequency Section
                if reminderEnabled {
                    Section {
                        Picker("Frequency", selection: $reminderType) {
                            ForEach(ReminderType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Frequency")
                            .font(.roundedCaption)
                    } footer: {
                        Text(frequencyDescription)
                            .font(.roundedCaption)
                    }
                
                // MARK: - Daily Time Picker
                if reminderType == .daily {
                    Section {
                        DatePicker(
                            "Time",
                            selection: $dailyReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                    } header: {
                        Text("Reminder Time")
                            .font(.roundedCaption)
                    } footer: {
                        Text("You'll receive a notification at this time every day.")
                            .font(.roundedCaption)
                    }
                }
                
                // MARK: - Weekly Day Selection
                if reminderType == .weekly {
                    Section {
                        ForEach(Weekday.allCases) { weekday in
                            WeekdayRow(
                                weekday: weekday,
                                isSelected: selectedDays.contains(weekday),
                                onTap: {
                                    toggleDay(weekday)
                                }
                            )
                        }
                    } header: {
                        Text("Notify me on")
                            .font(.roundedCaption)
                    } footer: {
                        Text("You'll receive reminders at a random time between 9 AM and 8 PM on the selected days.")
                            .font(.roundedCaption)
                    }
                }
                
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // If user cancels and this was opened to enable, disable it
                        if startEnabled && !event.reminderSettings.isEnabled {
                            // Don't save anything, just dismiss
                        }
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryBlue)
                    .disabled(reminderType == .weekly && selectedDays.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var frequencyDescription: String {
        switch reminderType {
        case .daily:
            return "You'll receive a daily motivational reminder about your progress."
        case .weekly:
            return "You'll receive reminders on the days you select."
        }
    }
    
    // MARK: - Actions
    
    private func toggleDay(_ weekday: Weekday) {
        HapticManager.shared.selection()
        
        if selectedDays.contains(weekday) {
            // Don't allow deselecting the last day
            if selectedDays.count > 1 {
                selectedDays.remove(weekday)
            }
        } else {
            selectedDays.insert(weekday)
        }
    }
    
    private func saveSettings() {
        // Update event with new settings
        event.reminderSettings = ReminderSettings(
            isEnabled: reminderEnabled,
            reminderType: reminderType,
            weeklyDays: Array(selectedDays).sorted { $0.rawValue < $1.rawValue },
            dailyReminderTime: dailyReminderTime
        )
        
        // Save to storage
        viewModel.updateEvent(event)
        
        // Schedule/cancel notifications
        NotificationManager.shared.scheduleReminders(for: event)
        
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Weekday Row Component

struct WeekdayRow: View {
    let weekday: Weekday
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(weekday.fullName)
                    .font(.roundedBody)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryBlue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ReminderSettingsView(
        event: .constant(SinceEvent(
            title: "No smoking",
            startedAt: Date().addingTimeInterval(-86400 * 5)
        )),
        viewModel: EventViewModel(),
        startEnabled: true
    )
}


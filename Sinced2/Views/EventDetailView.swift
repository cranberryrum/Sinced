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
    @State private var showingReminderSettings = false
    @State private var showingDeleteSheet = false
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
                        
                        // 2. Started on date
                        Text("Started on \(localEvent.smartFormattedStartDate)")
                            .font(.roundedSubheadline)
                            .foregroundColor(.secondary)
                        
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
                            viewModel: viewModel,
                            showingReminderSettings: $showingReminderSettings
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
            .sheet(isPresented: $showingShareSheet) {
                ShareSheetView(event: localEvent)
            }
            .sheet(isPresented: $showingReminderSettings) {
                ReminderSettingsView(
                    event: $localEvent,
                    viewModel: viewModel,
                    startEnabled: !localEvent.reminderSettings.isEnabled
                )
            }
            .sheet(isPresented: $showingDeleteSheet) {
                DeleteConfirmationSheet(
                    eventTitle: localEvent.title,
                    onConfirmDelete: confirmDelete
                )
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onReceive(viewModel.$events) { events in
            guard let updatedEvent = events.first(where: { $0.id == localEvent.id }) else { return }
            localEvent = updatedEvent
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

/// Reminder toggle section for event detail view
struct ReminderToggleSection: View {
    @Binding var event: SinceEvent
    let viewModel: EventViewModel
    @Binding var showingReminderSettings: Bool
    
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main toggle row
            Button(action: {
                if event.reminderSettings.isEnabled {
                    // If already enabled, open settings
                    showingReminderSettings = true
                } else {
                    // Enable and request permission if needed
                    handleToggle()
                }
            }) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(event.reminderSettings.isEnabled ? Color.primaryBlue : Color.secondary.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: event.reminderSettings.isEnabled ? "bell.badge.fill" : "bell.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(event.reminderSettings.isEnabled ? .white : .secondary)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reminders")
                            .font(.roundedBody)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(reminderStatusText)
                            .font(.roundedCaption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Toggle / Chevron
                    if event.reminderSettings.isEnabled {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    } else {
                        Toggle("", isOn: Binding(
                            get: { event.reminderSettings.isEnabled },
                            set: { _ in handleToggle() }
                        ))
                        .labelsHidden()
                        .tint(.primaryBlue)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)
        }
        .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                notificationManager.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive reminders, please enable notifications in Settings.")
        }
    }
    
    private var reminderStatusText: String {
        guard event.reminderSettings.isEnabled else {
            return "Get daily or weekly motivation"
        }
        
        switch event.reminderSettings.reminderType {
        case .daily:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: event.reminderSettings.dailyReminderTime)
            return "Daily at \(timeString)"
        case .weekly:
            let days = event.reminderSettings.weeklyDays
                .sorted { $0.rawValue < $1.rawValue }
                .map { $0.shortName }
                .joined(separator: ", ")
            return "Weekly on \(days)"
        }
    }
    
    private func handleToggle() {
        HapticManager.shared.light()
        
        // Check notification permission status
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            // Request permission
            notificationManager.requestAuthorization { granted in
                if granted {
                    showingReminderSettings = true
                }
            }
        case .denied:
            showingPermissionAlert = true
        case .authorized, .provisional, .ephemeral:
            showingReminderSettings = true
        @unknown default:
            showingReminderSettings = true
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


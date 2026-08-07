//
//  SettingsView.swift
//  Sinced2
//
//  Created by AI on 2026-01-18.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @State private var activeSheet: SettingsSheet?
    @State private var showingNameEditor = false

    private var displayName: String {
        let trimmed = viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Your name" : trimmed
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingNameEditor = true
                    } label: {
                        NameSettingsRow(name: displayName)
                    }
                    .buttonStyle(.plain)

                    Button {
                        activeSheet = .aboutApp
                    } label: {
                        SettingsRowLabel(title: "About Sinced")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        NotificationSettingsView()
                            .environmentObject(viewModel)
                    } label: {
                        SettingsRowLabel(title: "Notifications", showsChevron: false)
                    }

                    Button {
                        activeSheet = .aboutDeveloper
                    } label: {
                        SettingsRowLabel(title: "About Developer")
                    }
                    .buttonStyle(.plain)

                    Button {
                        activeSheet = .privacy
                    } label: {
                        SettingsRowLabel(title: "Privacy Policy")
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .aboutApp:
                    SimpleInfoSheet(
                        title: "About Sinced",
                        bodyText: "Sinced is a simple way to keep the moments that matter visible. Add an event, track the time since it started, and check in with your progress whenever you need to.",
                        imageName: nil,
                        actions: []
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                case .aboutDeveloper:
                    DeveloperInfoSheet()
                        .presentationDetents([.height(340), .medium])
                        .presentationDragIndicator(.visible)
                case .privacy:
                    SimpleInfoSheet(
                        title: "Privacy Policy",
                        bodyText: "Privacy policy placeholder: Sinced will explain what data is stored on device, what information may be collected, and how your reminders and event data are handled. This can be replaced with the final policy later.",
                        imageName: nil,
                        actions: []
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showingNameEditor) {
                EditNameSheet(currentName: viewModel.userName) { newName in
                    viewModel.updateUserName(newName)
                }
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

private enum SettingsSheet: Identifiable {
    case aboutApp
    case aboutDeveloper
    case privacy

    var id: Int {
        switch self {
        case .aboutApp:
            return 0
        case .aboutDeveloper:
            return 1
        case .privacy:
            return 2
        }
    }
}

private struct NameSettingsRow: View {
    let name: String

    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.roundedBody)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "pencil")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
}

private struct SettingsRowLabel: View {
    let title: String
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.roundedBody)
                .foregroundColor(.primary)

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .contentShape(Rectangle())
    }
}

private struct EditNameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nameInput: String
    @FocusState private var isFocused: Bool

    let onSave: (String) -> Void

    init(currentName: String, onSave: @escaping (String) -> Void) {
        _nameInput = State(initialValue: currentName)
        self.onSave = onSave
    }

    private var trimmedName: String {
        nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Your name", text: $nameInput)
                    .font(.roundedBody)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .focused($isFocused)

                Button("Save") {
                    guard !trimmedName.isEmpty else { return }
                    onSave(trimmedName)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(trimmedName.isEmpty)
                .opacity(trimmedName.isEmpty ? 0.5 : 1)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isFocused = true
            }
        }
    }
}

private struct SimpleInfoSheet: View {
    let title: String
    let bodyText: String
    let imageName: String?
    let actions: [SheetAction]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }

                Text(title)
                    .font(.roundedTitle2)
                    .foregroundColor(.primary)

                Text(bodyText)
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(actions) { action in
                    if action.isPrimary {
                        Link(destination: action.url) {
                            Text(action.title)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Link(destination: action.url) {
                            Text(action.title)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SubtleButtonStyle())
                    }
                }
            }
            .padding(20)
        }
    }
}

private struct DeveloperInfoSheet: View {
    var body: some View {
        SimpleInfoSheet(
            title: "About Developer",
            bodyText: "Aditya Kolte is a product designer building thoughtful consumer experiences, and Sinced is one of those small Swift experiments made with a focus on clarity and feeling.",
            imageName: nil,
            actions: [
                SheetAction(title: "Visit Website", url: URL(string: "https://adityakolte.com/")!, isPrimary: true),
                SheetAction(title: "Open Twitter", url: URL(string: "https://x.com/adityakvlte")!, isPrimary: false)
            ]
        )
    }
}

private struct SheetAction: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
    let isPrimary: Bool
}

private struct SubtleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.roundedHeadline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(AppMotion.spring(reduceMotion: reduceMotion, response: 0.25), value: configuration.isPressed)
    }
}

private struct NotificationSettingsView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false

    private var eventsWithNotifications: [SinceEvent] {
        viewModel.events.filter { $0.reminderSettings.isEnabled }
    }

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { notificationManager.notificationsEnabled },
                    set: handleGlobalNotificationsToggle
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allow notifications")
                            .font(.roundedBody)
                            .foregroundColor(.primary)

                        Text("Turn this off to dismiss all Sinced notifications.")
                            .font(.roundedCaption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.primaryBlue)

                if notificationManager.authorizationStatus == .denied {
                    Button("Open System Settings") {
                        notificationManager.openSettings()
                    }
                    .foregroundColor(.primaryBlue)
                }
            }

            Section("Event notifications") {
                if eventsWithNotifications.isEmpty {
                    Text("No event reminders are turned on right now.")
                        .font(.roundedBody)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(eventsWithNotifications) { event in
                        Toggle(isOn: Binding(
                            get: { isReminderEnabled(for: event) },
                            set: { isEnabled in
                                updateReminder(for: event, isEnabled: isEnabled)
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.roundedBody)
                                    .foregroundColor(.primary)

                                Text(reminderDescription(for: event))
                                    .font(.roundedCaption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(.primaryBlue)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                notificationManager.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive Sinced reminders, please enable notifications in Settings.")
        }
    }

    private func handleGlobalNotificationsToggle(_ isEnabled: Bool) {
        HapticManager.shared.light()

        guard isEnabled else {
            notificationManager.setNotificationsEnabled(false, events: viewModel.events)
            return
        }

        switch notificationManager.authorizationStatus {
        case .notDetermined:
            notificationManager.requestAuthorization { granted in
                if granted {
                    notificationManager.setNotificationsEnabled(true, events: viewModel.events)
                }
            }
        case .denied:
            showingPermissionAlert = true
        case .authorized, .provisional, .ephemeral:
            notificationManager.setNotificationsEnabled(true, events: viewModel.events)
        @unknown default:
            notificationManager.setNotificationsEnabled(true, events: viewModel.events)
        }
    }

    private func isReminderEnabled(for event: SinceEvent) -> Bool {
        viewModel.events.first(where: { $0.id == event.id })?.reminderSettings.isEnabled ?? false
    }

    private func updateReminder(for event: SinceEvent, isEnabled: Bool) {
        guard let currentEvent = viewModel.events.first(where: { $0.id == event.id }) else { return }

        var updatedEvent = currentEvent
        updatedEvent.reminderSettings.isEnabled = isEnabled
        viewModel.updateEvent(updatedEvent)
        HapticManager.shared.selection()
    }

    private func reminderDescription(for event: SinceEvent) -> String {
        switch event.reminderSettings.reminderType {
        case .daily:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Daily at \(formatter.string(from: event.reminderSettings.dailyReminderTime))"
        case .weekly:
            let days = event.reminderSettings.weeklyDays
                .sorted { $0.rawValue < $1.rawValue }
                .map(\.shortName)
                .joined(separator: ", ")
            return "Weekly on \(days)"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(EventViewModel())
}


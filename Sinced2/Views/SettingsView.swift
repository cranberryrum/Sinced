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
    @Environment(\.openURL) private var openURL
    
    private static let privacyPolicyURL = URL(string: "https://github.com/cranberryrum/Sinced/blob/main/PRIVACY.md")!
    private static let supportEmailURL = URL(string: "mailto:adityakoltedes@gmail.com?subject=Sinced")!
    private static let supportPageURL = URL(string: "https://github.com/cranberryrum/Sinced/blob/main/SUPPORT.md")!

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
                        SettingsRowLabel(icon: "info.circle", title: "About Sinced")
                    }
                    .buttonStyle(.plain)

                    Button {
                        activeSheet = .widgetGuide
                    } label: {
                        SettingsRowLabel(icon: "square.grid.2x2", title: "Add a Widget")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        NotificationSettingsView()
                            .environmentObject(viewModel)
                    } label: {
                        SettingsRowLabel(icon: "bell", title: "Notifications", showsChevron: false)
                    }

                    NavigationLink {
                        ArchivedEventsView()
                            .environmentObject(viewModel)
                    } label: {
                        SettingsRowLabel(
                            icon: "archivebox",
                            title: "Archived Events",
                            value: viewModel.archivedEvents.isEmpty ? nil : "\(viewModel.archivedEvents.count)",
                            showsChevron: false
                        )
                    }

                    Button {
                        activeSheet = .aboutDeveloper
                    } label: {
                        SettingsRowLabel(icon: "hammer", title: "About Developer")
                    }
                    .buttonStyle(.plain)
                }

                Section {
                    Button {
                        openURL(AppStoreLinks.writeReview)
                    } label: {
                        SettingsRowLabel(icon: "star", title: "Rate Sinced")
                    }
                    .buttonStyle(.plain)

                    ShareLink(
                        item: AppStoreLinks.listing,
                        message: Text("I use Sinced to count the days since the moments that matter. No account, no ads.")
                    ) {
                        SettingsRowLabel(icon: "heart", title: "Tell a Friend")
                    }
                    .buttonStyle(.plain)
                } footer: {
                    // The small print, kept quiet at the very bottom
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Button("Privacy Policy") { openURL(Self.privacyPolicyURL) }
                            Text("·").accessibilityHidden(true)
                            Button("Support") {
                                // No mail app set up → open the support page instead
                                openURL(Self.supportEmailURL) { accepted in
                                    if !accepted { openURL(Self.supportPageURL) }
                                }
                            }
                        }
                        .font(.roundedFootnote)
                        .foregroundColor(.secondary)
                        .buttonStyle(.plain)

                        Text(AppVersion.label)
                            .font(.roundedCaption)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 28)
                }
            }
            .listStyle(.insetGrouped)
            .grainListBackground()
            .navigationTitle("Settings")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .aboutApp:
                    AboutSincedSheet()
                case .aboutDeveloper:
                    DeveloperSheet()
                case .widgetGuide:
                    WidgetGuideView(event: viewModel.events.first)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showingNameEditor) {
                EditNameSheet(currentName: viewModel.userName) { newName in
                    viewModel.updateUserName(newName)
                }
            }
        }
    }
}

private enum SettingsSheet: Identifiable {
    case aboutApp
    case aboutDeveloper
    case widgetGuide

    var id: Int {
        switch self {
        case .aboutApp:
            return 0
        case .aboutDeveloper:
            return 1
        case .widgetGuide:
            return 2
        }
    }
}

/// Leading SF Symbol for a settings row: one size, weight and width so
/// every title lines up
private struct SettingsIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .symbolVariant(.fill)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Color(.systemGray))
            .frame(width: 22)
            .accessibilityHidden(true)
    }
}

private struct NameSettingsRow: View {
    let name: String

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: "person")

            Text(name)
                .font(.roundedBody)
                .foregroundColor(.primary)
                // Separators start under the title, not the icon
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }

            Spacer()

            Image(systemName: "pencil")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
}

private struct SettingsRowLabel: View {
    let icon: String
    let title: String
    var value: String? = nil
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon)

            Text(title)
                .font(.roundedBody)
                .foregroundColor(.primary)
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }

            Spacer()

            if let value {
                Text(value)
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText())
            }

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
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your name")
                    .font(.rounded(22, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Some reminders use it, so they feel written for you.")
                    .font(.roundedSubheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .sheetEntrance(0)

            TextField("Your name", text: $nameInput)
                .font(.roundedBody)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AddEventBottomSheet.fieldFill)
                )
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(save)
                .sheetEntrance(1)

            Button("Save", action: save)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(trimmedName.isEmpty)
                .opacity(trimmedName.isEmpty ? 0.5 : 1)
                .animation(.easeOut(duration: 0.2), value: trimmedName.isEmpty)
                .sheetEntrance(2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .sheetHeightPart()
        .frame(maxHeight: .infinity, alignment: .top)
        .fittedSheet(estimate: 240)
        .onAppear {
            isFocused = true
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        HapticManager.shared.success()
        onSave(trimmedName)
        dismiss()
    }
}

private struct NotificationSettingsView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var showingPermissionAlert = false
    /// Events listed on this screen. Captured on appear so a row doesn't
    /// vanish the moment its toggle is switched off.
    @State private var listedEventIds: [UUID] = []

    private var eventsWithNotifications: [SinceEvent] {
        viewModel.events.filter { listedEventIds.contains($0.id) }
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
                .tint(.primaryGreen)

                if notificationManager.authorizationStatus == .denied {
                    Button("Open System Settings") {
                        notificationManager.openSettings()
                    }
                    .foregroundColor(.primaryGreen)
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
                        .tint(.primaryGreen)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .grainListBackground()
        .onAppear {
            listedEventIds = viewModel.events
                .filter { $0.reminderSettings.isEnabled }
                .map(\.id)
        }
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
            notificationManager.setNotificationsEnabled(false)
            return
        }

        switch notificationManager.authorizationStatus {
        case .notDetermined:
            notificationManager.requestAuthorization { granted in
                if granted {
                    notificationManager.setNotificationsEnabled(true)
                }
            }
        case .denied:
            showingPermissionAlert = true
        case .authorized, .provisional, .ephemeral:
            notificationManager.setNotificationsEnabled(true)
        @unknown default:
            notificationManager.setNotificationsEnabled(true)
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


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
    @ObservedObject private var notifications = NotificationManager.shared
    @State private var activeSheet: SettingsSheet?
    @State private var showingNameEditor = false
    @Environment(\.openURL) private var openURL

    private static let privacyPolicyURL = URL(string: "https://adityakolte.com/sinced/privacy")!
    private static let supportEmailURL = URL(string: "mailto:adityakoltedes@gmail.com?subject=Sinced")!
    private static let supportPageURL = URL(string: "https://adityakolte.com/sinced/support")!

    private var firstName: String {
        viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ").first.map(String.init) ?? ""
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    header
                        .padding(.bottom, 10)

                    SettingsCard {
                        Button { showingNameEditor = true } label: {
                            SettingsRow(icon: "person", title: "Your name", value: firstName.isEmpty ? "Add" : viewModel.userName)
                        }
                        DashedRule()
                        NavigationLink {
                            NotificationSettingsView().environmentObject(viewModel)
                        } label: {
                            SettingsRow(icon: "bell", title: "Notifications", value: notifications.notificationsEnabled ? "On" : "Off")
                        }
                        DashedRule()
                        NavigationLink {
                            ArchivedEventsView().environmentObject(viewModel)
                        } label: {
                            SettingsRow(icon: "archivebox", title: "Archived", value: viewModel.archivedEvents.isEmpty ? "None" : "\(viewModel.archivedEvents.count)")
                        }
                        DashedRule()
                        Button { activeSheet = .widgetGuide } label: {
                            SettingsRow(icon: "square.grid.2x2", title: "Add a widget")
                        }
                    }

                    TipJarCard()

                    SettingsCard {
                        Button { openURL(AppStoreLinks.writeReview) } label: {
                            SettingsRow(icon: "star", title: "Rate Sinced")
                        }
                        DashedRule()
                        ShareLink(
                            item: AppStoreLinks.listing,
                            message: Text("I use Sinced to count the days since the moments that matter. No account, no ads.")
                        ) {
                            SettingsRow(icon: "heart", title: "Tell a friend")
                        }
                    }

                    SettingsCard {
                        Button { activeSheet = .aboutApp } label: {
                            SettingsRow(icon: "info.circle", title: "About Sinced")
                        }
                        DashedRule()
                        Button { activeSheet = .aboutDeveloper } label: {
                            SettingsRow(icon: "hammer", title: "Who made this")
                        }
                    }

                    footer
                        .padding(.top, 22)
                }
                .buttonStyle(SettingsRowButtonStyle())
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 130)
            }
            .background(GrainBackground().ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .aboutApp:
                    AboutSincedSheet()
                case .aboutDeveloper:
                    DeveloperSheet()
                case .widgetGuide:
                    WidgetGuideView(event: viewModel.events.first)
                        .presentationDetents([.large])
                        .deviceCornerSheet()
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

    /// "Settings", then a line in the home's voice
    private var header: some View {
        let count = viewModel.events.count
        let bold = { (s: String) in Text(s).font(.allo(25, weight: .semibold)).foregroundColor(CardText.word) }
        return VStack(alignment: .leading, spacing: 2) {
            Text("Settings").font(.allo(18, weight: .medium)).foregroundStyle(CardText.label)
            (Text(firstName.isEmpty ? "Hi. " : "Hi, ") + (firstName.isEmpty ? Text("") : bold(firstName) + Text(". "))
             + Text(count == 0 ? "Nothing counting yet." : "") + (count == 0 ? Text("") : bold("\(count) \(count == 1 ? "counter" : "counters")") + Text(" going.")))
                .font(.allo(25, weight: .medium))
                .foregroundStyle(CardText.connector)
        }
        .padding(.horizontal, 6)
        .accessibilityElement(children: .combine)
    }

    /// The small print, kept quiet at the very bottom
    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Button("Privacy") { openURL(Self.privacyPolicyURL) }
                Text("·").accessibilityHidden(true)
                Button("Support") {
                    // No mail app set up → open the support page instead
                    openURL(Self.supportEmailURL) { accepted in
                        if !accepted { openURL(Self.supportPageURL) }
                    }
                }
            }
            .font(.allo(14, weight: .medium))
            .foregroundStyle(CardText.label)
            .buttonStyle(.plain)

            Text(AppVersion.label)
                .font(.allo(12))
                .foregroundStyle(CardText.connector)
        }
        .frame(maxWidth: .infinity)
    }
}

private enum SettingsSheet: Identifiable {
    case aboutApp
    case aboutDeveloper
    case widgetGuide

    var id: Int {
        switch self {
        case .aboutApp: return 0
        case .aboutDeveloper: return 1
        case .widgetGuide: return 2
        }
    }
}

/// A white card of rows, like the event page's actions
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
    }
}

/// Icon, title, a quiet value and a chevron, in Allo
struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(CardText.word)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(title)
                .font(.allo(16, weight: .medium))
                .foregroundStyle(CardText.word)
            Spacer(minLength: 12)
            if let value {
                Text(value)
                    .font(.allo(16))
                    .foregroundStyle(CardText.label)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CardText.connector.opacity(0.8))
                .accessibilityHidden(true)
        }
        .frame(height: 56)
        .contentShape(Rectangle())
    }
}

/// A settings page's title: a small label, then a line in the home's voice
struct SettingsPageHeader: View {
    let label: String
    let line: Text
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.allo(18, weight: .medium)).foregroundStyle(CardText.label)
            line.font(.allo(25, weight: .medium)).foregroundStyle(CardText.connector)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// The bold part of a header line
    static func bold(_ s: String) -> Text { Text(s).font(.allo(25, weight: .semibold)).foregroundColor(CardText.word) }
}

/// Rows dim a touch and shrink slightly under the finger
struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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

    private var headerLine: Text {
        let on = notificationManager.notificationsEnabled
        let count = viewModel.events.filter { $0.reminderSettings.isEnabled }.count
        guard on else { return Text("Reminders are ") + SettingsPageHeader.bold("off") + Text(".") }
        if count == 0 { return Text("No counter is reminding you yet.") }
        return SettingsPageHeader.bold("\(count) \(count == 1 ? "counter" : "counters")") + Text(count == 1 ? " reminds you." : " remind you.")
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsPageHeader(label: "Notifications", line: headerLine)
                    .padding(.bottom, 10)

                SettingsCard {
                    Toggle(isOn: Binding(
                        get: { notificationManager.notificationsEnabled },
                        set: handleGlobalNotificationsToggle
                    )) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Allow notifications").font(.allo(16, weight: .medium)).foregroundStyle(CardText.word)
                            Text("Off pauses every reminder from Sinced.").font(.allo(13)).foregroundStyle(CardText.label)
                        }
                    }
                    .tint(.primaryGreen)
                    .padding(.vertical, 14)

                    if notificationManager.authorizationStatus == .denied {
                        DashedRule()
                        Button { notificationManager.openSettings() } label: {
                            SettingsRow(icon: "gear", title: "Turn on in iOS Settings")
                        }
                        .buttonStyle(SettingsRowButtonStyle())
                    }
                }

                Text("Counters with reminders")
                    .font(.allo(14, weight: .medium))
                    .foregroundStyle(CardText.label)
                    .padding(.horizontal, 6)
                    .padding(.top, 12)

                SettingsCard {
                    if eventsWithNotifications.isEmpty {
                        Text("None yet. Open a counter and tap “Remind me” to set one up.")
                            .font(.allo(15))
                            .foregroundStyle(CardText.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 18)
                    } else {
                        ForEach(Array(eventsWithNotifications.enumerated()), id: \.element.id) { i, event in
                            if i > 0 { DashedRule() }
                            Toggle(isOn: Binding(
                                get: { isReminderEnabled(for: event) },
                                set: { updateReminder(for: event, isEnabled: $0) }
                            )) {
                                HStack(spacing: 12) {
                                    EventThumbnail(event: event, size: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title).font(.allo(16, weight: .medium)).foregroundStyle(CardText.word).lineLimit(1)
                                        Text(reminderDescription(for: event)).font(.allo(13)).foregroundStyle(CardText.label).lineLimit(1)
                                    }
                                }
                            }
                            .tint(.primaryGreen)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 130)
        }
        .background(GrainBackground().ignoresSafeArea())
        .onAppear {
            listedEventIds = viewModel.events
                .filter { $0.reminderSettings.isEnabled }
                .map(\.id)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notifications are off", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                notificationManager.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To get reminders, turn on notifications for Sinced in Settings.")
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
            return "Every day at \(formatter.string(from: event.reminderSettings.dailyReminderTime).lowercased())"
        case .weekly:
            let days = event.reminderSettings.weeklyDays
                .sorted { $0.rawValue < $1.rawValue }
                .map(\.shortName)
                .joined(separator: ", ")
            return "On \(days)"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(EventViewModel())
}


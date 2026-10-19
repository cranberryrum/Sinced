//
//  Sinced2App.swift
//  Sinced2
//
//  Main app entry point
//

import SwiftUI
import UserNotifications

@main
struct Sinced2App: App {
    @StateObject private var viewModel = EventViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Fix any existing large images for widgets
        StorageManager.shared.fixLargeImages()
        
        // Initialize notification manager (sets up delegate)
        _ = NotificationManager.shared
        
        // Widget, Control Center and Siri resets can happen while the app is open
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .eventsChangedExternally, object: nil)
                }
            },
            ExternalEventChanges.darwinName as CFString,
            nil,
            .deliverImmediately
        )
    }
    
    var body: some Scene {
        WindowGroup {
            if !viewModel.hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(viewModel)
                    .preferredColorScheme(.light)
            } else {
                MainTabView()
                    .environmentObject(viewModel)
                    .preferredColorScheme(.light)
                    .onReceive(NotificationCenter.default.publisher(for: .didTapEventNotification)) { notification in
                        if let eventId = notification.userInfo?["eventId"] as? UUID {
                            viewModel.openEvent(id: eventId)
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .eventsChangedExternally)) { _ in
                        viewModel.loadEvents()
                        viewModel.refreshAllNotifications()
                    }
                    // Widget taps open sinced://event/<id>
                    .onOpenURL { url in
                        guard url.scheme == "sinced", url.host == "event",
                              let eventId = UUID(uuidString: url.lastPathComponent) else { return }
                        viewModel.openEvent(id: eventId)
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Pick up resets made from widgets, controls or Siri
                viewModel.loadEvents()
                // Pick up permission changes made in iOS Settings
                NotificationManager.shared.checkAuthorizationStatus()
                // Reminders are scheduled a limited number of days ahead with
                // pre-computed day counts, so top them up whenever the app is opened
                viewModel.refreshAllNotifications()
            }
        }
    }
}

extension Notification.Name {
    /// Posted when an intent outside the app's UI changed events
    static let eventsChangedExternally = Notification.Name("eventsChangedExternally")
}

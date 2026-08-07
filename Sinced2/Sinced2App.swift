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
    @State private var selectedEventId: UUID?
    @State private var showEventDetail = false
    @Namespace private var animation
    
    init() {
        // Fix any existing large images for widgets
        StorageManager.shared.fixLargeImages()
        
        // Initialize notification manager (sets up delegate)
        _ = NotificationManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !viewModel.hasCompletedOnboarding {
                    OnboardingView()
                        .environmentObject(viewModel)
                } else {
                    MainTabView()
                        .environmentObject(viewModel)
                        .onReceive(NotificationCenter.default.publisher(for: .didTapEventNotification)) { notification in
                            if let eventId = notification.userInfo?["eventId"] as? UUID {
                                selectedEventId = eventId
                                showEventDetail = true
                            }
                        }
                        .sheet(isPresented: $showEventDetail) {
                            if let eventId = selectedEventId,
                               let event = viewModel.events.first(where: { $0.id == eventId }) {
                                EventDetailView(event: event, viewModel: viewModel)
                            }
                        }
                }
            }
            .tint(.primaryBlue)
        }
    }
}

//
//  MainTabView.swift
//  Sinced2
//
//  Created by AI on 2026-01-18.
//

import SwiftUI
import Combine

enum Tab {
    case home
    case settings
}

struct MainTabView: View {
    @EnvironmentObject var viewModel: EventViewModel
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EventListView()
                .environmentObject(viewModel)
                .tag(Tab.home)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(viewModel.$eventToOpen.compactMap { $0 }) { _ in
            // Events open from the home tab
            selectedTab = .home
        }
        // Launching straight from a widget is a cold start, which doesn't
        // count as coming to the foreground, so ask here too
        .task {
            viewModel.checkOutsideResets()
            viewModel.checkMilestones()
        }
        .onReceive(WidgetGuideRouter.shared.$isRequested.filter { $0 }) { _ in
            // So does the widget guide
            selectedTab = .home
        }
        // Asks about a reset made from a widget, Control Center or Siri
        .outsideResetReveal(
            viewModel.outsideReset,
            // After the card's ring, when a widget tap brought them here
            after: viewModel.focusedEventID == nil ? .seconds(0.35) : .seconds(1.1),
            onUndo: viewModel.undoOutsideReset,
            onTimeout: viewModel.dismissOutsideReset
        )
        // A milestone or goal reached since the app last looked
        .overlay {
            if let celebration = viewModel.celebration {
                MilestoneCelebrationView(
                    celebration: celebration,
                    event: viewModel.events.first { $0.id == celebration.eventID },
                    onClose: viewModel.closeCelebration,
                    onSetNextGoal: viewModel.setNextGoal
                )
                // Fades in; leaves a touch smaller, quicker than it came
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 0.98))
                ))
                .zIndex(10)
            }
        }
    }
}

struct TabButton: View {
    let tab: Tab
    @Binding var currentTab: Tab
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                currentTab = tab
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: currentTab == tab ? .bold : .medium))
                
                if currentTab == tab {
                    Text(title)
                        .font(.allo(14, weight: .semibold))
                }
            }
            .foregroundColor(currentTab == tab ? .primaryGreen : .secondary)
            .padding(.horizontal, currentTab == tab ? 16 : 12)
            .frame(height: 44)
            .background(currentTab == tab ? Color.primaryGreen.opacity(0.1) : Color.clear)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(EventViewModel())
}


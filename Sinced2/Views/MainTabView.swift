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
    @StateObject private var toastManager = ToastManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
        .task { viewModel.checkOutsideResets() }
        .onReceive(WidgetGuideRouter.shared.$isRequested.filter { $0 }) { _ in
            // So does the widget guide
            selectedTab = .home
        }
        // Asks about a reset made from a widget, Control Center or Siri
        .overlay(alignment: .bottom) {
            if let offer = viewModel.outsideReset {
                OutsideResetBanner(
                    offer: offer,
                    onUndo: viewModel.undoOutsideReset,
                    onDismiss: viewModel.dismissOutsideReset
                )
                .padding(.horizontal, 16)
                // Clear of the tab bar
                .padding(.bottom, 84)
                .transition(.banner(reduceMotion: reduceMotion))
                .id(offer.eventID)
            }
        }
        .toast(
            isShowing: $toastManager.isShowing,
            message: toastManager.message,
            icon: toastManager.icon,
            style: toastManager.style
        )
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
                        .font(.system(size: 14, weight: .semibold))
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


//
//  MainTabView.swift
//  Sinced2
//
//  Created by AI on 2026-01-18.
//

import SwiftUI

enum Tab {
    case home
    case settings
}

struct MainTabView: View {
    @EnvironmentObject var viewModel: EventViewModel
    @State private var selectedTab: Tab = .home
    @StateObject private var toastManager = ToastManager.shared
    
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            withAnimation(AppMotion.spring(reduceMotion: reduceMotion, response: 0.4)) {
                currentTab = tab
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: currentTab == tab ? .bold : .medium))
                
                if currentTab == tab {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(currentTab == tab ? .primaryBlue : .secondary)
            .padding(.horizontal, currentTab == tab ? 16 : 12)
            .frame(height: 44)
            .background(currentTab == tab ? Color.primaryBlue.opacity(0.1) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(FluidPressButtonStyle())
    }
}

#Preview {
    MainTabView()
        .environmentObject(EventViewModel())
}


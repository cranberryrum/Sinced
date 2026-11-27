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
    @ObservedObject private var addFlow = AddFlow.shared
    @ObservedObject private var support = SupportPrompter.shared

    private var firstName: String {
        viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ").first.map(String.init) ?? ""
    }

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
        // Now and then, after a milestone or a share: a gentle ask for a tip
        .sheet(item: $support.ask, onDismiss: support.askDidClose) { ask in
            SupportAskSheet(ask: ask, firstName: firstName)
        }
        .background {
            // The thank-you after tipping from that ask, once it has closed
            Color.clear.sheet(item: $support.thanks) { thanks in
                TipThankYouSheet(thanks: thanks, firstName: firstName)
            }
        }
        .onChange(of: selectedTab, initial: true) { _, tab in
            support.homeVisible = tab == .home
        }
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
        // Adding an event: a card over the tab bar that grows out of the + tile
        .overlay {
            if addFlow.isPresented {
                AddEventOverlay(viewModel: viewModel)
            }
        }
        // A milestone or goal reached since the app last looked: home dims and
        // that card counts up to it, then confetti
        .overlay {
            if viewModel.spotlightShowing, let celebration = viewModel.celebration,
               let event = viewModel.events.first(where: { $0.id == celebration.eventID }) {
                MilestoneSpotlight(
                    celebration: celebration,
                    event: event,
                    cardFrame: addFlow.cardFrames[event.id],
                    onOpen: viewModel.openCelebratedEvent,
                    onDismiss: viewModel.closeCelebration
                )
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


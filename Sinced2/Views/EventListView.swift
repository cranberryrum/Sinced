//
//  EventListView.swift
//  Sinced2
//
//  Created by AI on 2026-01-18.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

struct EventListView: View {
    @EnvironmentObject var viewModel: EventViewModel
    @State private var selectedEvent: SinceEvent?
    @State private var showingCreateEvent = false
    @State private var draggingEvent: SinceEvent?
    @State private var eventPendingDelete: SinceEvent?
    @State private var eventBeingEdited: SinceEvent?
    @State private var showingWidgetGuide = false
    @ObservedObject private var widgetStatus = WidgetStatus.shared
    @ObservedObject private var guideRouter = WidgetGuideRouter.shared
    @AppStorage("widgetGuide.cardDismissed") private var guideCardDismissed = false
    /// The add sheet opens by itself once, straight after onboarding
    @AppStorage("firstRun.addSheetOffered") private var addSheetOffered = false
    /// The card currently showing its "look here" ring
    @State private var ringedEventID: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Only once iOS has confirmed there's no widget, so it never flashes for people who have one
    private var showsGuideCard: Bool {
        widgetStatus.hasWidget == false && !guideCardDismissed && !viewModel.events.isEmpty
    }
    
    private var isEmptyState: Bool {
        viewModel.events.isEmpty
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
            let cardHeight = (geometry.size.width - (16 * 3)) / 2
            
            ZStack {
                // Background
                GrainBackground()
                
                if isEmptyState {
                    VStack {
                        Spacer()
                        
                        EmptyEventsView(
                            title: "no events yet",
                            subtitle: "track your days since events"
                        )
                        
                        Button("Add event") {
                            HapticManager.shared.medium()
                            showingCreateEvent = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        Spacer()
                    }
                } else {
                    // Large Cards with Vertical Scroll
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            if showsGuideCard, let first = viewModel.events.first {
                                WidgetGuideCard(
                                    event: first,
                                    onOpen: {
                                        HapticManager.shared.light()
                                        showingWidgetGuide = true
                                    },
                                    onDismiss: {
                                        HapticManager.shared.light()
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            guideCardDismissed = true
                                        }
                                    }
                                )
                                .transition(
                                    reduceMotion
                                        ? .opacity
                                        : .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
                                )
                            }

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.events) { event in
                                    HomeEventCardView(event: event)
                                        .frame(height: cardHeight)
                                        // Lands as the add sheet clears; leaves the same way
                                        .transition(cardTransition)
                                        // Where to look, after a widget tap
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                                .strokeBorder(Color.black.opacity(0.85), lineWidth: 2.5)
                                                .padding(-5)
                                                .opacity(ringedEventID == event.id ? 1 : 0)
                                                .allowsHitTesting(false)
                                        }
                                        .contentShape(Rectangle())
                                        .scaleEffect(draggingEvent?.id == event.id ? 0.96 : 1.0)
                                        .zIndex(draggingEvent?.id == event.id ? 1 : 0)
                                        .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.86), value: draggingEvent?.id)
                                        .onTapGesture {
                                            HapticManager.shared.light()
                                            selectedEvent = event
                                        }
                                        .onDrag {
                                            draggingEvent = event
                                            HapticManager.shared.light()
                                            return NSItemProvider(object: event.id.uuidString as NSString)
                                        } preview: {
                                            HomeEventCardView(event: event)
                                                .frame(height: cardHeight)
                                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                                .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
                                                .background(Color.clear)
                                        }
                                        .onDrop(
                                            of: [UTType.text],
                                            delegate: EventReorderDropDelegate(
                                                targetEvent: event,
                                                viewModel: viewModel,
                                                draggingEvent: $draggingEvent
                                            )
                                        )
                                        .contextMenu {
                                            Button {
                                                eventBeingEdited = event
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                        
                                            Button(role: .destructive) {
                                                eventPendingDelete = event
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        
                                            Button {
                                                viewModel.archiveEvent(event)
                                            } label: {
                                                Label("Archive", systemImage: "archivebox")
                                            }
                                        }
                                }
                            
                                Button {
                                    HapticManager.shared.medium()
                                    showingCreateEvent = true
                                } label: {
                                    AddEventPlaceholderCard()
                                        .frame(height: cardHeight)
                                }
                                .buttonStyle(AddPlaceholderButtonStyle())
                            }
                            .animation(cardCountAnimation, value: viewModel.events.count)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, geometry.safeAreaInsets.top + 16)
                        .padding(.bottom, 120) // Space for bottom nav
                    }
                    .ignoresSafeArea()
                    // A drop outside any card would otherwise leave the dragged card shrunk
                    .onDrop(of: [UTType.text], isTargeted: nil) { _ in
                        draggingEvent = nil
                        return false
                    }
                }

                // Top gradient fade
                VStack {
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 16)
                        .background(
                            // Same grainy background, faded, so the grain runs
                            // unbroken under the status bar
                            GrainBackground()
                                .mask(
                                    LinearGradient(
                                        colors: [.black, .black.opacity(0.9), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .ignoresSafeArea()
                                )
                        )
                    
                    Spacer()
                }
                
            }
            .confirmationDialog(
                "Delete \(eventPendingDelete?.title ?? "event")?",
                isPresented: Binding(
                    get: { eventPendingDelete != nil },
                    set: { if !$0 { eventPendingDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let event = eventPendingDelete {
                        viewModel.deleteEvent(event)
                        showSuccessToast(title: event.title)
                    }
                    eventPendingDelete = nil
                }
            } message: {
                Text("This removes the event and its history.")
            }
            // Opened from a notification or widget tap
            .onReceive(viewModel.$eventToOpen.compactMap { $0 }) { event in
                showingCreateEvent = false
                selectedEvent = event
                viewModel.eventToOpen = nil
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(
                    event: event,
                    viewModel: viewModel,
                    onDeleteSuccess: { title in
                        showSuccessToast(title: title)
                    }
                )
            }
            .sheet(item: $eventBeingEdited) { event in
                AddEventBottomSheet(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { eventBeingEdited != nil },
                        set: { if !$0 { eventBeingEdited = nil } }
                    ),
                    editingEvent: event
                )
            }
            .sheet(isPresented: $showingCreateEvent, onDismiss: offerGuideAfterFirstEvent) {
                AddEventBottomSheet(viewModel: viewModel, isPresented: $showingCreateEvent)
            }
            .sheet(isPresented: $showingWidgetGuide) {
                WidgetGuideView(event: viewModel.events.first)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .animation(.spring(duration: 0.4, bounce: 0), value: showsGuideCard)
            .onAppear(perform: openRequestedGuide)
            // A widget tap landed here: ring the card once, then let the
            // screen lift to ask about the reset
            .task(id: viewModel.focusedEventID) {
                guard let id = viewModel.focusedEventID else { return }
                selectedEvent = nil
                try? await Task.sleep(for: .seconds(0.35))
                withAnimation(.easeOut(duration: 0.24)) { ringedEventID = id }
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.easeOut(duration: 0.24)) { ringedEventID = nil }
                viewModel.focusedEventID = nil
            }
            .task {
                // Someone who's just finished onboarding has nothing to look
                // at yet, so go straight to adding their first event
                guard !addSheetOffered, viewModel.events.isEmpty else { return }
                addSheetOffered = true
                // Let the home screen settle in first, so the sheet reads as
                // the next step rather than a pop-up
                try? await Task.sleep(for: .seconds(0.45))
                showingCreateEvent = true
            }
            .onChange(of: guideRouter.isRequested) { openRequestedGuide() }
        }
    }
    
    /// Nothing appears from nothing: just under full size, and faded
    private var cardTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95))
    }

    /// Cards coming and going. A short delay lets the sheet that caused it
    /// get out of the way first. Reordering keeps its own quicker spring,
    /// since it doesn't change the count.
    private var cardCountAnimation: Animation {
        (reduceMotion ? Animation.easeOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0))
            .delay(0.12)
    }

    /// Right after the first event is saved is when a widget makes the most sense
    private func offerGuideAfterFirstEvent() {
        guard viewModel.events.count == 1,
              !WidgetNudge.introShown,
              widgetStatus.hasWidget != true else { return }
        WidgetNudge.introShown = true
        // Let the new card land before the guide comes up over it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showingWidgetGuide = true
        }
    }

    /// From the reminder notification or a sinced://widget-guide link
    private func openRequestedGuide() {
        guard guideRouter.isRequested else { return }
        guideRouter.isRequested = false
        let wasShowingSomething = selectedEvent != nil || eventBeingEdited != nil || showingCreateEvent
        selectedEvent = nil
        eventBeingEdited = nil
        showingCreateEvent = false
        guard !showingWidgetGuide else { return }
        // A sheet can't open while another is still closing
        DispatchQueue.main.asyncAfter(deadline: .now() + (wasShowingSomething ? 0.5 : 0)) {
            showingWidgetGuide = true
        }
    }

    private func showSuccessToast(title: String) {
        ToastManager.shared.show(
            "\(title) deleted successfully",
            icon: "trash.fill",
            style: .deleteBanner,
            duration: 2.0
        )
    }
}

private struct AddEventPlaceholderCard: View {
    private let cornerRadius: CGFloat = 24
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    Color.black.opacity(0.18),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
            
            Image(systemName: "plus")
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(.black.opacity(0.85))
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct AddPlaceholderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

private struct EventReorderDropDelegate: DropDelegate {
    let targetEvent: SinceEvent
    let viewModel: EventViewModel
    @Binding var draggingEvent: SinceEvent?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let sourceEvent = draggingEvent,
              sourceEvent.id != targetEvent.id,
              let fromIndex = viewModel.events.firstIndex(where: { $0.id == sourceEvent.id }),
              let toIndex = viewModel.events.firstIndex(where: { $0.id == targetEvent.id }) else {
            self.draggingEvent = nil
            return false
        }

        withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.86)) {
            viewModel.moveEvent(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
        viewModel.persistActiveEventOrder()
        HapticManager.shared.medium()

        withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.86)) {
            draggingEvent = nil
        }
        return true
    }
}

/// Square home card built with the SVG themes from Assets
struct HomeEventCardView: View {
    let event: SinceEvent
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let cardCornerRadius: CGFloat = 24
    
    private var isImageCard: Bool {
        event.cardTheme == .custom && event.imageData != nil
    }
    
    var body: some View {
        ZStack(alignment: isImageCard ? .bottomLeading : .center) {
            backgroundView
            
            if isImageCard {
                LinearGradient(
                    colors: [.black.opacity(0.02), .black.opacity(0.36)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }

            textStack
        }
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if event.cardTheme == .custom,
           let imageData = event.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(0.18))
        } else {
            ZStack {
                event.cardTheme.backgroundColor
                
                if let squareAsset = event.cardTheme.squareSvgAssetName {
                    Image(squareAsset)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .clipped()
                } else if let assetName = event.cardTheme.svgAssetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .clipped()
                }
            }
        }
    }
    
    private func widgetTimeValue(for date: Date) -> String {
        let elapsed = max(0, date.timeIntervalSince(event.startedAt))
        
        switch event.widgetTimeUnit {
        case .hours:
            let hours = Int(elapsed / 3600)
            return "\(hours) \(hours == 1 ? "hour" : "hours")"
        case .days:
            let days = Int(elapsed / 86400)
            return "\(days) \(days == 1 ? "day" : "days")"
        case .months:
            let months = Int(elapsed / (86400 * 30))
            return "\(months) \(months == 1 ? "month" : "months")"
        case .years:
            let years = Int(elapsed / (86400 * 365))
            return "\(years) \(years == 1 ? "year" : "years")"
        }
    }

    @ViewBuilder
    private var textStack: some View {
        if isImageCard {
            VStack(alignment: .leading, spacing: 0) {
                timeLabel
                    .padding(.bottom, -2)

                subtitleLabel(multilineAlignment: .leading)
            }
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        } else {
            VStack(alignment: .center, spacing: 0) {
                timeLabel
                subtitleLabel(multilineAlignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(14)
        }
    }

    private var timeLabel: some View {
        Text(widgetTimeValue(for: currentTime).uppercased())
            .font(.custom("GeistMono-Medium", size: 20))
            // Digits roll when the count changes, e.g. after an undo
            .contentTransition(.numericText())
            .foregroundColor(.white)
            .tracking(-0.6)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 3)
    }

    private func subtitleLabel(multilineAlignment: TextAlignment) -> some View {
        Text("Since \(event.title)")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color.white.opacity(0.6))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(multilineAlignment)
    }
}

#Preview {
    EventListView()
        .environmentObject(EventViewModel())
}

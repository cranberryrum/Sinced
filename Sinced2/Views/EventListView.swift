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
    /// The add card, which grows out of the + tile above the tab bar
    @ObservedObject private var addFlow = AddFlow.shared
    @State private var draggingEvent: SinceEvent?
    @State private var showingWidgetGuide = false
    @State private var widgetGuidePlace: WidgetGuidePlace = .homeScreen
    /// The first counter's card and the nudge's widget spot, for the flight between them
    @State private var firstCardFrame: CGRect?
    @State private var nudgeSlotFrame: CGRect?
    @State private var nudgeFlight: NudgeFlight?
    @State private var nudgeWidgetPlaced = true
    @ObservedObject private var widgetStatus = WidgetStatus.shared
    @ObservedObject private var guideRouter = WidgetGuideRouter.shared
    @AppStorage("widgetGuide.cardDismissed") private var guideCardDismissed = false
    /// The add sheet opens by itself once, straight after onboarding
    /// The card currently showing its "look here" ring
    @State private var ringedEventID: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    /// The card zooms into its event page
    @Namespace private var cardZoom
    /// A hello for this visit: shows as the app opens, then tucks away
    @State private var homeVisible = false

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
                    EmptyHomeView(addFlow: addFlow)
                } else {
                    // Large Cards with Vertical Scroll
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            if showsGuideCard, let first = viewModel.events.first {
                                WidgetNudgeCard(
                                    event: first,
                                    widgetPlaced: nudgeWidgetPlaced,
                                    onReplay: playNudgeFlight,
                                    onSlotFrame: { nudgeSlotFrame = $0 },
                                    onLockScreen: {
                                        HapticManager.shared.light()
                                        widgetGuidePlace = .lockScreen
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
                                        .overlay(alignment: .topTrailing) {
                                            if event.isOnBestRun() {
                                                Text("★ Best")
                                                    .font(.allo(11, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 8)
                                                    .frame(height: 22)
                                                    .background(Capsule().fill(Color.black.opacity(0.28)))
                                                    .padding(10)
                                                    .accessibilityLabel("Longest run yet")
                                            }
                                        }
                                        .matchedTransitionSource(id: event.id, in: cardZoom) { source in
                                            source.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                        }
                                        // A soft lift off the page, part of the hairline look
                                        .shadow(color: .black.opacity(0.10), radius: 9, y: 8)
                                        // Lands as the add sheet clears; leaves the same way. A card
                                        // the add card is about to land on appears under it instead.
                                        .transition(addFlow.hiddenEventID == event.id ? .identity : cardTransition)
                                        // Hidden while the floating card is it: being edited, or about to be landed on
                                        .opacity(addFlow.hiddenEventID == event.id || (viewModel.spotlightShowing && viewModel.celebration?.eventID == event.id) ? 0 : 1)
                                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                                            addFlow.cardFrames[event.id] = frame
                                        }
                                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(HomeSpace.name)) } action: { frame in
                                            if event.id == viewModel.events.first?.id { firstCardFrame = frame }
                                        }
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
                                                // The long press can leave the card in its lifted drag size
                                                draggingEvent = nil
                                                // After the menu has let go of the card, so the edit card grows out of it
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                    addFlow.presentEdit(event)
                                                }
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                        
                                            Button(role: .destructive) {
                                                draggingEvent = nil
                                                // After the menu has let go of the card, so the card grows out of it
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                    addFlow.deleting = event
                                                }
                                            } label: {
                                                Label("Delete or archive", systemImage: "trash")
                                            }
                                        }
                                }
                            
                                Button {
                                    HapticManager.shared.medium()
                                    addFlow.present()
                                } label: {
                                    AddEventPlaceholderCard()
                                        .frame(height: cardHeight)
                                }
                                .buttonStyle(AddPlaceholderButtonStyle())
                                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { addFlow.sourceFrame = $0 }
                                // The add card is this tile while it's out
                                .opacity(addFlow.hidesSource ? 0 : 1)
                                .scaleEffect(addFlow.hidesSource ? 0.9 : 1)
                                .accessibilityLabel("Add an event")
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

                // The first counter flying into the nudge's widget spot
                if let flight = nudgeFlight, let first = viewModel.events.first {
                    let rect = flight.landed ? flight.to : flight.from
                    HomeEventCardView(event: first)
                        .frame(width: flight.from.width, height: flight.from.height)
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 8)
                        .scaleEffect(rect.width / flight.from.width)
                        .position(x: rect.midX, y: rect.midY)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .accessibilityHidden(true)
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
            .coordinateSpace(.named(HomeSpace.name))
            // Opened from a notification or widget tap
            .onReceive(viewModel.$eventToOpen.compactMap { $0 }) { event in
                addFlow.dismissImmediately()
                selectedEvent = event
                viewModel.eventToOpen = nil
            }
            .fullScreenCover(item: $selectedEvent) { event in
                EventPageView(
                    event: event,
                    viewModel: viewModel,
                    onDeleteSuccess: { title in
                        showSuccessToast(title: title)
                    }
                )
                .navigationTransition(.zoom(sourceID: event.id, in: cardZoom))
            }
            .onChange(of: viewModel.goalEditRequest) { _, id in
                guard let id, let event = viewModel.events.first(where: { $0.id == id }) else { return }
                viewModel.goalEditRequest = nil
                // An open event page has to slide away first, since the card sits under it
                let wait = selectedEvent == nil ? 0 : 0.5
                selectedEvent = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
                    addFlow.presentEdit(event, openGoal: true)
                }
            }
            .sheet(isPresented: $showingWidgetGuide) {
                WidgetGuideView(event: viewModel.events.first, place: widgetGuidePlace)
                    .presentationDetents([.large])
                    .deviceCornerSheet()
                    .presentationDragIndicator(.visible)
            }
            .animation(.spring(duration: 0.4, bounce: 0), value: showsGuideCard)
            .onAppear {
                addFlow.onFinish = offerGuideAfterFirstEvent
                openRequestedGuide()
            }
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
            .onChange(of: guideRouter.isRequested) { openRequestedGuide() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { trySpotlight() }
            }
            .onAppear { homeVisible = true; trySpotlight() }
            .onDisappear { homeVisible = false }
            .onChange(of: viewModel.celebration) { trySpotlight() }
            .onChange(of: selectedEvent) { _, open in if open == nil { trySpotlight() } }
            .onChange(of: addFlow.isPresented) { _, open in if !open { trySpotlight() } }
        }
    }
    
    /// Greets, holds for a moment, then tucks away so the grid rises into its place
    /// A milestone waiting to be celebrated plays on home, once home is
    /// actually what's on screen: not under an event page or the add card
    private func trySpotlight() {
        guard homeVisible, selectedEvent == nil, !addFlow.isPresented,
              viewModel.celebration != nil, !viewModel.spotlightShowing else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard homeVisible, selectedEvent == nil, !addFlow.isPresented, viewModel.celebration != nil else { return }
            viewModel.spotlightShowing = true
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
        // Let the new card land and the nudge settle, then the counter flies into its spot
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            playNudgeFlight()
        }
    }

    /// A copy of the first counter moves from its card into the nudge's widget spot
    private func playNudgeFlight() {
        guard nudgeFlight == nil, showsGuideCard else { return }
        guard !reduceMotion, let from = firstCardFrame, let to = nudgeSlotFrame else {
            // Reduce Motion: the widget just fades into its spot
            nudgeWidgetPlaced = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { nudgeWidgetPlaced = true }
            return
        }
        nudgeWidgetPlaced = false
        nudgeFlight = NudgeFlight(from: from, to: to)
        HapticManager.shared.light()
        DispatchQueue.main.async {
            // Moving across the screen: a strong ease-in-out
            withAnimation(.timingCurve(0.77, 0, 0.175, 1, duration: 0.7)) {
                nudgeFlight?.landed = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            // The copy has landed exactly on the spot: swap it for the widget in the
            // same frame, so the spot never blinks empty between the two
            var swap = Transaction()
            swap.disablesAnimations = true
            withTransaction(swap) {
                nudgeWidgetPlaced = true
                nudgeFlight = nil
            }
        }
    }

    /// From the reminder notification or a sinced://widget-guide link
    private func openRequestedGuide() {
        guard guideRouter.isRequested else { return }
        guideRouter.isRequested = false
        let wasShowingSomething = selectedEvent != nil || addFlow.isPresented
        selectedEvent = nil
        addFlow.dismissImmediately()
        guard !showingWidgetGuide else { return }
        widgetGuidePlace = .homeScreen
        // A sheet can't open while another is still closing
        DispatchQueue.main.asyncAfter(deadline: .now() + (wasShowingSomething ? 0.5 : 0)) {
            showingWidgetGuide = true
        }
    }

    private func showSuccessToast(title: String) {
        ToastManager.shared.show("Deleted “\(title)”", icon: "trash", kind: .destructive)
    }
}

/// The first counter on its way into the widget nudge
private struct NudgeFlight {
    let from: CGRect
    let to: CGRect
    var landed = false
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
    /// Days to show instead of the live count, while a milestone counts up
    var countOverride: Int? = nil
    /// Words to show instead of "Since …"
    var subtitleOverride: String? = nil
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let cardCornerRadius: CGFloat = 24
    
    private var isImageCard: Bool {
        event.cardTheme == .custom && event.imageData != nil
    }
    
    private var styled: Bool { event.cardStyle != .classic }

    var body: some View {
        ZStack(alignment: isImageCard ? .bottomLeading : .center) {
            backgroundView

            if styled {
                if isImageCard {
                    // Text runs across the whole photo in these layouts
                    Color.black.opacity(0.2).allowsHitTesting(false)
                }
                StyledCardFace(
                    event: event,
                    style: event.cardStyle,
                    count: countOverride ?? countParts(for: currentTime).value,
                    subtitleOverride: subtitleOverride,
                    now: currentTime
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(widgetTimeValue(for: currentTime)) since \(event.title)")
            } else {
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
        }
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .cardEdge(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
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

                // The styled layouts sit on the flat colour; the type is the graphic
                if styled {
                    EmptyView()
                } else if let squareAsset = event.cardTheme.squareSvgAssetName {
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

    /// "23" and "d": a big number with a small unit after it
    private func countParts(for date: Date) -> (value: Int, unit: String) {
        let elapsed = max(0, date.timeIntervalSince(event.startedAt))
        switch event.widgetTimeUnit {
        case .hours: return (Int(elapsed / 3600), "h")
        case .days: return (Int(elapsed / 86400), "d")
        case .months: return (Int(elapsed / (86400 * 30)), "mo")
        case .years: return (Int(elapsed / (86400 * 365)), "y")
        }
    }

    private var timeLabel: some View {
        let parts = countOverride.map { (value: $0, unit: "d") } ?? countParts(for: currentTime)
        // Small enough to sit clear of the pattern on every theme
        let big: CGFloat = isImageCard ? 36 : 42
        return (Text(parts.value.formatted()).font(.allo(big, weight: .semibold).monospacedDigit())
                + Text(parts.unit).font(.allo(big * 0.42, weight: .semibold)))
            .tracking(-1.5)
            // Digits roll when the count changes, e.g. after an undo
            .contentTransition(.numericText(value: Double(parts.value)))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .accessibilityLabel(widgetTimeValue(for: currentTime))
    }

    private func subtitleLabel(multilineAlignment: TextAlignment) -> some View {
        Text(subtitleOverride ?? "Since \(event.title)")
            .font(.allo(13, weight: .medium))
            .contentTransition(.opacity)
            .foregroundColor(Color.white.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(multilineAlignment)
    }
}

#Preview {
    EventListView()
        .environmentObject(EventViewModel())
}



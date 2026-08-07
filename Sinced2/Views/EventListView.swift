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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedEvent: SinceEvent?
    @State private var eventPendingDeletion: SinceEvent?
    @State private var showingCreateEvent = false
    @State private var draggingEvent: SinceEvent?
    
    private var isEmptyState: Bool {
        viewModel.events.isEmpty
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
            let cardHeight = (geometry.size.width - (16 * 3)) / 2
            
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
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
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.events) { event in
                                Button {
                                    HapticManager.shared.light()
                                    selectedEvent = event
                                } label: {
                                    HomeEventCardView(event: event)
                                    .frame(height: cardHeight)
                                }
                                .buttonStyle(FluidPressButtonStyle())
                                .scaleEffect(draggingEvent?.id == event.id && !reduceMotion ? 0.96 : 1.0)
                                .zIndex(draggingEvent?.id == event.id ? 1 : 0)
                                .animation(
                                    AppMotion.spring(reduceMotion: reduceMotion, response: 0.24, dampingFraction: 0.9),
                                    value: draggingEvent?.id
                                )
                                .accessibilityLabel("\(event.title), started \(event.smartFormattedStartDate)")
                                .accessibilityHint("Opens event details")
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
                                        draggingEvent: $draggingEvent,
                                        reduceMotion: reduceMotion
                                    )
                                )
                                .contextMenu {
                                    Button(role: .destructive) {
                                        eventPendingDeletion = event
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
                        .padding(.horizontal, 16)
                        .padding(.top, geometry.safeAreaInsets.top + 16)
                        .padding(.bottom, 120) // Space for bottom nav
                    }
                    .ignoresSafeArea()
                }

                // Top gradient fade
                VStack {
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(UIColor.systemBackground),
                                    Color(UIColor.systemBackground).opacity(0.9),
                                    Color(UIColor.systemBackground).opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()
                        )
                    
                    Spacer()
                }
                
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
            .sheet(isPresented: $showingCreateEvent) {
                AddEventBottomSheet(viewModel: viewModel, isPresented: $showingCreateEvent)
                    .presentationDetents([.height(440)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(36)
                    .presentationBackground(.regularMaterial)
            }
            .sheet(item: $eventPendingDeletion) { event in
                DeleteConfirmationSheet(eventTitle: event.title) {
                    eventPendingDeletion = nil
                    viewModel.deleteEvent(event)
                    showSuccessToast(title: event.title)
                }
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
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
                .fill(Color(UIColor.secondarySystemBackground))
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    Color.black.opacity(0.18),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
            
            Image(systemName: "plus")
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(.primary)
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct AddPlaceholderButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(AppMotion.spring(reduceMotion: reduceMotion, response: 0.2), value: configuration.isPressed)
    }
}

private struct EventReorderDropDelegate: DropDelegate {
    let targetEvent: SinceEvent
    let viewModel: EventViewModel
    @Binding var draggingEvent: SinceEvent?
    let reduceMotion: Bool

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

        withAnimation(AppMotion.spring(reduceMotion: reduceMotion, response: 0.24, dampingFraction: 0.9)) {
            viewModel.moveEvent(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
        viewModel.persistActiveEventOrder()
        HapticManager.shared.medium()

        withAnimation(AppMotion.spring(reduceMotion: reduceMotion, response: 0.24, dampingFraction: 0.9)) {
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
        let elapsed = date.timeIntervalSince(event.startedAt)
        
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
            .foregroundColor(.white)
            .tracking(-1.6)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 3)
    }

    private func subtitleLabel(multilineAlignment: TextAlignment) -> some View {
        Text("Since \(event.title)")
            .font(.system(size: 14, weight: .medium, design: .rounded))
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

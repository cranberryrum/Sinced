//
//  ArchivedEventsView.swift
//  Sinced2
//
//  Lists archived events from Settings so they can be restored or deleted
//

import SwiftUI

struct ArchivedEventsView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @State private var eventPendingDelete: SinceEvent?

    var body: some View {
        Group {
            if viewModel.archivedEvents.isEmpty {
                ContentUnavailableView {
                    Label("No Archived Events", systemImage: "archivebox")
                } description: {
                    Text("Long-press an event on your home screen and choose Archive to keep it here.")
                }
            } else {
                List {
                    Section {
                        ForEach(viewModel.archivedEvents) { event in
                            ArchivedEventRow(event: event) {
                                restore(event)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    restore(event)
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.primaryGreen)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    eventPendingDelete = event
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    restore(event)
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                }

                                Button(role: .destructive) {
                                    eventPendingDelete = event
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } footer: {
                        Text("Archived events keep counting, but stay off your home screen, widgets and reminders.")
                    }
                }
                .listStyle(.insetGrouped)
                .grainListBackground()
            }
        }
        .animation(.smooth(duration: 0.3), value: viewModel.archivedEvents.map(\.id))
        .navigationTitle("Archived Events")
        .navigationBarTitleDisplayMode(.inline)
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
                    HapticManager.shared.medium()
                }
                eventPendingDelete = nil
            }
        } message: {
            Text("This removes the event and its history.")
        }
    }

    private func restore(_ event: SinceEvent) {
        viewModel.unarchiveEvent(event)
    }
}

private struct ArchivedEventRow: View {
    let event: SinceEvent
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ArchivedEventThumbnail(event: event)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.roundedBody)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(event.relativeTimeString) · since \(event.smartFormattedStartDate)")
                    .font(.roundedCaption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button("Restore", action: onRestore)
                .font(.roundedCaption.weight(.semibold))
                .foregroundColor(.primaryGreen)
                .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}

/// Small square of the event's card, like the home screen tile
private struct ArchivedEventThumbnail: View {
    let event: SinceEvent

    var body: some View {
        ZStack {
            if event.cardTheme == .custom,
               let imageData = event.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                event.cardTheme.backgroundColor

                if let asset = event.cardTheme.squareSvgAssetName {
                    Image(asset)
                        .resizable()
                        .scaledToFill()
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }
}

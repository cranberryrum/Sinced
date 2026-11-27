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

    private var headerLine: Text {
        let count = viewModel.archivedEvents.count
        if count == 0 { return Text("Nothing archived.") }
        return SettingsPageHeader.bold("\(count) \(count == 1 ? "counter" : "counters")") + Text(" resting here.")
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsPageHeader(label: "Archived", line: headerLine)
                    .padding(.bottom, 10)

                SettingsCard {
                    if viewModel.archivedEvents.isEmpty {
                        Text("Long-press a counter on your home screen and choose Archive to keep it here, out of the way.")
                            .font(.allo(15))
                            .foregroundStyle(CardText.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 18)
                    } else {
                        ForEach(Array(viewModel.archivedEvents.enumerated()), id: \.element.id) { i, event in
                            if i > 0 { DashedRule() }
                            ArchivedEventRow(event: event, onRestore: { restore(event) }, onDelete: { eventPendingDelete = event })
                                .transition(.opacity)
                        }
                    }
                }

                if !viewModel.archivedEvents.isEmpty {
                    Text("Archived counters keep counting, but stay off your home screen, widgets and reminders. Long-press one to delete it for good.")
                        .font(.allo(13))
                        .foregroundStyle(CardText.label)
                        .padding(.horizontal, 6)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 130)
        }
        .background(GrainBackground().ignoresSafeArea())
        .animation(.smooth(duration: 0.3), value: viewModel.archivedEvents.map(\.id))
        .navigationTitle("")
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
            Text("This removes the counter and its history.")
        }
    }

    private func restore(_ event: SinceEvent) {
        viewModel.unarchiveEvent(event)
    }
}

private struct ArchivedEventRow: View {
    let event: SinceEvent
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            EventThumbnail(event: event, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.allo(16, weight: .medium))
                    .foregroundStyle(CardText.word)
                    .lineLimit(1)
                Text("\(event.relativeTimeString) · since \(event.smartFormattedStartDate)")
                    .font(.allo(13))
                    .foregroundStyle(CardText.label)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                HapticManager.shared.light()
                onRestore()
            } label: {
                Text("Restore")
                    .font(.allo(14, weight: .semibold))
                    .foregroundStyle(Color.primaryGreen)
                    .padding(.horizontal, 13)
                    .frame(height: 32)
                    .background(Capsule().fill(Color.primaryGreen.opacity(0.1)))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .contextMenu {
            Button { onRestore() } label: { Label("Restore", systemImage: "arrow.uturn.backward") }
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

/// Small square of the event's card, like the home screen tile
struct EventThumbnail: View {
    let event: SinceEvent
    var size: CGFloat = 40

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
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
        .accessibilityHidden(true)
    }
}

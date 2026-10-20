//
//  ResetSheetView.swift
//  Sinced2
//
//  Sheet for resetting an event: shows the run being ended, lets you backdate
//  the reset and add a note, and keeps the run in the event's history
//

import SwiftUI

struct ResetSheetView: View {
    let event: SinceEvent
    @ObservedObject var viewModel: EventViewModel
    /// Called after the reset is saved, e.g. to offer an undo
    var onReset: () -> Void = {}
    @Environment(\.dismiss) var dismiss

    @State private var resetDate = Date()
    @State private var note = ""

    /// Valid reset dates. Guards against a start date in the future (older
    /// data), which would make `startedAt...now` an invalid range and crash.
    private var resetRange: ClosedRange<Date> {
        let now = Date()
        return min(event.startedAt, now)...now
    }

    /// Length of the run this reset ends
    private var endingRun: String {
        SincedDurationText.text(for: min(resetDate, Date()).timeIntervalSince(event.startedAt))
    }

    private var isBackdated: Bool {
        Date().timeIntervalSince(resetDate) > 60
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reset \(event.title.lowercased())?")
                        .font(.rounded(22, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Your current run of \(endingRun) goes into history, and the counter starts again from \(isBackdated ? "the time below" : "now").")
                        .font(.roundedSubheadline)
                        .foregroundColor(.secondary)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.25), value: endingRun)

                    Text("First started \(event.firstStartedAt.sincedShortDate). That stays.")
                        .font(.roundedCaption)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }

                // When it happened, in case it was earlier than now
                HStack(spacing: 8) {
                    Text("When")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    Spacer()

                    StartDatePill(
                        date: $resetDate,
                        components: .date,
                        text: resetDate.formatted(.dateTime.day().month(.abbreviated).year()),
                        range: resetRange
                    )
                    StartDatePill(
                        date: $resetDate,
                        components: .hourAndMinute,
                        text: resetDate.formatted(date: .omitted, time: .shortened),
                        range: resetRange
                    )

                    if isBackdated {
                        Button("Now") {
                            withAnimation(.smooth(duration: 0.25)) { resetDate = Date() }
                        }
                        .font(.rounded(15, weight: .medium))
                        .foregroundColor(.primaryGreen)
                        .transition(.opacity)
                    }
                }
                .animation(.smooth(duration: 0.25), value: isBackdated)

                TextField(
                    "Note",
                    text: $note,
                    prompt: Text("what happened? (optional)").foregroundColor(Color(hex: "8a888a")),
                    axis: .vertical
                )
                .lineLimit(1...3)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )

                Button(action: resetEvent) {
                    Text("Reset counter")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Color(hex: "E5484D")))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        // Extra detent so large Dynamic Type can still reach the button
        .presentationDetents([.height(400), .large])
        .presentationDragIndicator(.visible)
    }

    private func resetEvent() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.resetEvent(event, at: min(resetDate, Date()), note: trimmedNote.isEmpty ? nil : trimmedNote)
        onReset()
        dismiss()
    }
}

#Preview {
    let sampleEvent = SinceEvent(
        title: "Coffee",
        startedAt: Date().addingTimeInterval(-3600 * 24 * 3)
    )

    ResetSheetView(event: sampleEvent, viewModel: EventViewModel())
}

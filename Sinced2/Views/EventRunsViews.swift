//
//  EventRunsViews.swift
//  Sinced2
//
//  Event detail pieces that show an event's runs: when it was first started,
//  how the current run compares, and every run a reset has ended.
//

import SwiftUI

/// Under the event title: when the current run started and, after any reset,
/// when the counter was first started
struct RunStartSummary: View {
    let event: SinceEvent

    var body: some View {
        VStack(spacing: 4) {
            if event.hasBeenReset {
                Text("Current run since \(event.startedAt.sincedShortDate)")
                    .foregroundColor(.secondary)
                Text("First started \(event.firstStartedAt.sincedShortDate)")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            } else {
                Text("Started on \(event.startedAt.sincedShortDate)")
                    .foregroundColor(.secondary)
            }
        }
        .font(.roundedSubheadline)
        .multilineTextAlignment(.center)
        .contentTransition(.opacity)
    }
}

/// Stats plus the list of past runs, shown once an event has been reset
struct RunsSection: View {
    let event: SinceEvent
    let now: Date
    @Binding var showingAll: Bool

    private static let collapsedCount = 4

    var body: some View {
        let runs = event.pastRuns
        let best = event.bestRunDuration(at: now)
        let visibleRuns = showingAll ? runs : Array(runs.prefix(Self.collapsedCount))

        VStack(alignment: .leading, spacing: 14) {
            Text("Runs")
                .font(.roundedHeadline)
                .foregroundColor(.primary)

            HStack(spacing: 8) {
                RunStatTile(
                    title: "current",
                    value: SincedDurationText.text(for: now.timeIntervalSince(event.startedAt)),
                    highlighted: event.isOnBestRun(at: now)
                )
                RunStatTile(title: "best", value: SincedDurationText.text(for: best))
                RunStatTile(title: "resets", value: "\(event.history.count)")
            }

            VStack(spacing: 0) {
                ForEach(Array(visibleRuns.enumerated()), id: \.element.id) { index, run in
                    RunRow(run: run, isBest: abs(run.duration(at: now) - best) < 1, goal: event.goalDays, now: now)
                    if index < visibleRuns.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )

            if runs.count > Self.collapsedCount {
                Button(showingAll ? "Show less" : "Show all \(runs.count) runs") {
                    withAnimation(.smooth(duration: 0.3)) { showingAll.toggle() }
                }
                .font(.roundedSubheadline)
                .foregroundColor(.primaryGreen)
                .frame(maxWidth: .infinity)
            }

            Text("Started \(event.firstStartedAt.sincedShortDate) · \(SincedDurationText.text(for: now.timeIntervalSince(event.firstStartedAt))) since the first start")
                .font(.roundedCaption)
                .foregroundColor(.secondary)
        }
    }
}

private struct RunStatTile: View {
    let title: String
    let value: String
    var highlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.roundedCaption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.rounded(15, weight: .medium))
                .foregroundColor(highlighted ? .primaryGreen : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
    }
}

/// One finished run: how long it lasted, its dates and the reset note
private struct RunRow: View {
    let run: EventRun
    let isBest: Bool
    /// The event's goal, to mark past runs that reached it
    let goal: Int?
    let now: Date

    private var reachedGoal: Bool {
        guard let goal, goal > 0, run.end != nil else { return false }
        return Int(run.duration(at: now) / 86400) >= goal
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(SincedDurationText.text(for: run.duration(at: now)))
                        .font(.rounded(15, weight: .medium))
                        .foregroundColor(.primary)
                    if isBest {
                        Text("best")
                            .font(.rounded(11, weight: .medium))
                            .foregroundColor(.primaryGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.primaryGreen.opacity(0.12)))
                    }
                    if reachedGoal {
                        Text("goal ✓")
                            .font(.rounded(11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.12)))
                    }
                }

                Text("\(run.start.sincedShortDate) → \(run.end?.sincedShortDate ?? "now")")
                    .font(.roundedCaption)
                    .foregroundColor(.secondary)

                if let note = run.note, !note.isEmpty {
                    Text(note)
                        .font(.roundedCaption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}


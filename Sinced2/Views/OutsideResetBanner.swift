//
//  OutsideResetBanner.swift
//  Sinced2
//
//  Asks about a reset made from a widget, Control Center, the Action button
//  or Siri, the next time the app is opened. It stays until answered: a mis-tap
//  shouldn't cost someone their streak just because they didn't see it in time.
//

import SwiftUI

struct OutsideResetBanner: View {
    let offer: OutsideResetOffer
    let onUndo: () -> Void
    let onDismiss: () -> Void

    private var when: String {
        offer.resetAt.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
    }

    private var lostRun: String {
        StreakText.text(for: offer.lostRun)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primaryGreen)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.primaryGreen.opacity(0.12)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(offer.title) was reset")
                    .font(.rounded(15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(when.prefix(1).capitalized + when.dropFirst()). By mistake? Undo brings back \(lostRun).")
                    .font(.roundedCaption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button(action: onUndo) {
                Text("Undo")
                    .font(.rounded(15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(Capsule().fill(Color.primaryGreen))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint("Brings back your run of \(lostRun)")

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.black.opacity(0.06)))
                    // Small glyph, full-size target
                    .frame(width: 36, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("It wasn't a mistake")
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        )
    }
}

extension AnyTransition {
    /// Banners rise from the bottom edge and leave the same way
    static func banner(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }
}

/// How long a run lasted, in the words that matter for a streak: whole days
/// once it's at least a day ("62 days", not "2 months")
enum StreakText {
    static func text(for interval: TimeInterval) -> String {
        let days = Int(interval / 86400)
        guard days >= 1 else { return SincedDurationText.text(for: interval) }
        return "\(days) \(days == 1 ? "day" : "days")"
    }
}

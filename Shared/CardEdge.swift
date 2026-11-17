//
//  CardEdge.swift
//  Shared (app + widget)
//
//  The "hairline" edge on event cards and widgets: a thin white inner stroke
//  and a little light catching the top edge. Quiet on its own; together it
//  makes the card read as a finished object rather than a flat image.
//

import SwiftUI
import WidgetKit

extension View {
    /// Draws the hairline edge inside `shape`, over the card's artwork.
    /// Apply it to the whole card, or the whole widget, so the stroke only
    /// follows the outside.
    func cardEdge<S: InsettableShape>(_ shape: S) -> some View {
        overlay { CardEdgeOverlay(shape: shape) }
    }
}

private struct CardEdgeOverlay<S: InsettableShape>: View {
    let shape: S
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        // Tinted and clear Home Screens recolour everything, which would turn
        // the edge into a bright outline; it only belongs on full-colour cards
        if renderingMode == .fullColor {
            ZStack {
                // Light catching the top edge
                LinearGradient(
                    colors: [.white.opacity(0.12), .white.opacity(0)],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.3)
                )
                .blendMode(.softLight)
                .clipShape(shape)

                // The hairline
                shape.strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

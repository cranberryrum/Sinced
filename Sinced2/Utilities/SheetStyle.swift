//
//  SheetStyle.swift
//  Sinced2
//
//  One way to present bottom sheets: sized to their content at any text
//  size, with the system's own corners, drag indicator and motion
//

import SwiftUI

/// Total height of the parts of a sheet marked with `sheetHeightPart()`
private struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

extension View {
    /// Counts this view's height toward the sheet's fitted height. Mark the
    /// parts that stack top to bottom (header, scroll content, buttons), never
    /// anything that stretches to fill space.
    func sheetHeightPart() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(key: SheetHeightKey.self, value: proxy.size.height)
            }
        }
    }

    /// Present as a sheet exactly as tall as its content. `estimate` is the
    /// first height used, before the content has been measured, so the sheet
    /// doesn't jump as it opens. Content taller than the screen scrolls.
    func fittedSheet(estimate: CGFloat) -> some View {
        modifier(FittedSheet(estimate: estimate))
    }
}

private struct FittedSheet: ViewModifier {
    let estimate: CGFloat

    @State private var contentHeight: CGFloat?

    /// iOS already leaves room for the home indicator below a height detent
    private var height: CGFloat {
        contentHeight ?? estimate
    }

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(SheetHeightKey.self) { measured in
                guard measured > 0 else { return }
                let rounded = measured.rounded(.up)
                guard let current = contentHeight else {
                    contentHeight = rounded
                    return
                }
                // Grows and shrinks with its content, e.g. a note getting a second line
                guard abs(current - rounded) > 0.5 else { return }
                withAnimation(.smooth(duration: 0.3)) { contentHeight = rounded }
            }
            // iOS stops a taller height at the top of the screen, and the content scrolls
            .presentationDetents([.height(height)])
            .presentationDragIndicator(.visible)
    }
}

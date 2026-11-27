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

    /// The height the sheet sits at
    @State private var height: CGFloat?
    /// Detents on offer. Normally just `height`; while resizing, the old and
    /// new heights side by side. iOS won't move a presented sheet when its
    /// only detent is swapped for another, but it will move between two.
    @State private var detents: Set<PresentationDetent> = []
    @State private var selection: PresentationDetent = .large
    @State private var settle: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(SheetHeightKey.self) { measured in
                guard measured > 0 else { return }
                let new = measured.rounded(.up)
                guard let old = height else {
                    height = new
                    detents = [.height(new)]
                    selection = .height(new)
                    return
                }
                // Grows and shrinks with its content, e.g. the goal dial opening
                guard abs(old - new) > 0.5 else { return }
                height = new
                detents = [.height(old), .height(new)]
                withAnimation(.smooth(duration: 0.3)) { selection = .height(new) }
                // Once it's there, take the old height away so it can't be dragged to
                settle?.cancel()
                settle = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.45))
                    guard !Task.isCancelled else { return }
                    detents = [.height(new)]
                }
            }
            // iOS stops a taller height at the top of the screen, and the content scrolls
            .presentationDetents(
                detents.isEmpty ? [.height(estimate)] : detents,
                selection: Binding(
                    get: { detents.isEmpty ? .height(estimate) : selection },
                    set: { selection = $0 }
                )
            )
            .presentationDragIndicator(.visible)
            // The sheet's corners follow the screen's own
            .deviceCornerSheet()
            // Solid white instead of the system's glass, so text keeps full
            // contrast whatever colourful cards sit behind the sheet
            .presentationBackground(Color.white)
    }
}

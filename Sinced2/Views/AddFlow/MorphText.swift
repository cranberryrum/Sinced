//
//  MorphText.swift
//  Sinced2
//
//  Text that morphs between values the way Torph (torph.lochie.me) does on
//  the web: the text is split into words, or letters when there are no
//  spaces, and each piece gets an id from its own string. Pieces that are in
//  both the old and new text slide to their new place; new pieces fade up
//  from just under full size; pieces that leave fade out where they were.
//

import SwiftUI

/// One word, letter or space of a `MorphText`
struct MorphSegment: Identifiable, Equatable {
    let id: String
    let text: String
    let isSpace: Bool
}

enum MorphSegmenter {
    /// Torph's rule: words when the text has spaces, letters when it doesn't.
    /// The first copy of a string keeps the string as its id, later copies
    /// get `~1`, `~2`…, so "Save" → "Done" keeps its "e" and "90 days" →
    /// "100 days" keeps "days".
    static func segments(_ text: String) -> [MorphSegment] {
        var taken = Set<String>()
        func take(_ key: String) -> String {
            guard taken.contains(key) else { taken.insert(key); return key }
            var n = 1
            while taken.contains("\(key)~\(n)") { n += 1 }
            let id = "\(key)~\(n)"
            taken.insert(id)
            return id
        }

        guard text.contains(" ") else {
            return text.map { MorphSegment(id: take(String($0)), text: String($0), isSpace: false) }
        }

        var result: [MorphSegment] = []
        var offset = 0
        for (i, word) in text.split(separator: " ", omittingEmptySubsequences: false).enumerated() {
            if i > 0 {
                result.append(MorphSegment(id: take("space-\(offset)"), text: " ", isSpace: true))
                offset += 1
            }
            if !word.isEmpty {
                result.append(MorphSegment(id: take(String(word)), text: String(word), isSpace: false))
            }
            offset += word.count
        }
        return result
    }
}

struct MorphText: View {
    let text: String
    var font: Font
    var color: Color = .primary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Torph's default curve and length
    static let animation = Animation.timingCurve(0.19, 1, 0.22, 1, duration: 0.4)

    var body: some View {
        WrapLayout(spacing: 0, lineSpacing: 0) {
            ForEach(MorphSegmenter.segments(text)) { segment in
                Text(segment.text)
                    .font(font)
                    .foregroundStyle(color)
                    .fixedSize()
                    .layoutValue(key: CollapsesAtLineStart.self, value: segment.isSpace)
                    .transition(reduceMotion ? .opacity : .morphSegment)
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.15) : Self.animation, value: text)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

private struct MorphSegmentIn: ViewModifier {
    let shown: Bool
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .scaleEffect(shown ? 1 : 0.95)
            .blur(radius: shown ? 0 : 2)
    }
}

extension AnyTransition {
    /// Torph's timing: a new piece waits a quarter of the morph, then fades
    /// in over half of it; a leaving piece is gone within a quarter
    static var morphSegment: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: MorphSegmentIn(shown: false), identity: MorphSegmentIn(shown: true))
                .animation(.easeOut(duration: 0.2).delay(0.1)),
            removal: .opacity.animation(.linear(duration: 0.1))
        )
    }
}

// MARK: - Wrapping layout

/// Spaces that would start a line are tucked onto the end of the line before
struct CollapsesAtLineStart: LayoutValueKey {
    static let defaultValue = false
}

/// Lays subviews out left to right and wraps them onto new lines, like text.
/// Each subview is offered the full width, so one that holds text of its
/// own can wrap inside itself.
struct WrapLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    private struct Line {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(for subviews: Subviews, maxWidth: CGFloat) -> [Line] {
        var lines: [Line] = [Line()]
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let collapses = subview[CollapsesAtLineStart.self]
            var line = lines[lines.count - 1]
            let gap = line.items.isEmpty ? 0 : spacing
            if !line.items.isEmpty, line.width + gap + size.width > maxWidth + 0.5, !collapses {
                lines.append(Line())
                line = Line()
            }
            let lineGap = line.items.isEmpty ? 0 : spacing
            line.items.append((index, size))
            // A space at the end of a line takes no room, so it never forces a wrap
            if !(collapses && line.width + lineGap + size.width > maxWidth) {
                line.width += lineGap + size.width
            }
            line.height = max(line.height, size.height)
            lines[lines.count - 1] = line
        }
        return lines
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let lines = lines(for: subviews, maxWidth: maxWidth)
        let width = lines.map(\.width).max() ?? 0
        let height = lines.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, lines.count - 1))
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(for: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for (n, item) in line.items.enumerated() {
                if n > 0 { x += spacing }
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (line.height - item.size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width
            }
            y += line.height + lineSpacing
        }
    }
}

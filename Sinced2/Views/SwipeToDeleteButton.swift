//
//  SwipeToDeleteButton.swift
//  Sinced2
//
//  Swipe to confirm delete CTA
//

import SwiftUI

struct SwipeToDeleteButton: View {
    let onDelete: () -> Void
    let title: String
    
    @State private var dragOffset: CGFloat = 0
    @State private var hasTriggered = false
    /// Past the point where letting go deletes, so a tick can mark it once
    @State private var isPastThreshold = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let height: CGFloat = 56
    private let handleSize: CGFloat = 44
    private let horizontalPadding: CGFloat = 6
    private let completionThreshold: CGFloat = 0.86
    
    init(title: String = "Swipe to delete", onDelete: @escaping () -> Void) {
        self.title = title
        self.onDelete = onDelete
    }
    
    var body: some View {
        GeometryReader { geometry in
            let maxOffset = max(0, geometry.size.width - handleSize - (horizontalPadding * 2))
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.red.opacity(0.12))
                
                Capsule()
                    .fill(Color.red.opacity(0.22))
                    .frame(width: dragOffset + handleSize + horizontalPadding)
                
                Text(hasTriggered ? "Deleting…" : title)
                    .font(.roundedSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    // Fades as the handle slides over it, so the two never overlap at full strength
                    .opacity(hasTriggered ? 1 : 1 - Double(dragOffset / max(maxOffset, 1)) * 0.7)
                    .contentTransition(.opacity)
                
                Circle()
                    .fill(Color.red)
                    .frame(width: handleSize, height: handleSize)
                    .overlay(
                        Image(systemName: "trash.fill")
                            .font(.rounded(16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.red.opacity(0.25), radius: 8, x: 0, y: 4)
                    .offset(x: dragOffset + horizontalPadding)
            }
            .frame(height: height)
            .overlay(
                Capsule()
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !hasTriggered else { return }
                        // Follows the finger exactly: no animation while dragging
                        let translation = max(0, value.translation.width)
                        dragOffset = min(translation, maxOffset)

                        let past = dragOffset >= maxOffset * completionThreshold
                        if past != isPastThreshold {
                            isPastThreshold = past
                            if past { HapticManager.shared.selection() }
                        }
                    }
                    .onEnded { value in
                        guard !hasTriggered else { return }
                        isPastThreshold = false
                        // A quick flick counts, not just a long drag
                        let projected = max(dragOffset, value.predictedEndTranslation.width)
                        if projected >= maxOffset * completionThreshold {
                            hasTriggered = true
                            HapticManager.shared.warning()
                            withAnimation(release) { dragOffset = maxOffset }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                onDelete()
                            }
                        } else {
                            withAnimation(release) { dragOffset = 0 }
                            HapticManager.shared.light()
                        }
                    }
            )
        }
        .frame(height: height)
    }

    /// Settles on release; no bounce on a destructive control
    private var release: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.35, bounce: 0)
    }
}

#Preview {
    SwipeToDeleteButton {
        print("Delete triggered")
    }
    .padding()
}

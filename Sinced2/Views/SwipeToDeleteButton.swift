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
                
                Text(hasTriggered ? "Deleting..." : title)
                    .font(.roundedSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                
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
                        let translation = max(0, value.translation.width)
                        dragOffset = min(translation, maxOffset)
                    }
                    .onEnded { _ in
                        guard !hasTriggered else { return }
                        if dragOffset >= maxOffset * completionThreshold {
                            hasTriggered = true
                            HapticManager.shared.warning()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                dragOffset = maxOffset
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                onDelete()
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                            HapticManager.shared.light()
                        }
                    }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: dragOffset)
        }
        .frame(height: height)
    }
}

#Preview {
    SwipeToDeleteButton {
        print("Delete triggered")
    }
    .padding()
}

//
//  DeleteButton.swift
//  Sinced2
//
//  Long-press delete button with animations and haptic feedback
//

import SwiftUI

struct DeleteButton: View {
    let eventName: String
    let onDelete: () -> Void
    let onShortPress: () -> Void
    
    @State private var isPressed = false
    @State private var pressProgress: CGFloat = 0.0
    @State private var scale: CGFloat = 1.0
    @State private var offsetY: CGFloat = 0.0
    @State private var opacity: Double = 1.0
    @State private var width: CGFloat?
    @State private var timer: Timer?
    
    private let longPressDuration: TimeInterval = 1.5
    private let deleteAnimationDuration: TimeInterval = 0.35
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {}) {
                ZStack {
                    // Background progress indicator
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.15))
                        .frame(width: width ?? geometry.size.width)
                    
                    // Progress fill
                    HStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.3))
                            .frame(width: (width ?? geometry.size.width) * pressProgress)
                        
                        Spacer(minLength: 0)
                    }
                    
                    // Button content
                    HStack {
                        Image(systemName: "trash")
                        Text(isPressed ? "Hold to Delete..." : "Delete Event")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .frame(width: width ?? geometry.size.width)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(scale)
            .offset(y: offsetY)
            .opacity(opacity)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            handlePressStart()
                        }
                    }
                    .onEnded { _ in
                        handlePressEnd()
                    }
            )
            .onAppear {
                width = geometry.size.width
            }
        }
        .frame(height: 50)
    }
    
    private func handlePressStart() {
        isPressed = true
        HapticManager.shared.light()
        
        // Start progress animation
        withAnimation(.linear(duration: longPressDuration)) {
            pressProgress = 1.0
        }
        
        // Scale animation on press
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 0.96
        }
        
        // Start timer for long press detection
        timer = Timer.scheduledTimer(withTimeInterval: longPressDuration, repeats: false) { _ in
            handleLongPressComplete()
        }
    }
    
    private func handlePressEnd() {
        guard isPressed else { return }
        
        timer?.invalidate()
        timer = nil
        
        // Check if long press was completed
        if pressProgress < 1.0 {
            // Short press - show toast
            onShortPress()
            HapticManager.shared.medium()
            
            // Reset animations - stop ongoing animation and reset immediately
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            // Stop the progress animation by setting it back to 0
            withAnimation(.easeOut(duration: 0.2)) {
                pressProgress = 0.0
            }
            
            isPressed = false
        }
    }
    
    private func handleLongPressComplete() {
        // Long press completed - trigger delete
        HapticManager.shared.warning()
        
        // Animate deletion
        withAnimation(.spring(response: deleteAnimationDuration, dampingFraction: 0.8)) {
            offsetY = -20.0
            scale = 0.9
        }
        
        withAnimation(.spring(response: deleteAnimationDuration, dampingFraction: 0.8).delay(0.1)) {
            opacity = 0.0
        }
        
        // Trigger delete action after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + deleteAnimationDuration + 0.1) {
            onDelete()
        }
    }
}

#Preview {
    VStack {
        DeleteButton(
            eventName: "Coffee",
            onDelete: {
                print("Delete triggered")
            },
            onShortPress: {
                print("Short press - show toast")
            }
        )
        .padding()
    }
}


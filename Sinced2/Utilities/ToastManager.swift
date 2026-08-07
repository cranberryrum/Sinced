//
//  ToastManager.swift
//  Sinced2
//
//  Toast notification system for showing temporary messages
//

import SwiftUI
import Combine

enum ToastPosition {
    case top
    case bottom
}

struct ToastStyle {
    let backgroundColor: Color
    let textColor: Color
    let iconColor: Color
    let iconBackgroundColor: Color?
    let position: ToastPosition
    let animation: Animation
    let transition: AnyTransition
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let bottomOffset: CGFloat
    
    static let defaultStyle = ToastStyle(
        backgroundColor: Color.black.opacity(0.85),
        textColor: .white,
        iconColor: .white,
        iconBackgroundColor: nil,
        position: .bottom,
        animation: .spring(response: 0.4, dampingFraction: 0.7),
        transition: .move(edge: .bottom).combined(with: .opacity),
        horizontalPadding: 20,
        verticalPadding: 14,
        bottomOffset: 0
    )
    
    static let deleteBanner = ToastStyle(
        backgroundColor: Color.red.opacity(0.14),
        textColor: .red,
        iconColor: .red,
        iconBackgroundColor: Color.red.opacity(0.2),
        position: .bottom,
        animation: .spring(response: 0.5, dampingFraction: 0.86),
        transition: .move(edge: .bottom)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.98, anchor: .bottom)),
        horizontalPadding: 16,
        verticalPadding: 12,
        bottomOffset: 92
    )
}

/// Toast notification view modifier
struct Toast: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let icon: String?
    let style: ToastStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                GeometryReader { geometry in
                    toastContent
                        .padding(.horizontal, style.horizontalPadding)
                        .padding(.vertical, style.verticalPadding)
                        .background(
                            Group {
                                if style.position == .top {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(reduceTransparency ? AnyShapeStyle(style.backgroundColor) : AnyShapeStyle(.regularMaterial))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(style.backgroundColor)
                                        )
                                } else {
                                    Capsule()
                                        .fill(reduceTransparency ? AnyShapeStyle(style.backgroundColor) : AnyShapeStyle(.regularMaterial))
                                        .overlay(
                                            Capsule()
                                                .fill(style.backgroundColor)
                                        )
                                }
                            }
                        )
                        .shadow(color: .black.opacity(style.position == .top ? 0.08 : 0.2), radius: 10, x: 0, y: 5)
                        .padding(.top, style.position == .top ? geometry.safeAreaInsets.top + 8 : 0)
                        .padding(
                            .bottom,
                            style.position == .bottom
                                ? max(36, geometry.safeAreaInsets.bottom + 24) + style.bottomOffset
                                : 0
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: style.position == .top ? .top : .bottom
                        )
                        .transition(reduceMotion ? .opacity : style.transition)
                }
                .allowsHitTesting(false)
                .animation(reduceMotion ? .easeOut(duration: 0.16) : style.animation, value: isShowing)
            }
        }
    }
    
    private var toastContent: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                if let iconBackgroundColor = style.iconBackgroundColor {
                    ZStack {
                        Circle()
                            .fill(iconBackgroundColor)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: icon)
                            .font(.rounded(14, weight: .semibold))
                            .foregroundColor(style.iconColor)
                    }
                } else {
                    Image(systemName: icon)
                        .font(.rounded(16, weight: .semibold))
                        .foregroundColor(style.iconColor)
                }
            }
            
            Text(message)
                .font(.roundedSubheadline)
                .fontWeight(.medium)
                .foregroundColor(style.textColor)
        }
    }
}

extension View {
    /// Show a toast notification
    func toast(
        isShowing: Binding<Bool>,
        message: String,
        icon: String? = nil,
        style: ToastStyle = .defaultStyle
    ) -> some View {
        modifier(Toast(isShowing: isShowing, message: message, icon: icon, style: style))
    }
}

/// Observable toast manager for showing toasts from anywhere
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isShowing = false
    @Published var message = ""
    @Published var icon: String?
    @Published var style: ToastStyle = .defaultStyle
    
    private var dismissWorkItem: DispatchWorkItem?
    
    private init() {}
    
    /// Show a toast message
    func show(_ message: String, icon: String? = nil, style: ToastStyle = .defaultStyle, duration: Double = 2.0) {
        dismissWorkItem?.cancel()
        
        self.message = message
        self.icon = icon
        self.style = style
        
        let animation: Animation = UIAccessibility.isReduceMotionEnabled
            ? .easeOut(duration: 0.16)
            : style.animation

        withAnimation(animation) {
            isShowing = true
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let animation: Animation = UIAccessibility.isReduceMotionEnabled
                ? .easeOut(duration: 0.16)
                : self.style.animation
            withAnimation(animation) {
                self.isShowing = false
            }
        }
        dismissWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
}


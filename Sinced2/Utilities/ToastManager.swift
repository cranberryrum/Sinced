//
//  ToastManager.swift
//  Sinced2
//
//  One toast for the whole app. It drops in under the Dynamic Island like a
//  system banner, in its own window above everything (sheets included), so
//  every message looks, moves and behaves the same wherever it comes from.
//
//  ToastManager.shared.show("Widget added", icon: "checkmark", kind: .success)
//

import Combine
import SwiftUI
import UIKit

// MARK: - The toast

struct Toast: Identifiable, Equatable {
    enum Kind {
        /// Something went well: green icon, success haptic
        case success
        /// Neutral news: grey icon, no haptic
        case info
        /// Something was removed: red icon, a light tap
        case destructive
        /// Something failed: orange icon, warning haptic
        case error
    }

    struct Action {
        let title: String
        let handler: () -> Void
    }

    let id = UUID()
    let title: String
    var subtitle: String? = nil
    var icon: String
    var kind: Kind = .info
    var action: Action? = nil
    var duration: Double = 2.6

    static func == (lhs: Toast, rhs: Toast) -> Bool { lhs.id == rhs.id }
}

/// Kept so older call sites read naturally
enum ToastStyle {
    case defaultStyle
    case deleteBanner
}

// MARK: - Manager

@MainActor
final class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published private(set) var current: Toast?
    /// Where the toast is on screen, so its window only takes touches there
    fileprivate var toastFrame: CGRect = .null

    private var dismissTask: Task<Void, Never>?
    private var remaining: Double = 0
    private var shownAt: Date?
    private var window: ToastWindow?

    private init() {}

    /// Show a toast. A new one replaces the one on screen.
    func show(_ toast: Toast) {
        installWindowIfNeeded()
        dismissTask?.cancel()

        switch toast.kind {
        case .success: HapticManager.shared.success()
        case .error: HapticManager.shared.warning()
        case .destructive: HapticManager.shared.light()
        case .info: break
        }

        withAnimation(current == nil ? Self.enter : .spring(duration: 0.3, bounce: 0)) {
            current = toast
        }
        // A toast with an action stays a little longer, so there's time to use it
        remaining = toast.duration
        startTimer()
        UIAccessibility.post(notification: .announcement,
                             argument: [toast.title, toast.subtitle].compactMap { $0 }.joined(separator: ". "))
    }

    /// The short form most of the app uses
    func show(_ message: String, subtitle: String? = nil, icon: String? = nil,
              kind: Toast.Kind = .info, style: ToastStyle = .defaultStyle, duration: Double = 2.6) {
        let kind: Toast.Kind = style == .deleteBanner ? .destructive : kind
        show(Toast(title: message, subtitle: subtitle, icon: icon ?? Self.defaultIcon(for: kind),
                   kind: kind, duration: duration))
    }

    func dismiss() {
        dismissTask?.cancel()
        toastFrame = .null
        withAnimation(Self.exit) { current = nil }
    }

    /// A finger resting on the toast stops the clock
    func setHeld(_ held: Bool) {
        if held {
            dismissTask?.cancel()
            if let shownAt { remaining = max(0.6, remaining - Date().timeIntervalSince(shownAt)) }
            shownAt = nil
        } else if current != nil {
            startTimer()
        }
    }

    private func startTimer() {
        shownAt = Date()
        let wait = remaining
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    // Grows out of the Dynamic Island with a soft overshoot; tucks back in
    // quicker than it came, with no bounce
    static let enter = Animation.spring(duration: 0.55, bounce: 0.32)
    static let exit = Animation.spring(duration: 0.32, bounce: 0)

    private static func defaultIcon(for kind: Toast.Kind) -> String {
        switch kind {
        case .success: return "checkmark"
        case .info: return "info"
        case .destructive: return "trash"
        case .error: return "exclamationmark"
        }
    }

    private func installWindowIfNeeded() {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        let window = ToastWindow(windowScene: scene)
        window.manager = self
        let host = UIHostingController(rootView: ToastHost(manager: self))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.windowLevel = .alert + 1
        window.isHidden = false
        self.window = window
    }
}

// MARK: - Window

/// Sits above everything but lets touches through except on the toast itself
private final class ToastWindow: UIWindow {
    weak var manager: ToastManager?

    // SwiftUI reports every touch as landing on the root view, so decide by
    // the toast's frame: inside it the toast takes the touch, anywhere else
    // it goes to the app underneath
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let frame = MainActor.assumeIsolated({ manager?.toastFrame }), frame.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

// MARK: - View

private struct ToastHost: View {
    @ObservedObject var manager: ToastManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
            if let toast = manager.current {
                ToastView(toast: toast)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .id(toast.id)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { manager.toastFrame = $0 }
                    .transition(reduceMotion ? .opacity : .islandPop)
            }
        }
        .ignoresSafeArea(edges: [.horizontal, .bottom])
    }
}

/// Starts as a small dark pill tucked under the Dynamic Island and grows to
/// full size, so the toast reads as coming out of it. Never from nothing:
/// the smallest it gets is a little wider than the island.
private struct IslandPop: ViewModifier {
    let progress: CGFloat   // 0 = tucked under the island, 1 = full size

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: 0.38 + 0.62 * progress, y: 0.5 + 0.5 * progress, anchor: .top)
            .offset(y: -14 * (1 - progress))
            .blur(radius: 6 * (1 - progress))
            .opacity(Double(min(1, progress * 2.2)))
    }
}

private extension AnyTransition {
    static var islandPop: AnyTransition {
        .modifier(active: IslandPop(progress: 0), identity: IslandPop(progress: 1))
    }
}

private struct ToastView: View {
    let toast: Toast
    @State private var dragY: CGFloat = 0
    @State private var pressed = false
    /// The contents arrive just after the capsule opens, one after another
    @State private var revealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tint: Color {
        switch toast.kind {
        case .success: return Color(hex: "34C759")
        case .info: return Color(hex: "8E8E93")
        case .destructive: return Color(hex: "FF453A")
        case .error: return Color(hex: "FF9F0A")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                // A little hop when it lands
                .symbolEffect(.bounce, value: revealed)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.18)))
                // Pops in with a playful spring
                .scaleEffect(revealed || reduceMotion ? 1 : 0.5)
                .opacity(revealed ? 1 : 0)
                .animation(.spring(duration: 0.45, bounce: 0.45).delay(0.08), value: revealed)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(toast.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let subtitle = toast.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(revealed ? 1 : 0)
            .offset(x: revealed || reduceMotion ? 0 : -6)
            .blur(radius: revealed || reduceMotion ? 0 : 3)
            .animation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.4).delay(0.13), value: revealed)

            if let action = toast.action {
                Button {
                    HapticManager.shared.light()
                    action.handler()
                    ToastManager.shared.dismiss()
                } label: {
                    Text(action.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "141417"))
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(Capsule().fill(.white))
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .scaleEffect(revealed || reduceMotion ? 1 : 0.8)
                .opacity(revealed ? 1 : 0)
                .animation(.spring(duration: 0.45, bounce: 0.35).delay(0.18), value: revealed)
            }
        }
        .onAppear { revealed = true }
        .padding(.leading, 10)
        .padding(.trailing, toast.action == nil ? 18 : 10)
        .padding(.vertical, 10)
        .frame(maxWidth: 420)
        .background(
            Capsule(style: .continuous)
                .fill(Color(hex: "1C1C1E"))
                .overlay(Capsule(style: .continuous).strokeBorder(.white.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
        )
        .environment(\.colorScheme, .dark)
        // A finger on it gives a little; pulling down stretches like taffy
        .scaleEffect(x: pressed ? 0.98 : 1, y: pressed ? 0.98 + min(max(dragY, 0), 40) * 0.002 : 1, anchor: .top)
        .animation(.spring(duration: 0.3, bounce: 0.3), value: pressed)
        // Swipe up to dismiss
        .offset(y: dragY)
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    if !pressed { pressed = true }
                    ToastManager.shared.setHeld(true)
                    let y = value.translation.height
                    dragY = y < 0 ? y : y * 0.15
                }
                .onEnded { value in
                    pressed = false
                    if value.translation.height < -24 || (value.translation.height < -8 && value.predictedEndTranslation.height < -60) {
                        ToastManager.shared.dismiss()
                    } else {
                        withAnimation(.spring(duration: 0.3, bounce: 0)) { dragY = 0 }
                        ToastManager.shared.setHeld(false)
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

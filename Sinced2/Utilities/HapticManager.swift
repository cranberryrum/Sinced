//
//  HapticManager.swift
//  Sinced2
//
//  Centralized haptic feedback management
//

import UIKit

/// Intensity / style for a single haptic event
enum HapticStyle {
    case soft
    case light
    case medium
    case rigid
    case heavy
    case selection
    case success
    case warning
}

/// A haptic cue tied to Lottie animation progress (0...1)
struct LottieHapticCue: Equatable {
    let progress: Double
    let style: HapticStyle
    
    init(progress: Double, style: HapticStyle) {
        self.progress = min(max(progress, 0), 1)
        self.style = style
    }
    
    /// Convenience from animation seconds + frame rate duration
    static func at(seconds: Double, duration: Double, style: HapticStyle) -> LottieHapticCue {
        LottieHapticCue(progress: seconds / max(duration, 0.001), style: style)
    }
}

/// Manager for triggering haptic feedback throughout the app
final class HapticManager {
    static let shared = HapticManager()
    
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {}
    
    /// Warm up generators so the first impact has lower latency
    func prepare() {
        softGenerator.prepare()
        lightGenerator.prepare()
        mediumGenerator.prepare()
        rigidGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func play(_ style: HapticStyle) {
        switch style {
        case .soft:
            softGenerator.impactOccurred(intensity: 0.7)
            softGenerator.prepare()
        case .light:
            lightGenerator.impactOccurred()
            lightGenerator.prepare()
        case .medium:
            mediumGenerator.impactOccurred()
            mediumGenerator.prepare()
        case .rigid:
            rigidGenerator.impactOccurred(intensity: 0.85)
            rigidGenerator.prepare()
        case .heavy:
            heavyGenerator.impactOccurred()
            heavyGenerator.prepare()
        case .selection:
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        case .success:
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
            notificationGenerator.prepare()
        }
    }
    
    /// Light impact haptic (for selections, taps)
    func light() {
        play(.light)
    }
    
    /// Medium impact haptic (for state changes)
    func medium() {
        play(.medium)
    }
    
    /// Soft impact (subtle landings)
    func soft() {
        play(.soft)
    }
    
    /// Rigid impact (crisper pops)
    func rigid() {
        play(.rigid)
    }
    
    /// Success notification haptic
    func success() {
        play(.success)
    }
    
    /// Warning notification haptic
    func warning() {
        play(.warning)
    }
    
    /// Selection haptic (for picker changes)
    func selection() {
        play(.selection)
    }
}

// MARK: - Onboarding Lottie timeline

extension LottieHapticCue {
    /// Synced cues for `Fadedproper` (8s @ 60fps).
    /// Derived from transform keyframe beats: intro settle → card pops → final shake → settle.
    static let fadedProperOnboarding: [LottieHapticCue] = {
        let duration = 8.0
        var cues: [LottieHapticCue] = [
            // Intro breathe-in
            .at(seconds: 0.08, duration: duration, style: .soft),
            // First element lands
            .at(seconds: 0.50, duration: duration, style: .light),
            // Theme cards stack in (~1s cadence)
            .at(seconds: 1.35, duration: duration, style: .medium),
            .at(seconds: 2.35, duration: duration, style: .medium),
            .at(seconds: 3.36, duration: duration, style: .rigid),
            .at(seconds: 4.36, duration: duration, style: .medium),
            .at(seconds: 5.36, duration: duration, style: .rigid),
        ]
        
        // Late jostle / shake (dense position keys on lead layer)
        for second in stride(from: 5.50, through: 5.90, by: 0.10) {
            cues.append(.at(seconds: second, duration: duration, style: .selection))
        }
        
        cues.append(contentsOf: [
            // Settle scale
            .at(seconds: 6.36, duration: duration, style: .medium),
            .at(seconds: 7.08, duration: duration, style: .light),
            // Hand-off into name step
            .at(seconds: 7.85, duration: duration, style: .success),
        ])
        
        return cues.sorted { $0.progress < $1.progress }
    }()
}

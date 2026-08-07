//
//  LottiePlayerView.swift
//  Sinced2
//
//  SwiftUI wrapper for Lottie animations with optional synced haptics
//

import SwiftUI
import Lottie
import QuartzCore

struct LottiePlayerView: UIViewRepresentable {
    let name: String
    var loopMode: LottieLoopMode = .playOnce
    var contentMode: UIView.ContentMode = .scaleAspectFill
    /// Progress-based haptic cues fired as the animation advances (0...1)
    var hapticCues: [LottieHapticCue] = []
    var onFinished: (() -> Void)?

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        if let animation = LottieAnimation.named(name, bundle: .main) {
            animationView.animation = animation
        } else if let path = Bundle.main.path(forResource: name, ofType: "json") {
            animationView.animation = LottieAnimation.filepath(path)
        }
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.isUserInteractionEnabled = false
        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        context.coordinator.hapticCues = hapticCues
        context.coordinator.onFinished = onFinished
        
        guard !context.coordinator.hasPlayed else { return }
        context.coordinator.hasPlayed = true
        
        HapticManager.shared.prepare()
        context.coordinator.startProgressTracking(on: uiView)

        uiView.play { finished in
            context.coordinator.stopProgressTracking()
            if finished {
                // Fire any remaining cues that sat at the end
                context.coordinator.flushRemainingCues(progress: 1.0)
                DispatchQueue.main.async {
                    context.coordinator.onFinished?()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(hapticCues: hapticCues, onFinished: onFinished)
    }
    
    static func dismantleUIView(_ uiView: LottieAnimationView, coordinator: Coordinator) {
        coordinator.stopProgressTracking()
        uiView.stop()
    }

    final class Coordinator {
        var hasPlayed = false
        var hapticCues: [LottieHapticCue]
        var onFinished: (() -> Void)?
        
        private var nextCueIndex = 0
        private var displayLink: CADisplayLink?
        private weak var animationView: LottieAnimationView?
        
        init(hapticCues: [LottieHapticCue], onFinished: (() -> Void)?) {
            self.hapticCues = hapticCues.sorted { $0.progress < $1.progress }
            self.onFinished = onFinished
        }
        
        func startProgressTracking(on animationView: LottieAnimationView) {
            stopProgressTracking()
            nextCueIndex = 0
            self.animationView = animationView
            
            guard !hapticCues.isEmpty else { return }
            
            let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
        
        func stopProgressTracking() {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        @objc private func handleDisplayLink() {
            guard let animationView else { return }
            // realtimeAnimationProgress stays accurate even if the run loop jitters
            fireCues(upTo: Double(animationView.realtimeAnimationProgress))
        }
        
        func flushRemainingCues(progress: Double) {
            fireCues(upTo: progress)
        }
        
        private func fireCues(upTo progress: Double) {
            guard nextCueIndex < hapticCues.count else {
                if progress >= 1.0 {
                    stopProgressTracking()
                }
                return
            }
            
            while nextCueIndex < hapticCues.count,
                  hapticCues[nextCueIndex].progress <= progress + 0.001 {
                let cue = hapticCues[nextCueIndex]
                nextCueIndex += 1
                HapticManager.shared.play(cue.style)
            }
            
            if nextCueIndex >= hapticCues.count {
                stopProgressTracking()
            }
        }
        
        deinit {
            stopProgressTracking()
        }
    }
}

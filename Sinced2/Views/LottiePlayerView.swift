//
//  LottiePlayerView.swift
//  Sinced2
//
//  SwiftUI wrapper for Lottie animations
//

import SwiftUI
import Lottie

struct LottiePlayerView: UIViewRepresentable {
    let name: String
    var loopMode: LottieLoopMode = .playOnce
    var contentMode: UIView.ContentMode = .scaleAspectFill
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
        guard !context.coordinator.hasPlayed else { return }
        context.coordinator.hasPlayed = true

        uiView.play { finished in
            if finished {
                DispatchQueue.main.async {
                    onFinished?()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var hasPlayed = false
    }
}

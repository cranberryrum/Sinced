//
//  GrainBackground.swift
//  Sinced2
//
//  Subtle film grain laid over screen backgrounds for a softer, printed feel
//

import SwiftUI
import UIKit

/// A small tile of random dark specks, generated once and repeated across the screen
enum GrainTexture {
    static let image: UIImage = {
        let side = 160
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        for i in 0..<(side * side) {
            // Squaring keeps most specks faint with a few darker ones
            let value = Double.random(in: 0...1)
            pixels[i * 4 + 3] = UInt8(value * value * 255)
        }

        let cgImage = pixels.withUnsafeMutableBytes { buffer -> CGImage? in
            CGContext(
                data: buffer.baseAddress,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )?.makeImage()
        }

        // Scale 2 makes each speck about 1.5 pixels on a 3x screen, closer to film grain
        return cgImage.map { UIImage(cgImage: $0, scale: 2, orientation: .up) } ?? UIImage()
    }()
}

/// Tiled grain on its own, for layering over a background color
struct GrainOverlay: View {
    var intensity: Double = GrainOverlay.defaultIntensity

    static let defaultIntensity = 0.1

    var body: some View {
        Image(uiImage: GrainTexture.image)
            .resizable(resizingMode: .tile)
            .opacity(intensity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// A full-screen color with grain on top
struct GrainBackground: View {
    var color: Color = Color(UIColor.systemBackground)

    var body: some View {
        ZStack {
            color
            GrainOverlay()
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Puts a grainy background behind the view, edge to edge
    func grainBackground(_ color: Color = Color(UIColor.systemBackground)) -> some View {
        background { GrainBackground(color: color) }
    }

    /// Hides a List's own background and shows a grainy grouped one instead
    func grainListBackground() -> some View {
        scrollContentBackground(.hidden)
            .grainBackground(Color(UIColor.systemGroupedBackground))
    }
}

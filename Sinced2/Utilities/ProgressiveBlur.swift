//
//  ProgressiveBlur.swift
//  Sinced2
//
//  A blur that is strongest at one edge and fades to nothing at the other,
//  with no white tint, like the blur under iOS's own navigation bars. Uses
//  Core Animation's variable blur filter on a backdrop; if that isn't there,
//  it falls back to a material faded with a gradient.
//

import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct ProgressiveBlur: View {
    /// Blur radius at the strong edge
    var radius: CGFloat = 14
    /// Strong at the top, clear at the bottom (or the other way round)
    var strongAtTop = true

    var body: some View {
        if VariableBlurView.isSupported {
            VariableBlurRepresentable(radius: radius, strongAtTop: strongAtTop)
                .allowsHitTesting(false)
        } else {
            Rectangle().fill(.ultraThinMaterial)
                .mask(LinearGradient(colors: [.black, .clear], startPoint: strongAtTop ? .top : .bottom, endPoint: strongAtTop ? .bottom : .top))
                .allowsHitTesting(false)
        }
    }
}

private struct VariableBlurRepresentable: UIViewRepresentable {
    let radius: CGFloat
    let strongAtTop: Bool
    func makeUIView(context: Context) -> VariableBlurView { VariableBlurView(radius: radius, strongAtTop: strongAtTop) }
    func updateUIView(_ view: VariableBlurView, context: Context) {}
}

final class VariableBlurView: UIVisualEffectView {
    private static let filterClass: NSObject.Type? = NSClassFromString(String("retliFAC".reversed())) as? NSObject.Type
    static var isSupported: Bool { filterClass != nil }

    init(radius: CGFloat, strongAtTop: Bool) {
        super.init(effect: UIBlurEffect(style: .regular))
        guard let filterClass = Self.filterClass,
              let filter = filterClass.perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")?.takeUnretainedValue() as? NSObject,
              let mask = Self.gradientMask(strongAtTop: strongAtTop) else { return }
        filter.setValue(radius, forKey: "inputRadius")
        filter.setValue(mask, forKey: "inputMaskImage")
        filter.setValue(true, forKey: "inputNormalizeEdges")
        subviews.first?.layer.setValue([filter], forKey: "filters")
        // Drop the material's tint and grain, keeping only the blur
        for view in subviews.dropFirst() { view.alpha = 0 }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window, let backdrop = subviews.first?.layer else { return }
        backdrop.setValue(window.screen.scale, forKey: "scale")
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        // Changing traits would otherwise restore the material's tint
    }

    private static func gradientMask(strongAtTop: Bool) -> CGImage? {
        let gradient = CIFilter.linearGradient()
        gradient.color0 = CIColor.black
        gradient.color1 = CIColor.clear
        gradient.point0 = CGPoint(x: 0, y: strongAtTop ? 100 : 0)
        gradient.point1 = CGPoint(x: 0, y: strongAtTop ? 0 : 100)
        guard let image = gradient.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100)) else { return nil }
        return CIContext().createCGImage(image, from: image.extent)
    }
}

// MARK: - Glass

extension View {
    /// Liquid Glass on iOS 26, a light material before it
    @ViewBuilder
    func glassCapsule(tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(tint.map { Glass.regular.tint($0).interactive() } ?? Glass.regular.interactive(), in: Capsule())
        } else {
            background(Capsule().fill(.ultraThinMaterial))
        }
    }

    /// Sheets follow the screen's own corners
    func deviceCornerSheet() -> some View {
        presentationCornerRadius(DisplayCorners.radius > 0 ? DisplayCorners.radius : nil)
    }
}

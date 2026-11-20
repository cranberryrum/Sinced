// Renders og.html to sinced-og@2x.png (2400 × 1260 on a Retina Mac) with WebKit.
// Run: swift render.swift && sips -Z 1200 sinced-og@2x.png --out sinced-og.png

import AppKit
import WebKit

let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let page = dir.appendingPathComponent("og.html")
let size = CGSize(width: 1200, height: 630)

final class Renderer: NSObject, WKNavigationDelegate {
    let web: WKWebView
    init(frame: CGRect) {
        web = WKWebView(frame: frame, configuration: WKWebViewConfiguration())
        super.init()
        web.navigationDelegate = self
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait for web fonts and images before taking the snapshot
        webView.evaluateJavaScript(
            "Promise.all([document.fonts.ready, ...[...document.images].map(i => i.decode())]).then(() => true)"
        ) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.snap(scales: [1]) }
        }
    }

    func snap(scales: [CGFloat]) {
        guard let scale = scales.first else { exit(0) }
        let config = WKSnapshotConfiguration()
        config.rect = CGRect(origin: .zero, size: size)
        config.snapshotWidth = NSNumber(value: Double(size.width * scale))
        config.afterScreenUpdates = true
        web.takeSnapshot(with: config) { image, error in
            guard let image, let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else {
                print("snapshot failed:", error?.localizedDescription ?? "unknown"); exit(1)
            }
            // Snapshots come out at the screen's backing scale, so on a Retina Mac this is 2400 × 1260
            let name = "sinced-og@2x.png"
            let out = dir.appendingPathComponent(name)
            try! rep.representation(using: .png, properties: [:])!.write(to: out)
            print("wrote", out.path, "\(rep.pixelsWide)×\(rep.pixelsHigh)")
            self.snap(scales: Array(scales.dropFirst()))
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
let renderer = Renderer(frame: CGRect(origin: .zero, size: size))
window.contentView = renderer.web
renderer.web.loadFileURL(page, allowingReadAccessTo: dir.deletingLastPathComponent())
app.run()

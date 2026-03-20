//
//  ShareableCardView.swift
//  Sinced2
//
//  Beautiful shareable card design for social media sharing
//

import SwiftUI

/// Themes for the shareable card
enum ShareTheme: String, CaseIterable, Identifiable {
    case image = "Image"
    case blue = "Blue"
    case green = "Green"
    case red = "Red"
    
    var id: String { self.rawValue }
    
    var backgroundColor: Color {
        switch self {
        case .image: return .clear
        case .blue: return Color(hex: "3B7BF6")
        case .green: return Color(hex: "2D6A4F")
        case .red: return Color(hex: "E63946")
        }
    }
    
    var assetName: String? {
        switch self {
        case .image: return nil
        case .blue: return "ShareCardBlue"
        case .green: return "ShareCardGreen"
        case .red: return "ShareCardRed"
        }
    }
}

/// The shareable card view that gets rendered to an image
struct ShareableCardView: View {
    let event: SinceEvent
    let cardSize: CGSize
    let theme: ShareTheme
    
    init(event: SinceEvent, cardSize: CGSize = CGSize(width: 1080, height: 1080), theme: ShareTheme = .image) {
        self.event = event
        self.cardSize = cardSize
        self.theme = theme
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content overlay
            if theme == .image {
                defaultLayout
            } else {
                themedLayout
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }
    
    @ViewBuilder
    private var defaultLayout: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: cardSize.height * 0.15)
            
            // Event Title
            Text(event.title)
                .font(.system(size: cardSize.width * 0.07, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, cardSize.width * 0.1)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Since date
            Text("Since \(formattedStartDate)")
                .font(.system(size: cardSize.width * 0.035, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, cardSize.height * 0.015)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Spacer()
            
            // Large Time Value
            Text("\(timeValue)")
                .font(.system(size: cardSize.width * 0.22, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            
            // Unit Label
            Text(unitLabel.uppercased())
                .font(.system(size: cardSize.width * 0.055, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .tracking(4)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Spacer()
                .frame(height: cardSize.height * 0.12)
            
            // App branding with logo and App Store call-to-action
            VStack(spacing: cardSize.height * 0.012) {
                // App icon and name
                HStack(spacing: cardSize.width * 0.02) {
                    AppIconView(size: cardSize.width * 0.06, hasImageBackground: true)
                    
                    Text("Sinced")
                        .font(.system(size: cardSize.width * 0.035, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Download CTA
                Text("Download Sinced on App Store")
                    .font(.system(size: cardSize.width * 0.025, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
            .padding(.bottom, cardSize.height * 0.05)
        }
    }
    
    @ViewBuilder
    private var themedLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            // Main Content Area
            VStack(alignment: .leading, spacing: 0) {
                // Large Time and Unit - Proportions from Figma (32/492 ≈ 0.065)
                Text("\(timeValue) \(unitLabel)".uppercased())
                    .font(.system(size: cardSize.width * 0.085, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                // Event Title - Proportions from Figma (20/492 ≈ 0.04)
                Text("Since \(event.title)")
                    .font(.system(size: cardSize.width * 0.053, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, cardSize.height * 0.005)
            }
            .padding(.leading, 16 * (cardSize.width / 375.0))
            .padding(.bottom, 16 * (cardSize.width / 375.0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if theme == .image, let imageData = event.imageData, let uiImage = UIImage(data: imageData) {
            // Image background with overlay
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardSize.width, height: cardSize.height)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
            // Use the actual image assets provided
            if let assetName = theme.assetName {
                Image(assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardSize.width, height: cardSize.height)
                    .clipped()
            } else {
                theme.backgroundColor
            }
        }
    }
    
    // Pattern overlay and circlePatternItem are no longer needed as we use image assets
    
    private var hasImage: Bool {
        event.imageData != nil
    }
    
    private var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: event.startedAt)
    }
    
    private var timeValue: Int {
        let elapsed = Date().timeIntervalSince(event.startedAt)
        
        switch event.widgetTimeUnit {
        case .hours:
            return Int(elapsed / 3600)
        case .days:
            return Int(elapsed / 86400)
        case .months:
            return Int(elapsed / (86400 * 30))
        case .years:
            return Int(elapsed / (86400 * 365))
        }
    }
    
    private var unitLabel: String {
        let value = timeValue
        switch event.widgetTimeUnit {
        case .hours:
            return value == 1 ? "Hour" : "Hours"
        case .days:
            return value == 1 ? "Day" : "Days"
        case .months:
            return value == 1 ? "Month" : "Months"
        case .years:
            return value == 1 ? "Year" : "Years"
        }
    }
}

/// App icon view that loads the app icon from the bundle
struct AppIconView: View {
    let size: CGFloat
    let hasImageBackground: Bool
    
    var body: some View {
        Group {
            if let appIcon = getAppIcon() {
                Image(uiImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Fallback: styled app icon representation
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .fill(
                            LinearGradient(
                                colors: [Color.primaryBlue, Color.primaryBlue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "timer")
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.2)
                .stroke(hasImageBackground ? Color.white.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func getAppIcon() -> UIImage? {
        // Try to load from the AppLogo asset
        if let image = UIImage(named: "AppLogo") {
            return image
        }
        
        // Fallback: try to get the app icon from the bundle
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        
        return nil
    }
}

/// Preview-sized shareable card for the share sheet
struct ShareableCardPreview: View {
    let event: SinceEvent
    let theme: ShareTheme
    
    init(event: SinceEvent, theme: ShareTheme = .image) {
        self.event = event
        self.theme = theme
    }
    
    var body: some View {
        ShareableCardView(event: event, cardSize: CGSize(width: 300, height: 300), theme: theme)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(theme.backgroundColor)
                    // Figma Shadow 1: Outer soft shadow (spread 4 is added to radius for similar effect)
                    .shadow(color: .black.opacity(0.25), radius: 25, x: 0, y: 4)
                    // Figma Shadow 2: Sharp subtle shadow
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 0)
            )
            .overlay(
                // Figma Shadow 3: 2px "border" shadow
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.black.opacity(0.1), lineWidth: 2)
            )
    }
}

// MARK: - Image Rendering Extension

extension View {
    /// Renders the view to a UIImage
    @MainActor
    func renderToImage(size: CGSize, scale: CGFloat = 2.0) -> UIImage? {
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = scale // Optimized scale for good quality and smaller file size
        return renderer.uiImage
    }
    
    /// Renders the view to optimized JPEG data
    @MainActor
    func renderToJPEGData(size: CGSize, scale: CGFloat = 2.0, compressionQuality: CGFloat = 0.85) -> Data? {
        guard let image = renderToImage(size: size, scale: scale) else { return nil }
        return image.jpegData(compressionQuality: compressionQuality)
    }
}

#Preview("Without Image") {
    VStack {
        ShareableCardPreview(
            event: SinceEvent(
                title: "No smoking",
                startedAt: Date().addingTimeInterval(-200 * 3600),
                widgetTimeUnit: .hours
            ),
            theme: .blue
        )
        
        ShareableCardPreview(
            event: SinceEvent(
                title: "No smoking",
                startedAt: Date().addingTimeInterval(-200 * 3600),
                widgetTimeUnit: .hours
            ),
            theme: .green
        )
        
        ShareableCardPreview(
            event: SinceEvent(
                title: "No smoking",
                startedAt: Date().addingTimeInterval(-200 * 3600),
                widgetTimeUnit: .hours
            ),
            theme: .red
        )
    }
    .padding()
}

#Preview("With Image") {
    ShareableCardPreview(
        event: SinceEvent(
            title: "Started Running",
            startedAt: Date().addingTimeInterval(-45 * 86400),
            imageData: UIImage(systemName: "photo.fill")?.pngData(),
            widgetTimeUnit: .days
        )
    )
    .padding()
}


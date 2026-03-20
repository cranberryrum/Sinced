//
//  LargeEventCardView.swift
//  Sinced2
//
//  Large event card for the redesigned home screen with theme backgrounds
//

import SwiftUI
import Combine

struct LargeEventCardView: View {
    let event: SinceEvent
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - Theme SVG or Custom Image
                backgroundView
                
                // Content overlay
                VStack(spacing: 16) {
                    // Time display in mono font
                    VStack(spacing: 4) {
                        Text(event.largeCardTimeValue())
                            .font(.custom("GeistMono-Medium", size: 40))
                            .fontWeight(.medium)
                            .tracking(-3.2)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
                        
                        // Event name
                        Text("Since \(event.title)")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
                    }
                    
                    // Started date badge
                    Text("Started on \(formatStartDate())")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .tracking(-0.64)
                        .foregroundColor(event.cardTheme == .custom ? .black : event.cardTheme.badgeTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(event.cardTheme == .custom ? .white : event.cardTheme.badgeBackgroundColor)
                        )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 42))
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if event.cardTheme == .custom,
           let imageData = event.imageData,
           let uiImage = UIImage(data: imageData) {
            // Custom image background
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .overlay(
                    // Subtle dark overlay for text readability
                    Color.black.opacity(0.3)
                )
        } else {
            // Theme background with SVG overlay
            ZStack {
                // Solid background color
                event.cardTheme.backgroundColor
                
                // SVG pattern overlay
                if let assetName = event.cardTheme.svgAssetName {
                    GeometryReader { geo in
                        Image(assetName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            }
        }
    }
    
    private func formatStartDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: event.startedAt)
    }
}

#Preview {
    LargeEventCardView(
        event: SinceEvent(
            title: "No smoking",
            startedAt: Date().addingTimeInterval(-86400 * 8),
            cardTheme: .mosaic
        )
    )
    .frame(height: 700)
    .padding()
}


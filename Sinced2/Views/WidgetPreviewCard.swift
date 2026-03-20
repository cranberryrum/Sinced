//
//  WidgetPreviewCard.swift
//  Sinced2
//
//  Widget configuration card with real-time preview
//

import SwiftUI
import Combine

struct WidgetPreviewCard: View {
    @Binding var event: SinceEvent
    @ObservedObject var viewModel: EventViewModel
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Widget Configuration")
                    .font(.roundedHeadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Widget Preview (1:1 aspect ratio with proper constraints)
            GeometryReader { geometry in
                WidgetPreviewView(event: event, currentTime: currentTime)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            }
            .aspectRatio(1.0, contentMode: .fit)
            
            // Native Segmented Control
            Picker("Time Unit", selection: Binding(
                get: { event.widgetTimeUnit },
                set: { newValue in
                    event.widgetTimeUnit = newValue
                    viewModel.updateEvent(event)
                }
            )) {
                ForEach(WidgetTimeUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

/// Widget preview view matching the design
struct WidgetPreviewView: View {
    let event: SinceEvent
    let currentTime: Date
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Image with 1:1 fill
                if let imageData = event.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    // Placeholder if no image
                    Color(hex: "e5e5e5")
                }
                
                // Gradient overlay (covering bottom 40% of image)
                VStack(spacing: 0) {
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.01),
                            Color.black.opacity(1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.4) // 40% of height
                    .blur(radius: 2)
                }
                
                // Content overlay
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()
                    
                    // Main heading: time value (larger and more prominent)
                    Text(formatTimeValueForWidget(event: event))
                        .font(.rounded(min(geometry.size.width * 0.15, 56), weight: .bold))
                        .foregroundColor(.white)
                        .tracking(-2.24)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    
                    // Subheading: event name
                    Text("since \(event.title)")
                        .font(.rounded(min(geometry.size.width * 0.05, 18), weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                        .tracking(-0.72)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .padding(min(geometry.size.width * 0.05, 20))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }
    
    /// Format time value for widget display (e.g., "12 days" becomes "12 days")
    private func formatTimeValueForWidget(event: SinceEvent) -> String {
        let elapsed = event.elapsedTime
        
        switch event.widgetTimeUnit {
        case .hours:
            let hours = Int(elapsed / 3600)
            return "\(hours) \(hours == 1 ? "hour" : "hours")"
        case .days:
            let days = Int(elapsed / 86400)
            return "\(days) \(days == 1 ? "day" : "days")"
        case .months:
            let months = Int(elapsed / (86400 * 30))
            return "\(months) \(months == 1 ? "month" : "months")"
        case .years:
            let years = Int(elapsed / (86400 * 365))
            return "\(years) \(years == 1 ? "year" : "years")"
        }
    }
}

/// Time unit selection button
struct TimeUnitButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .primaryBlue)
                .tracking(-0.56)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? .primaryBlue : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primaryBlue, lineWidth: 1.5)
                )
        }
    }
}

#Preview {
    let sampleEvent = SinceEvent(
        title: "dog walk",
        startedAt: Date().addingTimeInterval(-3600 * 24 * 12),
        imageData: nil,
        widgetTimeUnit: .days
    )
    
    WidgetPreviewCard(event: .constant(sampleEvent), viewModel: EventViewModel())
}


//
//  AnimatedTickerView.swift
//  Sinced2
//
//  Native SwiftUI numeric text transitions for time values
//

import SwiftUI

/// Animated text wrapper that uses the system numeric rolling transition.
struct AnimatedTickerView: View {
    let text: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
            .monospacedDigit()
            .foregroundColor(color)
            .contentTransition(.numericText())
            .animation(.smooth(duration: 0.35), value: text)
    }
}

/// Complete animated time display component
struct AnimatedTimeDisplay: View {
    let event: SinceEvent
    let currentTime: Date
    
    var body: some View {
        VStack(spacing: 8) {
            // Use the native numeric text transition for Apple-style rolling digits.
            AnimatedNumberOnly(
                number: getTimeValue(),
                fontSize: 72,
                color: .primaryBlue
            )
            
            Text("\(getUnitSuffix()) since")
                .font(.roundedBody)
                .foregroundColor(.secondary)
                .contentTransition(.interpolate)
                .animation(.smooth(duration: 0.35), value: event.widgetTimeUnit)
        }
    }
    
    private func getTimeValue() -> Int {
        let elapsed = currentTime.timeIntervalSince(event.startedAt)
        
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
    
    private func getUnitSuffix() -> String {
        let value = getTimeValue()
        
        switch event.widgetTimeUnit {
        case .hours:
            return value == 1 ? "hour" : "hours"
        case .days:
            return value == 1 ? "day" : "days"
        case .months:
            return value == 1 ? "month" : "months"
        case .years:
            return value == 1 ? "year" : "years"
        }
    }
}

/// Animated number only (no suffix) using the native system rolling animation.
struct AnimatedNumberOnly: View {
    let number: Int
    let fontSize: CGFloat
    let color: Color
    
    var body: some View {
        Text(numberString)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(color)
            .contentTransition(.numericText(value: Double(number)))
            .animation(.smooth(duration: 0.35), value: number)
            .fixedSize(horizontal: true, vertical: true)
    }
    
    private var numberString: String {
        "\(number)"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        AnimatedTickerView(text: "42", fontSize: 48, fontWeight: .bold, color: .primaryBlue)
        AnimatedNumberOnly(number: 365, fontSize: 56, color: .blue)
    }
    .padding()
}

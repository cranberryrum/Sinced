//
//  TipThankYouSheet.swift
//  Sinced2
//
//  Rises after a tip goes through: the tier's icon with a small burst of
//  hearts, a thank-you in the developer's voice, and a way to say hi.
//

import SwiftUI

struct TipThankYouSheet: View {
    let thanks: TipJar.Thanks
    let firstName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private static let noteURL = URL(string: "mailto:adityakoltedes@gmail.com?subject=I%20just%20tipped%20Sinced")!

    private var tierLine: String {
        switch thanks.tier.name {
        case "Coffee": return "A coffee on you. That means more than you’d think."
        case "Lunch": return "Lunch is on you, and it means a lot."
        default: return "Dinner? That’s incredibly generous."
        }
    }

    private var ordinal: String {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        return f.string(from: NSNumber(value: thanks.count)) ?? "\(thanks.count)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HeartBurst(tier: thanks.tier)
                .padding(.top, 36)
                .padding(.bottom, 22)

            if thanks.count > 1 {
                Text("Your \(ordinal) tip")
                    .font(.allo(13, weight: .semibold))
                    .foregroundStyle(thanks.tier.tint)
                    .padding(.horizontal, 12)
                    .frame(height: 26)
                    .background(Capsule().fill(thanks.tier.tint.opacity(0.12)))
                    .padding(.bottom, 12)
                    .sheetEntrance(1)
            }

            (Text("Thank you") + Text(firstName.isEmpty ? "." : ", \(firstName).")
                .foregroundColor(CardText.word))
                .font(.allo(28, weight: .semibold))
                .foregroundStyle(CardText.word)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .sheetEntrance(1)

            Text("\(tierLine) Sinced is made by one person, with no ads and no account. Tips like yours keep it that way.")
                .font(.allo(16))
                .foregroundStyle(CardText.label)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
                .sheetEntrance(2)

            HStack(spacing: 8) {
                Image("DeveloperPhoto")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                Text("Aditya, who makes Sinced")
                    .font(.allo(14, weight: .medium))
                    .foregroundStyle(CardText.word)
            }
            .padding(.leading, 4)
            .padding(.trailing, 14)
            .frame(height: 34)
            .background(Capsule().fill(CardText.fill))
            .padding(.bottom, 28)
            .sheetEntrance(3)

            VStack(spacing: 6) {
                Button("You’re welcome") {
                    HapticManager.shared.light()
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle(color: CardText.word))

                Button {
                    HapticManager.shared.light()
                    openURL(Self.noteURL)
                } label: {
                    Text("Send Aditya a note")
                        .font(.allo(16, weight: .medium))
                        .foregroundStyle(CardText.label)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .sheetEntrance(4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .sheetHeightPart()
        .frame(maxHeight: .infinity, alignment: .top)
        .fittedSheet(estimate: 520)
        .presentationDragIndicator(.visible)
        .onAppear { HapticManager.shared.success() }
    }
}

/// The tier's icon pops in, and a ring of small hearts bursts out and drifts away
private struct HeartBurst: View {
    let tier: TipJar.Tier
    @State private var popped = false
    @State private var burst = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let hearts = 8

    var body: some View {
        ZStack {
            if !reduceMotion {
                ForEach(0..<hearts, id: \.self) { i in
                    let angle = Angle.degrees(Double(i) / Double(hearts) * 360 - 90)
                    let distance: CGFloat = burst ? (i.isMultiple(of: 2) ? 78 : 62) : 20
                    Image(systemName: "heart.fill")
                        .font(.system(size: i.isMultiple(of: 2) ? 13 : 10, weight: .bold))
                        .foregroundStyle(i.isMultiple(of: 3) ? Color(hex: "E0605E") : tier.tint)
                        .offset(x: cos(angle.radians) * distance, y: sin(angle.radians) * distance - (burst ? 10 : 0))
                        .scaleEffect(burst ? 1 : 0.2)
                        .opacity(burst ? 0 : 1)
                }
            }

            Circle()
                .fill(tier.tint.opacity(0.14))
                .frame(width: 96, height: 96)
            Image(systemName: tier.symbol)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(tier.tint)
        }
        .frame(width: 180, height: 110)
        .scaleEffect(popped ? 1 : 0.6)
        .opacity(popped ? 1 : 0)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.12)) { popped = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.22)) { burst = true }
        }
    }
}

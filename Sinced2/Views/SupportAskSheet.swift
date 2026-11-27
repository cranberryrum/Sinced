//
//  SupportAskSheet.swift
//  Sinced2
//
//  The occasional ask for a tip: opens on the moment that earned it, then
//  the three tiers, ready to pay with one tap.
//

import SwiftUI

struct SupportAskSheet: View {
    let ask: SupportPrompter.Ask
    let firstName: String

    @ObservedObject private var jar = TipJar.shared
    @Environment(\.dismiss) private var dismiss

    private static let bold = { (s: String) in
        Text(s).font(.allo(26, weight: .semibold)).foregroundColor(CardText.word)
    }

    private var headline: Text {
        let m = ask.moment
        let name = firstName.isEmpty ? Text(".") : Text(", ") + Self.bold(firstName) + Text(".")
        switch m.kind {
        case .milestone:
            return Self.bold("\(m.days) \(m.days == 1 ? "day" : "days")") + Text(" since ") + Self.bold(m.title) + name
        case .goal:
            return Text("You reached your ") + Self.bold("\(m.days)-day goal") + Text(" for ") + Self.bold(m.title) + Text(".")
        case .share:
            return Text("Thanks for sharing ") + Self.bold("Sinced") + name
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "heart.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "E0605E"))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(hex: "E0605E").opacity(0.12)))
                .symbolEffect(.bounce, options: .nonRepeating)
                .padding(.bottom, 18)
                .accessibilityHidden(true)
                .sheetEntrance(0)

            headline
                .font(.allo(26, weight: .medium))
                .foregroundStyle(CardText.connector)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)
                .accessibilityAddTraits(.isHeader)
                .sheetEntrance(1)

            Text("Sinced is made by one person, with no ads and no account. If it’s been useful, a tip helps keep it going.")
                .font(.allo(16))
                .foregroundStyle(CardText.label)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 24)
                .sheetEntrance(2)

            HStack(spacing: 8) {
                ForEach(TipJar.tiers) { tier in
                    TipTile(tier: tier, product: jar.products[tier.id], purchasing: jar.purchasing) {
                        HapticManager.shared.light()
                        Task { await jar.tip(tier, from: .prompt) }
                    }
                }
            }
            // Full height, so the prices never shrink to fit the sheet
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 16)
            .sheetEntrance(3)

            VStack(spacing: 0) {
                Button {
                    HapticManager.shared.light()
                    dismiss()
                } label: {
                    Text("Not now")
                        .font(.allo(17, weight: .semibold))
                        .foregroundStyle(CardText.word)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(CardText.fill))
                }
                .buttonStyle(TipAskButtonStyle())

                Button {
                    SupportPrompter.shared.optOut()
                    dismiss()
                } label: {
                    Text("Don’t ask again")
                        .font(.allo(14, weight: .medium))
                        .foregroundStyle(CardText.connector)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .disabled(jar.purchasing != nil)
            .sheetEntrance(4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .padding(.bottom, 8)
        .sheetHeightPart()
        .frame(maxHeight: .infinity, alignment: .top)
        .fittedSheet(estimate: 470)
        .presentationDragIndicator(.visible)
        // Stay put while Apple's payment sheet is up
        .interactiveDismissDisabled(jar.purchasing != nil)
        .onAppear { SupportPrompter.shared.recordAsk() }
        .onChange(of: jar.thanks?.id) { _, _ in
            // Tipped from here: close, and the thank-you rises once this is gone
            guard let thanks = jar.thanks, thanks.source == .prompt else { return }
            jar.thanks = nil
            SupportPrompter.shared.queueThanks(thanks)
            dismiss()
        }
    }
}

private struct TipAskButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

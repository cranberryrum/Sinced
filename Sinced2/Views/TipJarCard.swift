//
//  TipJarCard.swift
//  Sinced2
//
//  The tip jar on Settings: three tiers shown upfront in the buyer's own
//  currency. One tap opens Apple's payment sheet.
//

import StoreKit
import SwiftUI

struct TipJarCard: View {
    @ObservedObject private var jar = TipJar.shared
    @EnvironmentObject private var viewModel: EventViewModel

    private var firstName: String {
        viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ").first.map(String.init) ?? ""
    }

    var body: some View {
        // Nothing to offer (e.g. products not set up yet): leave Settings as it was
        if jar.loadState != .unavailable {
            VStack(alignment: .leading, spacing: 16) {
                header
                HStack(spacing: 8) {
                    ForEach(TipJar.tiers) { tier in
                        TipTile(tier: tier, product: jar.products[tier.id], purchasing: jar.purchasing) {
                            HapticManager.shared.light()
                            Task { await jar.tip(tier) }
                        }
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
            .task { await jar.loadProducts() }
            .sheet(item: Binding(
                get: { jar.thanks?.source == .settings ? jar.thanks : nil },
                set: { jar.thanks = $0 }
            )) { thanks in
                TipThankYouSheet(thanks: thanks, firstName: firstName)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: jar.hasTipped ? "heart.fill" : "heart")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(jar.hasTipped ? Color(hex: "E0605E") : CardText.word)
                .symbolEffect(.bounce, value: jar.tipCount)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 22)
                .padding(.top, 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(jar.hasTipped ? "Thanks for supporting Sinced" : "Support Sinced")
                    .font(.allo(16, weight: .medium))
                    .foregroundStyle(CardText.word)
                    .contentTransition(.opacity)
                Text(jar.hasTipped
                     ? "It keeps Sinced free and ad-free. Tip again anytime."
                     : "Sinced is free, with no ads, made by one person. A tip helps keep it that way.")
                    .font(.allo(13))
                    .foregroundStyle(CardText.label)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
        }
        .padding(.horizontal, 0)
        .padding(.top, 4)
        .animation(.easeOut(duration: 0.25), value: jar.hasTipped)
        .accessibilityElement(children: .combine)
    }
}

struct TipTile: View {
    let tier: TipJar.Tier
    let product: Product?
    let purchasing: String?
    let action: () -> Void

    private var isBusy: Bool { purchasing == tier.id }
    private var isDimmed: Bool { purchasing != nil && !isBusy }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(tier.tint.opacity(0.14))
                    if isBusy {
                        ProgressView().tint(tier.tint)
                    } else {
                        Image(systemName: tier.symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(tier.tint)
                    }
                }
                .frame(width: 42, height: 42)

                VStack(spacing: 1) {
                    Text(tier.name)
                        .font(.allo(13, weight: .medium))
                        .foregroundStyle(CardText.label)
                    Text(product?.displayPrice ?? "00.00")
                        .font(.allo(17, weight: .semibold))
                        .foregroundStyle(CardText.word)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .redacted(reason: product == nil ? .placeholder : [])
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(CardText.fill)
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(TipTileStyle())
        .disabled(product == nil || purchasing != nil)
        .opacity(isDimmed ? 0.45 : 1)
        .animation(.easeOut(duration: 0.2), value: purchasing)
        .accessibilityLabel(product.map { "Tip \($0.displayPrice), \(tier.name)" } ?? tier.name)
    }
}

/// Presses in a little more than a settings row, since it's a single bold tap
private struct TipTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

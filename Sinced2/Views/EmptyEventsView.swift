//
//  EmptyEventsView.swift
//  Sinced2
//
//  Empty state for home screen
//

import SwiftUI

struct EmptyEventsView: View {
    var title: String = "no events yet"
    var subtitle: String = "track your days since events"
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Image("4xPhoto")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                Text(title)
                    .font(.roundedTitle2)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

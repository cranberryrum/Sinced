//
//  OnboardingView.swift
//  Sinced2
//
//  Welcome screen shown on first launch
//

import SwiftUI
import Lottie

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showName = false
    @State private var lottieOpacity: Double = 1
    @State private var nameOpacity: Double = 0
    @State private var nameInput: String = ""
    @FocusState private var nameFieldFocused: Bool
    
    private var trimmedName: String {
        nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canContinue: Bool {
        !trimmedName.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            if !showName && !reduceMotion {
                LottiePlayerView(
                    name: "Fadedproper",
                    loopMode: .playOnce,
                    contentMode: .scaleAspectFit
                ) {
                    withAnimation(AppMotion.smooth(reduceMotion: reduceMotion)) {
                        lottieOpacity = 0
                    }
                    withAnimation(AppMotion.smooth(reduceMotion: reduceMotion).delay(0.1)) {
                        nameOpacity = 1
                        showName = true
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(1.0 / 3.0)
                .clipped()
                .opacity(lottieOpacity)
                .ignoresSafeArea()
                .transition(.opacity)
            }

            if showName || reduceMotion {
                nameView
                    .opacity(reduceMotion ? 1 : nameOpacity)
                    .transition(.opacity)
            }
        }
        .onAppear {
            guard reduceMotion else { return }
            showName = true
            nameOpacity = 1
        }
    }
    
    private var nameView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("What should we call you?")
                    .font(.roundedTitle2)
                    .multilineTextAlignment(.center)
                
                Text("This shows up in your settings and greeting.")
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                TextField("Your name", text: $nameInput)
                    .font(.roundedBody)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .focused($nameFieldFocused)
                
                Button(action: {
                    let sanitizedName = trimmedName
                    guard !sanitizedName.isEmpty else { return }
                    HapticManager.shared.success()
                    viewModel.updateUserName(sanitizedName)
                    viewModel.completeOnboarding()
                }) {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.5)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .onAppear {
            if nameInput.isEmpty {
                nameInput = viewModel.userName
            }
            nameFieldFocused = true
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(EventViewModel())
}



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
    @State private var showName = false
    @State private var lottieOpacity: Double = 1
    @State private var nameOpacity: Double = 0
    @State private var nameInput: String = ""
    @FocusState private var nameFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
                // The animation doesn't take touches, so a tap here skips the intro
                .onTapGesture(perform: revealName)

            if !showName {
                LottiePlayerView(
                    name: "Fadedproper",
                    loopMode: .playOnce,
                    contentMode: .scaleAspectFit,
                    onFinished: revealName
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(1.0 / 3.0)
                .clipped()
                .opacity(lottieOpacity)
                .ignoresSafeArea()
                .transition(.opacity)
            }

            // Grain sits above the animation so its shapes get the same
            // texture as the background, not just the empty space around them
            GrainOverlay()
                .ignoresSafeArea()

            if showName {
                nameView
                    .opacity(nameOpacity)
                    .transition(.opacity)
            }
        }
        .task {
            // Reduce Motion skips the animation; otherwise move on even if
            // playback never reports finishing (interrupted or failed to load)
            if !reduceMotion {
                try? await Task.sleep(for: Self.introTimeout)
            }
            revealName()
        }
    }

    /// The intro runs 8s; give it a little slack before moving on regardless
    private static let introTimeout: Duration = .seconds(9)

    private func revealName() {
        guard !showName else { return }
        withAnimation(.easeInOut(duration: 0.45)) {
            lottieOpacity = 0
        }
        withAnimation(.easeInOut(duration: 0.45).delay(0.1)) {
            nameOpacity = 1
            showName = true
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
                    viewModel.updateUserName(sanitizedName)
                    viewModel.completeOnboarding()
                }) {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.5)

                // A name is optional; it only personalises greetings
                Button("Skip") {
                    viewModel.completeOnboarding()
                }
                .font(.roundedBody)
                .foregroundColor(.secondary)
                .frame(height: 44)
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



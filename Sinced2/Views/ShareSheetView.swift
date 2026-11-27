//
//  ShareSheetView.swift
//  Sinced2
//
//  Share the card: the counter in one of three designs (Stamp, Month,
//  Sentence), square or story, always in its own theme. Save or share.
//

import SwiftUI
import Photos

struct ShareSheetView: View {
    let event: SinceEvent
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("share.design") private var designRaw = ShareDesign.stamp.rawValue
    @AppStorage("share.format") private var formatRaw = ShareFormat.square.rawValue
    @State private var isSharing = false
    @State private var showingSaveSuccess = false
    @State private var renderedImage: UIImage?
    @State private var optimizedImageData: Data?
    @State private var saveError: SaveError?
    @State private var didShareOrSave = false
    @Namespace private var knob

    private enum SaveError: Identifiable {
        case permissionDenied, failed
        var id: Self { self }
    }

    /// Set when sharing from a milestone or goal moment, for the message
    var moment: ShareMessage.Moment? = nil

    init(event: SinceEvent, moment: ShareMessage.Moment? = nil) {
        self.event = event
        self.moment = moment
    }

    private var design: ShareDesign { ShareDesign(rawValue: designRaw) ?? .stamp }
    private var format: ShareFormat { ShareFormat(rawValue: formatRaw) ?? .square }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            preview
            formatSwitch.padding(.top, 4)
            designPicker.padding(.top, 18)
            actions.padding(.top, 20)
        }
        .padding(.bottom, 12)
        .background(GrainBackground(color: Color(hex: "F3F2F0")).ignoresSafeArea())
        .presentationDetents([.large])
        .deviceCornerSheet()
        .presentationDragIndicator(.hidden)
        .task { await renderImage() }
        .onChange(of: designRaw) { _, _ in Task { await renderImage() } }
        .onChange(of: formatRaw) { _, _ in Task { await renderImage() } }
        .onDisappear {
            // Asked once this sheet is gone, so the two never stack
            if didShareOrSave {
                ReviewPrompter.considerAfterShare(events: [event])
                SupportPrompter.shared.noteShare(title: event.title)
            }
        }
        .alert(item: $saveError) { error in
            switch error {
            case .permissionDenied:
                return Alert(
                    title: Text("Can't save to Photos"),
                    message: Text("Allow Sinced to add photos in Settings to save your card."),
                    primaryButton: .default(Text("Open Settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .failed:
                return Alert(
                    title: Text("Couldn't save image"),
                    message: Text("Something went wrong saving your card. Please try again."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: Pieces

    private var topBar: some View {
        ZStack {
            Text("Share the card")
                .font(.allo(17, weight: .semibold))
                .foregroundStyle(CardText.word)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CardText.word)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white).shadow(color: .black.opacity(0.06), radius: 8, y: 2))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Close")
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var preview: some View {
        GeometryReader { proxy in
            let size = format.size
            let k = min((proxy.size.width - 64) / size.width, (proxy.size.height - 24) / size.height)
            ShareCard(event: event, design: design, format: format)
                .scaleEffect(k)
                .frame(width: size.width * k, height: size.height * k)
                .clipShape(RoundedRectangle(cornerRadius: 28 * k, style: .continuous))
                .shadow(color: .black.opacity(0.28), radius: 24, y: 18)
                .scaleEffect(isSharing ? 0.97 : 1)
                .id("\(designRaw)-\(formatRaw)")
                .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(.blurReplace).combined(with: .scale(scale: 0.97)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(design.name) card, \(format.name.lowercased())")
        }
        .frame(maxHeight: .infinity)
    }

    private var formatSwitch: some View {
        HStack(spacing: 0) {
            ForEach(ShareFormat.allCases) { f in
                let on = f == format
                Button {
                    guard !on else { return }
                    HapticManager.shared.selection()
                    withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.3)) { formatRaw = f.rawValue }
                } label: {
                    Text(f.name)
                        .font(.allo(14, weight: .semibold))
                        .foregroundStyle(on ? CardText.word : CardText.label)
                        .padding(.horizontal, 16)
                        .frame(height: 32)
                        .background {
                            if on {
                                Capsule().fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                                    .matchedGeometryEffect(id: "knob", in: knob)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.black.opacity(0.05)))
    }

    private var designPicker: some View {
        HStack(spacing: 14) {
            ForEach(ShareDesign.allCases) { d in
                let on = d == design
                Button {
                    guard !on else { return }
                    HapticManager.shared.selection()
                    withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.28)) { designRaw = d.rawValue }
                } label: {
                    VStack(spacing: 6) {
                        ShareCard(event: event, design: d, format: .square)
                            .scaleEffect(64 / 360)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.black.opacity(0.06)))
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(CardText.word, lineWidth: 2)
                                    .opacity(on ? 1 : 0)
                                    .scaleEffect(on ? 1 : 0.92)
                            )
                        Text(d.name)
                            .font(.allo(13, weight: .semibold))
                            .foregroundStyle(on ? CardText.word : CardText.label)
                    }
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(d.name)
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button(action: saveToPhotos) {
                HStack(spacing: 8) {
                    Image(systemName: showingSaveSuccess ? "checkmark" : "arrow.down.to.line")
                        .font(.system(size: 17, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                    Text(showingSaveSuccess ? "Saved" : "Save")
                        .font(.allo(17, weight: .semibold))
                        .contentTransition(.opacity)
                }
                .foregroundStyle(showingSaveSuccess ? Color.primaryGreen : CardText.word)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(Color.white).shadow(color: .black.opacity(0.05), radius: 8, y: 2))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(isSharing || showingSaveSuccess)

            Button(action: shareImage) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Share").font(.allo(17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(CardText.word))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(isSharing)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Rendering

    @MainActor
    private func renderImage() async {
        let card = ShareCard(event: event, design: design, format: format)
        renderedImage = card.renderToImage(size: format.size, scale: 3)
        optimizedImageData = renderedImage?.jpegData(compressionQuality: 0.9)
    }

    /// The streak, the event and a link to Sinced, sent along with the card
    private var shareText: String {
        ShareMessage.text(for: event, moment: moment)
    }

    private func shareImage() {
        isSharing = true
        
        Task {
            // Ensure image is rendered
            if renderedImage == nil {
                await renderImage()
            }
            
            guard let image = renderedImage else {
                isSharing = false
                return
            }
            
            await MainActor.run {
                // Share the UIImage (system will handle compression appropriately for each destination)
                let activityViewController = UIActivityViewController(
                    activityItems: [
                        image,
                        ShareMessageItem(message: shareText, subject: "\(ShareMessage.streak(for: event)) since \(event.title)", image: image)
                    ],
                    applicationActivities: nil
                )
                
                // Exclude some activity types that don't make sense for images
                activityViewController.excludedActivityTypes = [
                    .addToReadingList,
                    .assignToContact,
                    .openInIBooks
                ]
                
                let windowScene = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first { $0.activationState == .foregroundActive }
                if let windowScene,
                   let window = windowScene.windows.first(where: \.isKeyWindow) ?? windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    
                    // Find the topmost presented view controller
                    var topController = rootViewController
                    while let presented = topController.presentedViewController {
                        topController = presented
                    }
                    
                    activityViewController.popoverPresentationController?.sourceView = window
                    activityViewController.popoverPresentationController?.sourceRect = CGRect(
                        x: window.bounds.midX,
                        y: window.bounds.midY,
                        width: 0,
                        height: 0
                    )
                    
                    activityViewController.completionWithItemsHandler = { _, completed, _, _ in
                        isSharing = false
                        if completed { didShareOrSave = true }
                    }
                    
                    topController.present(activityViewController, animated: true)
                }
            }
        }
    }
    
    private func saveToPhotos() {
        isSharing = true
        
        Task {
            // Ensure image is rendered
            if optimizedImageData == nil {
                await renderImage()
            }
            
            guard let imageData = optimizedImageData else {
                isSharing = false
                saveError = .failed
                return
            }
            
            // Request photo library permission
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            
            guard status == .authorized || status == .limited else {
                await MainActor.run {
                    isSharing = false
                    saveError = .permissionDenied
                }
                return
            }
            
            // Save optimized JPEG to photo library
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    options.uniformTypeIdentifier = "public.jpeg"
                    request.addResource(with: .photo, data: imageData, options: options)
                }
                
                await MainActor.run {
                    // Show success feedback
                    withAnimation(.spring(duration: 0.3, bounce: 0)) {
                        showingSaveSuccess = true
                    }
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    isSharing = false
                    didShareOrSave = true
                    
                    // Reset after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // Quieter on the way back than on arrival
                        withAnimation(.easeOut(duration: 0.2)) {
                            showingSaveSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isSharing = false
                    saveError = .failed
                }
            }
        }
    }
}

#Preview {
    ShareSheetView(
        event: SinceEvent(
            title: "No smoking",
            startedAt: Date().addingTimeInterval(-200 * 3600),
            widgetTimeUnit: .hours
        )
    )
}

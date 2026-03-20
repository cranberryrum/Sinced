//
//  ShareSheetView.swift
//  Sinced2
//
//  Bottom sheet for sharing events with a beautiful card preview
//

import SwiftUI
import Photos
import PhotosUI

struct ShareSheetView: View {
    let event: SinceEvent
    @Environment(\.dismiss) var dismiss
    @State private var isSharing = false
    @State private var showingSaveSuccess = false
    @State private var renderedImage: UIImage?
    @State private var optimizedImageData: Data?
    @State private var selectedTheme: ShareTheme
    @State private var isChangingTheme = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var previewImageData: Data?
    @State private var showPhotoPicker = false
    
    init(event: SinceEvent) {
        self.event = event
        _selectedTheme = State(initialValue: ShareSheetView.defaultShareTheme(for: event))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 10)
                
                // Card Preview
                ZStack {
                    ShareableCardPreview(event: previewEvent, theme: selectedTheme)
                        .scaleEffect(isChangingTheme ? 0.97 : (isSharing ? 0.95 : 1.0))
                        .blur(radius: isChangingTheme ? 3 : 0)
                        .opacity(isChangingTheme ? 0.8 : 1.0)
                        .animation(.spring(response: 0.22, dampingFraction: 0.95), value: isChangingTheme)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSharing)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 30) // Extra vertical padding for shadows
                
                // Theme Selection
                VStack(spacing: 12) {
                    Text("Theme")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.4))
                    
                    HStack(spacing: 16) {
                        ForEach(themeOptions) { theme in
                            Button(action: {
                                handleThemeSelection(theme)
                            }) {
                                themeDot(for: theme)
                            }
                            .buttonStyle(ThemeDotButtonStyle())
                        }
                    }
                }
                .padding(.vertical, 10)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Share Button
                    Button(action: shareImage) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Share")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primaryBlue)
                        )
                    }
                    .disabled(isSharing)
                    
                    // Save to Photos Button
                    Button(action: saveToPhotos) {
                        HStack(spacing: 10) {
                            Image(systemName: showingSaveSuccess ? "checkmark" : "square.and.arrow.down")
                                .font(.system(size: 18, weight: .semibold))
                            Text(showingSaveSuccess ? "Saved!" : "Save to Photos")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(showingSaveSuccess ? .green : .primaryBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(showingSaveSuccess ? Color.green.opacity(0.1) : Color.primaryBlue.opacity(0.1))
                        )
                    }
                    .disabled(isSharing || showingSaveSuccess)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Share Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onAppear {
            // Pre-render the image
            Task {
                await renderImage()
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadPreviewImage(from: newItem)
            }
        }
    }
    
    private var themeOptions: [ShareTheme] {
        if event.imageData != nil {
            return ShareTheme.allCases
        }
        
        return [.blue, .green, .red, .image]
    }
    
    private var previewEvent: SinceEvent {
        var previewEvent = event
        previewEvent.imageData = previewImageData ?? event.imageData
        return previewEvent
    }
    
    private var currentImageData: Data? {
        previewImageData ?? event.imageData
    }
    
    private static func defaultShareTheme(for event: SinceEvent) -> ShareTheme {
        if event.imageData != nil {
            return .image
        }
        
        switch event.cardTheme {
        case .clouds:
            return .green
        case .circles, .puffs:
            return .blue
        case .mosaic, .eyes:
            return .red
        case .custom:
            return .blue
        }
    }
    
    @ViewBuilder
    private func themeDot(for theme: ShareTheme) -> some View {
        ZStack {
            if theme == .image {
                // Image theme circle
                if let imageData = currentImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "photo").font(.system(size: 12)).foregroundColor(.secondary))
                }
            } else {
                // Colored theme circle
                Circle()
                    .fill(theme.backgroundColor)
                    .frame(width: 36, height: 36)
            }
            
            // Selection ring with dissolve transition
            Circle()
                .stroke(Color.primaryBlue, lineWidth: 2)
                .frame(width: 44, height: 44)
                .opacity(selectedTheme == theme ? 1 : 0)
                .scaleEffect(selectedTheme == theme ? 1.0 : 0.8)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTheme)
        }
    }
    
    @MainActor
    private func renderImage() async {
        let size = CGSize(width: 1080, height: 1080)
        let cardView = ShareableCardView(event: previewEvent, cardSize: size, theme: selectedTheme)
        // Render at 2x scale for good quality while keeping file size reasonable
        renderedImage = cardView.renderToImage(size: size, scale: 2.0)
        // Pre-generate optimized JPEG data (0.85 quality keeps file around 2-6 MB)
        optimizedImageData = cardView.renderToJPEGData(size: size, scale: 2.0, compressionQuality: 0.85)
    }
    
    private func handleThemeSelection(_ theme: ShareTheme) {
        if theme == .image, event.imageData == nil, previewImageData == nil {
            HapticManager.shared.light()
            showPhotoPicker = true
            return
        }
        
        guard selectedTheme != theme else { return }
        
        HapticManager.shared.light()
        selectedTheme = theme
        animateThemeChange()
        
        Task {
            await renderImage()
        }
    }
    
    private func animateThemeChange() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.95)) {
            isChangingTheme = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.95)) {
                isChangingTheme = false
            }
        }
    }
    
    private func loadPreviewImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let processedData = processPreviewImage(uiImage) else {
                return
            }
            
            await MainActor.run {
                previewImageData = processedData
                selectedTheme = .image
                animateThemeChange()
            }
            
            await renderImage()
        } catch {
            print("Error loading preview image: \(error)")
        }
    }
    
    /// Keep preview images square and reasonably sized for sharing.
    private func processPreviewImage(_ image: UIImage) -> Data? {
        let size = min(image.size.width, image.size.height)
        let origin = CGPoint(
            x: (image.size.width - size) / 2,
            y: (image.size.height - size) / 2
        )
        
        guard let cgImage = image.cgImage?.cropping(to: CGRect(origin: origin, size: CGSize(width: size, height: size))) else {
            return image.jpegData(compressionQuality: 0.85)
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        let maxSize: CGFloat = 1200
        let scale = min(maxSize / size, 1)
        let newSize = CGSize(width: size * scale, height: size * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        croppedImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: 0.85)
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
                    activityItems: [image],
                    applicationActivities: nil
                )
                
                // Exclude some activity types that don't make sense for images
                activityViewController.excludedActivityTypes = [
                    .addToReadingList,
                    .assignToContact,
                    .openInIBooks
                ]
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
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
                    
                    activityViewController.completionWithItemsHandler = { _, _, _, _ in
                        isSharing = false
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
                return
            }
            
            // Request photo library permission
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            
            guard status == .authorized || status == .limited else {
                await MainActor.run {
                    isSharing = false
                    // Could show an alert here asking user to enable permissions in Settings
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingSaveSuccess = true
                    }
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    isSharing = false
                    
                    // Reset after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showingSaveSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isSharing = false
                    // Handle error - could show an alert
                    print("Error saving photo: \(error)")
                }
            }
        }
    }
}

/// Button style for theme dots with touch scale effect
struct ThemeDotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
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

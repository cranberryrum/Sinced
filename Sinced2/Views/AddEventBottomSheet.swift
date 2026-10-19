//
//  AddEventBottomSheet.swift
//  Sinced2
//
//  Bottom sheet for adding new events - matches new Figma design with image selection
//

import SwiftUI

/// Sheet for adding a new event, or editing an existing one when `editingEvent` is set
struct AddEventBottomSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: EventViewModel
    @Binding var isPresented: Bool
    /// The event being edited; nil when adding a new one
    let editingEvent: SinceEvent?
    
    @State private var eventTitle: String
    @State private var startDate: Date
    @State private var selectedImage: UIImage?
    @State private var selectedTheme: CardTheme
    /// Theme to fall back to if the photo picker is cancelled
    @State private var themeBeforeCustom: CardTheme
    /// Set when the user picks a new photo, so an unchanged photo isn't re-encoded
    @State private var didPickNewImage = false
    @State private var showImagePicker: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showTimePicker: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    init(viewModel: EventViewModel, isPresented: Binding<Bool>, editingEvent: SinceEvent? = nil) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.editingEvent = editingEvent
        
        let theme = editingEvent?.cardTheme ?? .mosaic
        let image = editingEvent?.imageData.flatMap(UIImage.init(data:))
        self._eventTitle = State(initialValue: editingEvent?.title ?? "")
        self._startDate = State(initialValue: editingEvent?.startedAt ?? Date())
        self._selectedImage = State(initialValue: theme == .custom ? image : nil)
        self._selectedTheme = State(initialValue: theme)
        self._themeBeforeCustom = State(initialValue: theme == .custom ? .mosaic : theme)
    }
    
    private var isEditing: Bool { editingEvent != nil }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit event" : "Add an event")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primaryBlue)
                    .tracking(-0.96)
                
                Spacer()
                
                // Close Button
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .background(Color(hex: "f3f3f3"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Event Title Input
                    HStack(spacing: 8) {
                        TextField("eg: last cigarette, no coffee", text: $eventTitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "313131"))
                            .tracking(-0.64)
                            .focused($isTextFieldFocused)
                            .onChange(of: eventTitle) { _, newValue in
                                if newValue.count > Self.maxTitleLength {
                                    eventTitle = String(newValue.prefix(Self.maxTitleLength))
                                }
                            }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 58)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "f7f7f7"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.04), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    
                    // Details Section
                    VStack(spacing: 12) {
                        HStack {
                            Text("Started on")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "a5a3a5"))
                                .tracking(-0.64)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button(action: { showDatePicker = true }) {
                                    Text(formatDate(startDate))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "0881f4"))
                                        .tracking(-0.64)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 36)
                                                .stroke(Color.black.opacity(0.04), lineWidth: 1)
                                        )
                                }
                                
                                Button(action: { showTimePicker = true }) {
                                    Text(formatTime(startDate))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "0881f4"))
                                        .tracking(-0.64)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 36)
                                                .stroke(Color.black.opacity(0.04), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        
                        Rectangle()
                            .fill(Color.black.opacity(0.04))
                            .frame(height: 1)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Card theme")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "a5a3a5"))
                                .tracking(-0.64)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(availableThemes) { theme in
                                        Button {
                                            HapticManager.shared.light()
                                            
                                            if theme == .custom {
                                                if selectedTheme != .custom {
                                                    themeBeforeCustom = selectedTheme
                                                }
                                                selectedTheme = .custom
                                                showImagePicker = true
                                            } else {
                                                selectedTheme = theme
                                                selectedImage = nil
                                            }
                                        } label: {
                                            ThemeCarouselItem(
                                                theme: theme,
                                                isSelected: selectedTheme == theme,
                                                customImage: selectedImage
                                            )
                                        }
                                        .buttonStyle(ThemeCardButtonStyle())
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            
            // Action Buttons
            VStack(spacing: 0) {
                Button(action: { saveEvent() }) {
                    Text(isEditing ? "Save changes" : "Save")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(-0.64)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isSaveEnabled ? Color.primaryBlue : Color.mutedBlue)
                        .cornerRadius(50)
                        // Fade between enabled/disabled instead of snapping
                        .animation(.easeOut(duration: 0.2), value: isSaveEnabled)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(!isSaveEnabled)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: Binding(
                get: { selectedImage },
                set: { newImage in
                    selectedImage = newImage
                    if newImage != nil { didPickNewImage = true }
                }
            ), sourceType: .photoLibrary, requireSquareAspect: true)
                .onDisappear {
                    // Cancelled without a photo: don't leave an empty custom card
                    selectedTheme = selectedImage != nil ? .custom : themeBeforeCustom
                }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(date: $startDate, mode: .date)
                .presentationDetents([.height(500)])
        }
        .sheet(isPresented: $showTimePicker) {
            DatePickerSheet(date: $startDate, mode: .hourAndMinute)
                .presentationDetents([.height(280)])
        }
    }
    
    // MARK: - Computed Properties
    
    private var availableThemes: [CardTheme] {
        CardTheme.displayThemes + [.custom]
    }
    
    static let maxTitleLength = 40
    
    private var trimmedTitle: String {
        eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isSaveEnabled: Bool {
        guard !trimmedTitle.isEmpty else { return false }
        // When editing, only enable Save once something has actually changed
        guard let editingEvent else { return true }
        return trimmedTitle != editingEvent.title
            || abs(startDate.timeIntervalSince(editingEvent.startedAt)) >= 1
            || selectedTheme != editingEvent.cardTheme
            || didPickNewImage
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
    
    private func saveEvent() {
        guard isSaveEnabled else { return }
        
        if let editingEvent {
            saveChanges(to: editingEvent)
            return
        }

        // Convert UIImage to Data if image is selected (only for custom theme)
        let imageData = selectedTheme == .custom ? selectedImage?.jpegData(compressionQuality: 0.8) : nil
        
        let newEvent = SinceEvent(
            title: trimmedTitle,
            // A start in the future would give negative counts
            startedAt: min(startDate, Date()),
            imageData: imageData,
            cardTheme: selectedTheme
        )
        
        viewModel.addEvent(newEvent)
        viewModel.completeOnboarding()
        
        // Success haptic
        HapticManager.shared.success()
        
        isPresented = false
    }
    
    /// Apply edits while keeping the event's id, history, reminders and widget unit
    private func saveChanges(to original: SinceEvent) {
        var updated = original
        updated.title = trimmedTitle
        updated.startedAt = min(startDate, Date())
        updated.cardTheme = selectedTheme
        
        if selectedTheme != .custom {
            updated.imageData = nil
        } else if didPickNewImage {
            updated.imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        }
        
        viewModel.updateEvent(updated)
        HapticManager.shared.success()
        isPresented = false
    }
}

// MARK: - Pressable Button Style

/// Subtle press-down feedback for primary buttons
struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
            .opacity(configuration.isPressed && reduceMotion ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var requireSquareAspect: Bool = false
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = requireSquareAspect
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                // Crop to square if needed
                if parent.requireSquareAspect {
                    parent.image = cropToSquare(image: originalImage)
                } else {
                    parent.image = originalImage
                }
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        private func cropToSquare(image: UIImage) -> UIImage {
            let sideLength = min(image.size.width, image.size.height)
            let xOffset = (image.size.width - sideLength) / 2
            let yOffset = (image.size.height - sideLength) / 2
            
            let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)
            
            guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
                return image
            }
            
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var date: Date
    var mode: DatePickerComponents
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(mode.contains(.date) ? "Select Date" : "Select Time")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primaryBlue)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "0881f4"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Date Picker
            if mode.contains(.date) {
                DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            } else {
                DatePicker("", selection: $date, in: ...Date(), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
            }
            
            Spacer()
        }
        .background(Color.white)
        .preferredColorScheme(.light)
    }
}

// MARK: - Theme Card Button Style

struct ThemeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Theme Carousel Item

struct ThemeCarouselItem: View {
    let theme: CardTheme
    let isSelected: Bool
    let customImage: UIImage?
    
    var body: some View {
        ZStack {
            // Background color
            theme.backgroundColor
            
            // SVG or custom image - clipped inside
            if theme == .custom {
                if let image = customImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Placeholder for custom
                    Color(hex: "f0f0f0")
                    VStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "b5b5b8"))
                        Text("Custom")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "b5b5b8"))
                    }
                }
            } else if let assetName = theme.svgAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 64, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.primaryBlue : Color.clear, lineWidth: 3)
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Theme Mini Preview

struct ThemeMiniPreview: View {
    let theme: CardTheme
    let customImage: UIImage?
    
    var body: some View {
        ZStack {
            if theme == .custom, let image = customImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipped()
            } else if let svgName = theme.svgAssetName {
                Image(svgName, bundle: nil)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipped()
            } else {
                theme.backgroundColor
                    .frame(width: 32, height: 32)
            }
        }
    }
}

#Preview {
    AddEventBottomSheet_Preview()
}

struct AddEventBottomSheet_Preview: View {
    var body: some View {
        AddEventBottomSheet(viewModel: EventViewModel(), isPresented: .constant(true))
    }
}

//
//  AddEventBottomSheet.swift
//  Sinced2
//
//  Bottom sheet for adding new events - matches new Figma design with image selection
//

import SwiftUI

struct AddEventBottomSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: EventViewModel
    @Binding var isPresented: Bool
    
    @State private var eventTitle: String = ""
    @State private var startDate: Date = Date()
    @State private var selectedImage: UIImage? = nil
    @State private var selectedTheme: CardTheme = .mosaic
    @State private var showImagePicker: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showTimePicker: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add an event")
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
                    Text("Save")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(-0.64)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isSaveEnabled ? Color.primaryBlue : Color.mutedBlue)
                        .cornerRadius(50)
                }
                .disabled(!isSaveEnabled)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary, requireSquareAspect: true)
                .onDisappear {
                    if selectedImage != nil {
                        selectedTheme = .custom
                    }
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
    
    private var isSaveEnabled: Bool {
        !eventTitle.isEmpty
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
        guard !eventTitle.isEmpty else { return }

        // Convert UIImage to Data if image is selected (only for custom theme)
        let imageData = selectedTheme == .custom ? selectedImage?.jpegData(compressionQuality: 0.8) : nil
        
        let newEvent = SinceEvent(
            title: eventTitle,
            startedAt: startDate,
            imageData: imageData,
            cardTheme: selectedTheme
        )
        
        viewModel.addEvent(newEvent)
        viewModel.completeOnboarding()
        
        // Success haptic
        HapticManager.shared.success()
        
        isPresented = false
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
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
            } else {
                DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
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

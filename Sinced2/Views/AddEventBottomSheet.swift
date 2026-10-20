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
    /// nil until the user picks a card for a new event
    @State private var selectedTheme: CardTheme?
    /// Theme to fall back to if the photo picker is cancelled
    @State private var themeBeforeCustom: CardTheme?
    /// Set when the user picks a new photo, so an unchanged photo isn't re-encoded
    @State private var didPickNewImage = false
    @State private var showImagePicker: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    /// A fresh random pick of name ideas each time the sheet opens
    @State private var nameSuggestions = Array(Self.nameIdeas.shuffled().prefix(8))
    
    init(viewModel: EventViewModel, isPresented: Binding<Bool>, editingEvent: SinceEvent? = nil) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.editingEvent = editingEvent
        
        // New events start with no card selected
        let theme = editingEvent?.cardTheme
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
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primaryGreen)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Event Title Input
                    HStack(spacing: 8) {
                        TextField(
                            "Event name",
                            text: $eventTitle,
                            prompt: Text("eg: last cigarette, no coffee")
                                .foregroundColor(Self.labelColor)
                        )
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "1a1a1a"))
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
                    // Near-opaque so the field stays legible over the glass sheet
                    .background(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.bottom, isEditing ? 24 : 12)

                    if !isEditing {
                        nameSuggestionChips
                            .padding(.bottom, 20)
                    }
                    
                    // Details Section
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Text("Started on")
                                .font(.system(size: 16))
                                .foregroundColor(Self.labelColor)
                            
                            Spacer()
                            
                            StartDatePill(
                                date: $startDate,
                                components: .date,
                                text: startDate.formatted(.dateTime.day().month(.abbreviated).year())
                            )
                            StartDatePill(
                                date: $startDate,
                                components: .hourAndMinute,
                                text: startDate.formatted(date: .omitted, time: .shortened)
                            )
                        }
                        .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Card theme")
                                .font(.system(size: 16))
                                .foregroundColor(Self.labelColor)
                            
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
                            // Run edge to edge so cards fade out instead of being cut
                            .contentMargins(.horizontal, 14, for: .scrollContent)
                            .padding(.horizontal, -16)
                            .edgeFade()
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isSaveEnabled ? Color.primaryGreen : Color.mutedGreen)
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
    }
    
    // MARK: - Name Suggestions

    /// Tappable name ideas so people don't have to think up a title
    private var nameSuggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(nameSuggestions, id: \.self) { idea in
                    Button {
                        HapticManager.shared.light()
                        eventTitle = idea
                    } label: {
                        NameSuggestionChip(title: idea, isSelected: trimmedTitle == idea)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.vertical, 2)
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .edgeFade()
    }

    /// The most common things people count days since
    static let nameIdeas = [
        "Quit smoking", "Last cigarette", "No alcohol", "Quit vaping",
        "No caffeine", "No sugar", "No junk food", "No social media",
        "Started the gym", "Started running", "Meditating daily", "Started therapy",
        "New job", "Moved cities", "Got sober", "Last breakup",
        "First date", "Our anniversary", "Got a pet", "Last haircut",
        "Last vacation", "Called mom", "Last doctor visit", "Changed bedsheets",
        "Watered the plants", "Car service", "Started journaling", "Reading daily"
    ]

    /// Secondary text that stays readable on the glass sheet
    static let labelColor = Color(hex: "8a888a")

    // MARK: - Computed Properties
    
    private var availableThemes: [CardTheme] {
        // Photo first so it's easy to find; the themes follow
        [.custom] + CardTheme.displayThemes
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
            // Fall back to the default card if none was picked
            cardTheme: selectedTheme ?? .mosaic
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
        updated.cardTheme = selectedTheme ?? updated.cardTheme
        
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
                    // Add-a-photo card, outlined like the name chips
                    Color.white
                    VStack(spacing: 5) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 20, weight: .medium))
                        Text("Photo")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.primaryGreen)
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Color.primaryGreen.opacity(0.6),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                        )
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
            // Inside the card's edge so the scroll view never clips it
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.primaryGreen : Color.clear, lineWidth: 3)
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

/// Outlined, dashed pill for a name idea
private struct NameSuggestionChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(isSelected ? .primaryGreen : Color(hex: "4a484a"))
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primaryGreen.opacity(0.08) : Color.white.opacity(0.5))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.primaryGreen : Color.black.opacity(0.28),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            )
            .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

private extension View {
    /// Softly fades a horizontal carousel's edges, but only on a side with more
    /// content to scroll to, so the first card isn't faded at rest
    func edgeFade(width: CGFloat = 24) -> some View {
        modifier(CarouselEdgeFade(width: width))
    }
}

private struct CarouselEdgeFade: ViewModifier {
    let width: CGFloat
    @State private var fadesLeading = false
    @State private var fadesTrailing = false

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: [Bool].self) { geometry in
                let visible = geometry.visibleRect
                return [visible.minX > 1, visible.maxX < geometry.contentSize.width - 1]
            } action: { _, edges in
                withAnimation(.easeOut(duration: 0.2)) {
                    fadesLeading = edges[0]
                    fadesTrailing = edges[1]
                }
            }
            .mask(
                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [.black.opacity(fadesLeading ? 0 : 1), .black],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: width)
                    Color.black
                    LinearGradient(
                        colors: [.black, .black.opacity(fadesTrailing ? 0 : 1)],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: width)
                }
            )
    }
}

/// Date or time pill in the sheet's own style. The real compact DatePicker is
/// underneath and fully visible to touch; our pill is drawn over it, opaque and
/// with hit testing off, so taps fall straight through to the native control and
/// open the system's own glass picker.
struct StartDatePill: View {
    @Binding var date: Date
    let components: DatePickerComponents
    let text: String
    var range: ClosedRange<Date>? = nil

    var body: some View {
        DatePicker("", selection: $date, in: range ?? (Date.distantPast...Date()), displayedComponents: components)
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(.primaryGreen)
            .accessibilityLabel(components == .date ? "Start date" : "Start time")
            .overlay {
                // Fully opaque, so none of the native text shows through
                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "1a1a1a"))
                    .lineLimit(1)
                    .fixedSize()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Capsule().fill(Color.white))
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

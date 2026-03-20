//
//  ThemePickerView.swift
//  Sinced2
//
//  Theme picker for selecting event card backgrounds
//

import SwiftUI

struct ThemePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTheme: CardTheme
    @Binding var customImage: UIImage?
    var onSelectImage: () -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Choose a theme")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primaryBlue)
                    .tracking(-0.96)
                
                Spacer()
                
                Button(action: { dismiss() }) {
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
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Theme Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(CardTheme.displayThemes) { theme in
                            ThemePreviewCard(
                                theme: theme,
                                isSelected: selectedTheme == theme && customImage == nil
                            )
                            .onTapGesture {
                                HapticManager.shared.light()
                                selectedTheme = theme
                                customImage = nil
                                dismiss()
                            }
                        }
                        
                        // Custom Image Option
                        CustomImageCard(
                            image: customImage,
                            isSelected: selectedTheme == .custom && customImage != nil
                        )
                        .onTapGesture {
                            HapticManager.shared.light()
                            onSelectImage()
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color.white)
        .preferredColorScheme(.light)
    }
}

// MARK: - Theme Preview Card
struct ThemePreviewCard: View {
    let theme: CardTheme
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            // Theme background
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.backgroundColor)
            
            // SVG overlay (scaled down)
            if let assetName = theme.svgAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            }
            
            // Theme name
            VStack {
                Spacer()
                Text(theme.rawValue)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
            }
            
            // Selection indicator
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primaryBlue, lineWidth: 3)
                
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.primaryBlue))
                            .padding(6)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(0.54, contentMode: .fit) // Matches card aspect ratio (394/732)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Custom Image Card
struct CustomImageCard: View {
    let image: UIImage?
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            if let image = image {
                // Show selected image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "f7f7f7"))
                
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "b5b5b8"))
                    
                    Text("Custom")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "b5b5b8"))
                }
            }
            
            // Selection indicator
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primaryBlue, lineWidth: 3)
                
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.primaryBlue))
                            .padding(6)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(0.54, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ThemePickerView(
        selectedTheme: .constant(.mosaic),
        customImage: .constant(nil),
        onSelectImage: {}
    )
}


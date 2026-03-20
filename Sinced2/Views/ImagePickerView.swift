//
//  ImagePickerView.swift
//  Sinced2
//
//  Image picker for selecting/replacing event images
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var showCamera = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview section
                VStack(spacing: 16) {
                    Text("Image Preview")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Image preview with 1:1 aspect ratio
                    ZStack {
                        if let imageData = imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width - 48, height: UIScreen.main.bounds.width - 48)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: UIScreen.main.bounds.width - 48, height: UIScreen.main.bounds.width - 48)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray.opacity(0.5))
                                        Text("No image selected")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Action buttons
                VStack(spacing: 12) {
                    // Photo library picker
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Library")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "00621a"))
                        )
                    }
                    .disabled(isLoading)
                    
                    // Camera button
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Take Photo")
                        }
                        .font(.headline)
                        .foregroundColor(Color(hex: "00621a"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "00621a"), lineWidth: 2)
                        )
                    }
                    .disabled(isLoading)
                    
                    // Remove image button (only show if there's an image)
                    if imageData != nil {
                        Button(action: {
                            imageData = nil
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Image")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding(.top, 24)
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView(imageData: $imageData)
            }
        }
    }
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoading = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // Process image to ensure it's in a reasonable size (1:1 aspect ratio)
                if let uiImage = UIImage(data: data) {
                    let processedData = processImage(uiImage)
                    await MainActor.run {
                        self.imageData = processedData
                        self.isLoading = false
                    }
                }
            }
        } catch {
            print("Error loading image: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    /// Process image to crop to 1:1 aspect ratio and compress
    /// IMPORTANT: Widget has strict memory limits - keep images small!
    private func processImage(_ image: UIImage) -> Data? {
        let size = min(image.size.width, image.size.height)
        let origin = CGPoint(
            x: (image.size.width - size) / 2,
            y: (image.size.height - size) / 2
        )
        
        guard let cgImage = image.cgImage?.cropping(to: CGRect(origin: origin, size: CGSize(width: size, height: size))) else {
            return image.jpegData(compressionQuality: 0.6)
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        
        // Resize to max 512x512 for widget compatibility
        // Widget memory limit: image area must be < 526750 pixels
        // 512x512 = 262144 pixels (well within limit)
        let maxSize: CGFloat = 512
        let scale = maxSize / size
        let newSize = CGSize(width: size * scale, height: size * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        croppedImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Compress more aggressively (60% quality) to reduce memory usage
        return resizedImage?.jpegData(compressionQuality: 0.6)
    }
}

/// Camera picker wrapper using UIImagePickerController
struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @Binding var imageData: Data?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = processImage(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        private func processImage(_ image: UIImage) -> Data? {
            let size = min(image.size.width, image.size.height)
            let origin = CGPoint(
                x: (image.size.width - size) / 2,
                y: (image.size.height - size) / 2
            )
            
            guard let cgImage = image.cgImage?.cropping(to: CGRect(origin: origin, size: CGSize(width: size, height: size))) else {
                return image.jpegData(compressionQuality: 0.6)
            }
            
            let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            
            // Resize to max 512x512 for widget compatibility
            let maxSize: CGFloat = 512
            let scale = maxSize / size
            let newSize = CGSize(width: size * scale, height: size * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            croppedImage.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage?.jpegData(compressionQuality: 0.6)
        }
    }
}

#Preview {
    ImagePickerView(imageData: .constant(nil))
}


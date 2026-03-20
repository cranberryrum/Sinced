//
//  CreateEventView.swift
//  Sinced2
//
//  Screen for creating a new event with title, date, and optional image
//

import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: EventViewModel
    
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What are you tracking?")
                            .font(.roundedHeadline)
                            .foregroundColor(.primary)
                        
                        TextField("e.g., Coffee, Cigarette, Sugar", text: $title)
                            .textFieldStyle(.plain)
                            .font(.roundedBody)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Date Picker Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When did it start?")
                            .font(.roundedHeadline)
                            .foregroundColor(.primary)
                        
                        DatePicker("", selection: $startDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Image Selection Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Widget Image (Optional)")
                            .font(.roundedHeadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Image(systemName: "photo")
                                        .font(.rounded(32))
                                        .foregroundColor(.gray)
                                        .frame(width: 60, height: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(UIColor.tertiarySystemBackground))
                                        )
                                }
                                
                                Text(selectedImage == nil ? "Select 1:1 image" : "Change image")
                                    .font(.roundedBody)
                                    .foregroundColor(.primaryBlue)
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Preview Section
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            Text("Preview")
                                .font(.roundedSubheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title.isEmpty ? "Untitled Event" : title)
                                        .font(.roundedTitle3)
                                        .foregroundColor(.primary)
                                    
                                    Text(timeAgoString)
                                        .font(.roundedSubheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary, requireSquareAspect: true)
            }
        }
    }
    
    private var timeAgoString: String {
        let elapsed = Date().timeIntervalSince(startDate)
        let minutes = Int(elapsed / 60)
        
        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes) min ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h \(minutes % 60)m ago"
        }
    }
    
    private func saveEvent() {
        // Convert UIImage to Data if image is selected
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        
        let newEvent = SinceEvent(
            title: title,
            startedAt: startDate,
            imageData: imageData
        )
        
        viewModel.addEvent(newEvent)
        viewModel.completeOnboarding()
        dismiss()
    }
}

#Preview {
    CreateEventView(viewModel: EventViewModel())
}



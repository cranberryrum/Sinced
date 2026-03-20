//
//  ResetSheetView.swift
//  Sinced2
//
//  Sheet for resetting an event with optional note
//

import SwiftUI

struct ResetSheetView: View {
    let event: SinceEvent
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var resetDate = Date()
    @State private var note = ""
    @State private var lastNowTap = Date.distantPast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Reset time")
                    .font(.roundedHeadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Now") {
                    resetDate = Date()
                    lastNowTap = Date()
                }
                .font(.roundedSubheadline)
                .foregroundColor(.primaryBlue)
            }
            
            HStack(spacing: 14) {
                DatePicker("", selection: $resetDate, in: event.startedAt...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                DatePicker("", selection: $resetDate, in: event.startedAt...Date(), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Note (optional)")
                    .font(.roundedHeadline)
                    .foregroundColor(.primary)
                
                TextField("Add a quick note", text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(12)
                    .frame(minHeight: 54, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(UIColor.separator), lineWidth: 0.5)
                    )
            }
            
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primaryBlue)
                    .opacity(lastNowTap.timeIntervalSinceNow > -1.5 ? 1 : 0.4)
                    .animation(.easeInOut(duration: 0.2), value: lastNowTap)
                
                Text("Your current streak will be saved to history.")
                    .font(.roundedCaption)
                    .foregroundColor(.secondary)
            }
            
            Button(role: .destructive, action: {
                resetEvent()
            }) {
                Label("Reset & Save", systemImage: "arrow.counterclockwise")
                    .font(.roundedHeadline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 28)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(.white)
    }
    
    private func resetEvent() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = trimmedNote.isEmpty ? nil : trimmedNote
        
        viewModel.resetEvent(event, at: resetDate, note: finalNote)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Dismiss with animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dismiss()
        }
    }
}

#Preview {
    let sampleEvent = SinceEvent(
        title: "Coffee",
        startedAt: Date().addingTimeInterval(-3600 * 24 * 3)
    )
    
    ResetSheetView(event: sampleEvent, viewModel: EventViewModel())
}



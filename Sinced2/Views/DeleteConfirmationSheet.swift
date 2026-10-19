//
//  DeleteConfirmationSheet.swift
//  Sinced2
//
//  Bottom sheet confirmation for delete action
//

import SwiftUI

struct DeleteConfirmationSheet: View {
    let eventTitle: String
    let onConfirmDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Scroll only when the content doesn't fit (e.g. large Dynamic Type),
        // so the swipe gesture isn't competing with a scroll view normally
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
    }
    
    private var content: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.bottom, 4)
                
                Text("Delete Event")
                    .font(.roundedTitle3)
                    .fontWeight(.semibold)
                
                Text("This will permanently delete \"\(eventTitle)\".")
                    .font(.roundedSubheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            SwipeToDeleteButton {
                onConfirmDelete()
            }
            
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }
}

#Preview {
    DeleteConfirmationSheet(eventTitle: "Coffee") {
        print("Delete confirmed")
    }
}

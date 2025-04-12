//
//  StoryHistoryDetailView.swift
//  PeerPlot
//
//  Created by Ravi Shankar on 11/04/25.
//

import SwiftUI

struct StoryHistoryDetailView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: StoryViewModel
    @State private var storyEntries: [StoryEntry] = []
    let storyId: String
    let title: String
    
    // MARK: - Main Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Title with subtle decoration
                HStack {
                    Rectangle()
                        .fill(AppTheme.Colors.primary.opacity(0.5))
                        .frame(width: 3, height: 20)
                    
                    Text(title)
                        .font(AppTheme.Typography.title)
                        .foregroundColor(AppTheme.Colors.primary)
                }
                .padding(.vertical, 16)
                
                ForEach(Array(zip(storyEntries.indices, storyEntries)), id: \.0) { index, entry in
                    VStack(alignment: .leading, spacing: 2) {
                        if index > 0 {
                            // Delicate separator
                            HStack {
                                Rectangle()
                                    .fill(AppTheme.Colors.primary.opacity(0.15))
                                    .frame(width: 24, height: 1)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                        
                        // Story text
                        Text(entry.text)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Attribution
                        HStack {
                            Spacer()
                            Text("—\(entry.author)")
                                .font(AppTheme.Typography.caption)
                                .italic()
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding()
        }
        .withCustomBackButton {
            dismiss()
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            storyEntries = viewModel.loadHistoryStoryEntries(id: storyId)
        }
    }
}

#Preview {
    NavigationView {
        StoryHistoryDetailView(viewModel: StoryViewModel(), storyId: "sample", title: "Sample Story")
    }
}

//
//  StoryHistoryView.swift
//  PeerPlot
//
//  Created by Ravi Shankar on 11/04/25.
//

import SwiftUI

struct StoryHistoryView: View {
    // MARK: - Properties
    let viewModel: StoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Main Body
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.storyHistoryItems) { item in
                    NavigationLink(destination: StoryHistoryDetailView(viewModel: viewModel, storyId: item.id, title: item.title)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(AppTheme.Typography.headline)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text(item.formattedDate)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text("\(item.entryCount)")
                                    .font(AppTheme.Typography.title)
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .stroke(AppTheme.Colors.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        .padding()
                        .background(AppTheme.Colors.subtleBackground)
                        .cornerRadius(AppTheme.Layout.cornerRadius)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .withCustomBackButton {
            dismiss()
        }
        .background(Color.white)
        .navigationTitle("Story History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadStoryHistory()
        }
    }
}

#Preview {
    NavigationView {
        StoryHistoryView(viewModel: StoryViewModel())
    }
}

//
//  StoryView.swift
//  PeerPlot
//
//  Created for PeerPlot
//

import SwiftUI

// MARK: - Main View
struct StoryView: View {
    
    // MARK: - Properties
    @State private var viewModel = StoryViewModel()
    @State private var showRandomTwist = false
    @State private var showNewStoryConfirmation = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with title
                headerView
                
                // Main story content
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if viewModel.storyEntries.isEmpty {
                                emptyStoryView
                            } else {
                                continuousStoryView
                            }
                            
                            Spacer().frame(height: 100)
                                .id("scrollBottom")
                        }
                        .padding()
                    }
                    .background(AppTheme.Colors.subtleBackground)
                    .onChange(of: viewModel.storyEntries.count) { oldValue, newValue in
                        withAnimation {
                            scrollView.scrollTo("scrollBottom", anchor: .bottom)
                        }
                    }
                }
                
                // Story composer with random twist button
                composerView
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showAuthorNamePrompt) {
                authorNameView
            }
            .sheet(isPresented: $viewModel.showArchivePrompt) {
                archivePromptView
            }
            .alert("Add a Plot Twist!", isPresented: $showRandomTwist) {
                Button("Use This Twist") {
                    viewModel.newEntryText = viewModel.twist()
                    showRandomTwist = false
                }
                Button("Cancel", role: .cancel) {
                    showRandomTwist = false
                }
            } message: {
                Text("Add an unexpected turn to the story!")
            }
            .alert("Start New Story?", isPresented: $showNewStoryConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Archive & Start New", role: .destructive) {
                    if !viewModel.storyEntries.isEmpty {
                        viewModel.showArchivePrompt = true
                    } else {
                        _ = DatabaseManager.shared.clearStoryAndStartNew()
                    }
                }
            } message: {
                Text("Would you like to archive this story before starting a new one?")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Peer Plot")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        if !viewModel.storyEntries.isEmpty {
                            showNewStoryConfirmation = true
                        } else {
                            DatabaseManager.shared.loadStoryEntries()
                        }
                    }) {
                        Image(systemName: "doc.badge.plus")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    NavigationLink(
                        destination: StoryHistoryView(viewModel: viewModel)
                    ) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    Button(action: {
                        viewModel.showAuthorNamePrompt = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "person")
                            Text(viewModel.authorName.isEmpty ? "Set Name" : viewModel.authorName)
                                .font(AppTheme.Typography.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.Colors.accentLight)
                        .cornerRadius(AppTheme.Layout.smallCornerRadius)
                        .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Horizontal divider
            Rectangle()
                .fill(AppTheme.Colors.divider)
                .frame(height: 1)
        }
        .background(Color.white)
    }
    
    // MARK: - Archive Prompt View
    private var archivePromptView: some View {
        VStack(spacing: 20) {
            Text("Archive this story?")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.top)
            
            Text("Give your story a title before starting a new one")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("Story title", text: $viewModel.archiveTitle)
                .styledTextField()
                .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    viewModel.showArchivePrompt = false
                    viewModel.archiveTitle = ""
                }
                .buttonStyle(.secondary)
                
                Button("Archive & Start New") {
                    viewModel.archiveCurrentStory(withTitle: viewModel.archiveTitle)
                    viewModel.showArchivePrompt = false
                    viewModel.archiveTitle = ""
                }
                .buttonStyle(.primary)
                .disabled(viewModel.archiveTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Spacer()
        }
        .padding()
        .frame(height: 250)
        .presentationDetents([.height(250)])
        .background(Color.white)
    }
    
    // MARK: - Continuous Story View
    private var continuousStoryView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(zip(viewModel.storyEntries.indices, viewModel.storyEntries)), id: \.0) { index, entry in
                VStack(alignment: .leading, spacing: 2) {
                    // Small divider at beginning of each entry except first
                    if index > 0 {
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
                        Text("—\(entry.author)\(index == viewModel.storyEntries.count - 1 ? " (just now)" : "")")
                            .font(AppTheme.Typography.caption)
                            .italic()
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                }
                .padding(.vertical, 6)
            }
            
            // Prompt for next contribution
            if !viewModel.storyEntries.isEmpty {
                HStack {
                    Rectangle()
                        .fill(AppTheme.Colors.primary.opacity(0.15))
                        .frame(width: 24, height: 1)
                    
                    Text("What happens next?")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: - Empty Story View
    private var emptyStoryView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.primary.opacity(0.7))
                .padding(.bottom, 8)
            
            Text("Begin a new tale")
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("Every great story starts with a single sentence.")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: {
                showRandomTwist = true
            }) {
                Text("Get a story starter")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.Colors.primary, lineWidth: 1)
                    )
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
    
    // MARK: - Composer View
    private var composerView: some View {
        VStack(spacing: 12) {
            // Plot twist button
            if !viewModel.storyEntries.isEmpty {
                Button(action: {
                    showRandomTwist = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("Add Plot Twist")
                            .font(AppTheme.Typography.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.Colors.accentLight)
                    .foregroundColor(AppTheme.Colors.primary)
                    .cornerRadius(16)
                }
                .padding(.top, 4)
            }
            
            // Entry composer
            HStack(alignment: .bottom, spacing: 14) {
                TextField("Continue the story...", text: $viewModel.newEntryText, axis: .vertical)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .padding(12)
                    .background(AppTheme.Colors.subtleBackground)
                    .cornerRadius(AppTheme.Layout.cornerRadius)
                    .disabled(viewModel.isSubmitting)
                    .frame(minHeight: 50)
                
                Button(action: {
                    viewModel.submitEntry()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.newEntryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                         AppTheme.Colors.textSecondary.opacity(0.3) : AppTheme.Colors.primary)
                }
                .disabled(viewModel.newEntryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmitting)
            }
            
            // Device indicator
            HStack {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                Text(deviceName())
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(AppTheme.Colors.primary.opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Author Name View
    private var authorNameView: some View {
        VStack(spacing: 20) {
            Text("Who's adding to the story?")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.top)
            
            TextField("Your name or nickname", text: $viewModel.authorName)
                .styledTextField()
                .padding(.horizontal)
            
            Text("This will appear with your contributions")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Button("Join the Story") {
                viewModel.saveAuthorName()
            }
            .buttonStyle(.primary)
            .disabled(viewModel.authorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Spacer()
        }
        .padding()
        .frame(height: 250)
        .presentationDetents([.height(250)])
        .background(Color.white)
    }
    
    // Helper to get device name for "written from..."
    private func deviceName() -> String {
#if os(iOS)
        return UIDevice.current.name
#else
        return "Mac"
#endif
    }
}

#Preview {
    StoryView()
}

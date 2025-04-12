//
//  StoryViewModel.swift
//  PeerPlot
//
//  Created for PeerPlot
//

import SwiftUI
import Combine

class StoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var storyEntries: [StoryEntry] = []
    @Published var authorName: String = ""
    @Published var newEntryText: String = ""
    @Published var isSubmitting: Bool = false
    @Published var showAuthorNamePrompt: Bool = false
    @Published var storyHistoryItems: [StoryHistoryItem] = []
    @Published var showArchivePrompt = false
    @Published var archiveTitle = ""
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let databaseManager = DatabaseManager.shared
    
    // MARK: - Lifecycle
    init() {
        // Load saved author name
        authorName = UserDefaults.standard.string(forKey: "storyAuthorName") ?? ""
        
        // Subscribe to story entries
        databaseManager.storyEntriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.storyEntries = entries
                LogManager.info("Received \(entries.count) story entries from publisher",category: .ui)
            }
            .store(in: &cancellables)
        
        // Force load story entries immediately 
        databaseManager.loadStoryEntries()
        
        // Check if we need to prompt for author name
        showAuthorNamePrompt = authorName.isEmpty
    }
    
    // MARK: - Story Entry Management
    /// Submits a new entry to the collaborative story
    func submitEntry() {
        guard !newEntryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !authorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAuthorNamePrompt = true
            return
        }
        
        isSubmitting = true
        
        // Save author name
        UserDefaults.standard.set(authorName, forKey: "storyAuthorName")
        
        // Add entry to database
        let success = databaseManager.addStoryEntry(text: newEntryText, author: authorName)
        
        if success {
            // Clear text field
            newEntryText = ""
        }
        
        isSubmitting = false
    }
    
    func saveAuthorName() {
        UserDefaults.standard.set(authorName, forKey: "storyAuthorName")
        showAuthorNamePrompt = false
    }
    
    // MARK: - History Management
    func loadStoryHistory() {
        storyHistoryItems = databaseManager.getStoryHistory()
    }

    func archiveCurrentStory(withTitle title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let success = databaseManager.archiveCurrentStory(withTitle: title)
        if success {
            _ = databaseManager.clearStoryAndStartNew()
            loadStoryHistory()
        }
    }
    
    func loadHistoryStoryEntries(id: String) -> [StoryEntry] {
        return databaseManager.loadHistoryStory(id: id)
    }
    
    /// Twists prompts, later you can integrate this with AI
    func twist() -> String {
        let twists = [
            "Suddenly, aliens invaded...",
            "Without warning, everyone turned into llamas...",
            "The ground began to shake and...",
            "A mysterious portal opened and...",
            "Time started flowing backwards and...",
            "A character revealed a hidden superpower...",
            "The entire setting transformed into a jungle...",
            "A long-lost twin suddenly appeared...",
            "All technology mysteriously stopped working...",
            "A talking animal offered cryptic advice...",
            "They discovered it was all a dream, or was it...",
            "A secret society revealed their presence...",
            "The main villain turned out to be an ally...",
            "A forgotten prophecy started coming true...",
            "Gravity briefly reversed itself, causing chaos..."
        ]
        
        return twists.randomElement() ?? "Suddenly..."
    }
}

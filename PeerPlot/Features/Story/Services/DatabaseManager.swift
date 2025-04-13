//
//  DatabaseManager.swift
//  PeerPlot
//
//  Created for PeerPlot
//

import Foundation
import CouchbaseLiteSwift
import SwiftUI

@Observable
class DatabaseManager {
    // Singleton instance
    static let shared = DatabaseManager()
    
    // Database instance
    private var database: Database
    
    // Collection
    private var collection: Collection
    
    // App instance for P2P sync
    private var syncApp: AppService?
    
    var storyEntries: [StoryEntry] = []
    
    private init() {
        LogManager.info("Initializing DatabaseManager...", category: .database)
        
        // Initialize properties without using self
        do {
            let tempDatabase = try Database(name: "peerplot")
            let tempCollection = try tempDatabase.defaultCollection()
            
            // Assign to properties after initialization
            self.database = tempDatabase
            self.collection = tempCollection
            
            // Now it's safe to use self
            setupListeners()
            setupP2PSync()
        } catch {
            fatalError("Failed to initialize database: \(error.localizedDescription)")
        }
    }
    
    private func setupListeners() {
        LogManager.info("Setting up document listeners...")
        // Listen for changes to the story document
        collection.addDocumentChangeListener(id: "story") { [weak self] _ in
            LogManager.info("Story document changed")
            self?.loadStoryEntries()
        }
    }
    
    public func loadStoryEntries() {
        LogManager.info("Loading story entries...",category: .database)
        
        if let storyDoc = try? collection.document(id: "story") {
            var entries: [StoryEntry] = []
            let count = Int(storyDoc.int(forKey: "count"))
            
            for i in 0..<count {
                guard let id = storyDoc.string(forKey: "entry_\(i)_id"),
                      let text = storyDoc.string(forKey: "entry_\(i)_text"),
                      let author = storyDoc.string(forKey: "entry_\(i)_author"),
                      let timestamp = storyDoc.date(forKey: "entry_\(i)_timestamp") else {
                    continue
                }
                
                let entry = StoryEntry(
                    id: id,
                    text: text,
                    author: author,
                    timestamp: timestamp
                )
                
                entries.append(entry)
            }
            
            // Sort entries by timestamp
            entries.sort { $0.timestamp < $1.timestamp }
            
            LogManager.info("Loaded \(entries.count) story entries",category: .database)
            storyEntries = entries
        } else {
            // Create empty story document if it doesn't exist
            let storyDoc = MutableDocument(id: "story")
            storyDoc.setInt(0, forKey: "count")
            storyDoc.setDate(Date(), forKey: "updatedAt")
            
            try? collection.save(document: storyDoc)
            LogManager.info("Created empty story document")
            storyEntries = []
        }
    }
    
    func setupP2PSync() {
        Credentials.async { [weak self] identity, ca in
            guard let self = self else { return }
            
            LogManager.info("Setting up P2P sync...",category: .network)
            
            // Create app with database and credentials
            self.syncApp = AppService(
                database: self.database,
                conflictResolver: DefaultConflictResolver(),
                identity: identity,
                ca: ca
            )
            
            // Start P2P sync
            self.syncApp?.start()
            LogManager.info("P2P sync started",category: .network)
        }
    }
    
    func addStoryEntry(text: String, author: String) -> Bool {
        // Validate input
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        do {
            let timestamp = Date()
            let entryId = UUID().uuidString
            
            // Get or create document
            let storyDoc: MutableDocument
            let count: Int
            
            if let existingDoc = try collection.document(id: "story") {
                storyDoc = existingDoc.toMutable()
                count = Int(storyDoc.int(forKey: "count"))
            } else {
                storyDoc = MutableDocument(id: "story")
                count = 0
            }
            
            // Add entry data
            addEntryToDocument(
                storyDoc,
                index: count,
                id: entryId,
                text: text,
                author: author,
                timestamp: timestamp
            )
            
            // Update metadata
            storyDoc.setInt(count + 1, forKey: "count")
            storyDoc.setDate(timestamp, forKey: "updatedAt")
            
            try collection.save(document: storyDoc)
            return true
        } catch {
            LogManager.error("Error adding story entry: \(error.localizedDescription)",category: .database)
            return false
        }
    }
    
    /// Helper to add entry data to a document at the specified index
    private func addEntryToDocument(_ document: MutableDocument,
                                    index: Int, id: String, text: String, author: String, timestamp: Date) {
        document.setString(id, forKey: "entry_\(index)_id")
        document.setString(text, forKey: "entry_\(index)_text")
        document.setString(author, forKey: "entry_\(index)_author")
        document.setDate(timestamp, forKey: "entry_\(index)_timestamp")
    }
    
    func clearStoryAndStartNew() -> Bool {
        do {
            // Create empty story document, overwriting any existing one
            let storyDoc = MutableDocument(id: "story")
            storyDoc.setInt(0, forKey: "count")
            storyDoc.setDate(Date(), forKey: "updatedAt")
            
            try collection.save(document: storyDoc)
            LogManager.info("Created new empty story",category: .database)
            
            // Notify subscribers that the story is now empty
            return true
        } catch {
            LogManager.error("Error creating new story: \(error.localizedDescription)",category: .database)
            return false
        }
    }
    
    // Add to DatabaseManager.swift
    
    // Store a completed story in history
    func archiveCurrentStory(withTitle title: String) -> Bool {
        do {
            // Get current story
            guard let storyDoc = try collection.document(id: "story"),
                  Int(storyDoc.int(forKey: "count")) > 0 else {
                return false // Nothing to archive
            }
            
            // Create history document with timestamp as ID
            let historyId = "history_\(Date().timeIntervalSince1970)"
            let historyDoc = MutableDocument(id: historyId)
            
            // Add metadata
            historyDoc.setString(title, forKey: "title")
            historyDoc.setDate(Date(), forKey: "archivedAt")
            
            // Copy all entry data
            let count = Int(storyDoc.int(forKey: "count"))
            historyDoc.setInt(Int(Int64(count)), forKey: "count")
            
            for i in 0..<count {
                if let id = storyDoc.string(forKey: "entry_\(i)_id"),
                   let text = storyDoc.string(forKey: "entry_\(i)_text"),
                   let author = storyDoc.string(forKey: "entry_\(i)_author"),
                   let timestamp = storyDoc.date(forKey: "entry_\(i)_timestamp") {
                    
                    historyDoc.setString(id, forKey: "entry_\(i)_id")
                    historyDoc.setString(text, forKey: "entry_\(i)_text")
                    historyDoc.setString(author, forKey: "entry_\(i)_author")
                    historyDoc.setDate(timestamp, forKey: "entry_\(i)_timestamp")
                }
            }
            
            try collection.save(document: historyDoc)
            LogManager.info("Archived story to history: \(historyId)",category: .database)
            return true
        } catch {
            LogManager.error("Error archiving story: \(error.localizedDescription)",category: .database)
            return false
        }
    }
    
    // Get list of story history items
    func getStoryHistory() -> [StoryHistoryItem] {
        var historyItems: [StoryHistoryItem] = []
        
        do {
            // Query for documents with ID starting with "history_"
            let query = QueryBuilder
                .select(SelectResult.expression(Meta.id),
                        SelectResult.property("title"),
                        SelectResult.property("archivedAt"),
                        SelectResult.property("count"))
                .from(DataSource.collection(collection))
                .where(Meta.id.like(Expression.string("history_%")))
                .orderBy(Ordering.property("archivedAt").descending())
            
            let results = try query.execute()
            
            for result in results {
                guard let id = result.string(forKey: "id"),
                      let title = result.string(forKey: "title"),
                      let archivedAt = result.date(forKey: "archivedAt") else {
                    continue
                }
                
                // Don't use optional binding for non-optional values
                let count = result.int(forKey: "count")
                
                historyItems.append(StoryHistoryItem(
                    id: id,
                    title: title,
                    archivedAt: archivedAt,
                    entryCount: Int(count)
                ))
            }
        } catch {
            LogManager.error("Error fetching story history: \(error.localizedDescription)",category: .database)
        }
        
        return historyItems
    }
    
    // Load a specific history story
    func loadHistoryStory(id: String) -> [StoryEntry] {
        var entries: [StoryEntry] = []
        
        do {
            if let historyDoc = try collection.document(id: id) {
                let count = Int(historyDoc.int(forKey: "count"))
                
                for i in 0..<count {
                    guard let id = historyDoc.string(forKey: "entry_\(i)_id"),
                          let text = historyDoc.string(forKey: "entry_\(i)_text"),
                          let author = historyDoc.string(forKey: "entry_\(i)_author"),
                          let timestamp = historyDoc.date(forKey: "entry_\(i)_timestamp") else {
                        continue
                    }
                    
                    let entry = StoryEntry(
                        id: id,
                        text: text,
                        author: author,
                        timestamp: timestamp
                    )
                    
                    entries.append(entry)
                }
                
                // Sort entries by timestamp
                entries.sort { $0.timestamp < $1.timestamp }
            }
        } catch {
            LogManager.error("Error loading history story: \(error.localizedDescription)",category: .database)
        }
        
        return entries
    }
}

// MARK: - Conflict Resolver

class DefaultConflictResolver: ConflictResolverProtocol {
    func resolve(conflict: Conflict) -> Document? {
            guard let localDoc = conflict.localDocument,
                  let remoteDoc = conflict.remoteDocument else {
                return conflict.remoteDocument ?? conflict.localDocument
            }
            
            // Create a new merged document
            let mergedDoc = MutableDocument(id: localDoc.id)
            
            // Get the counts from both documents
            let localCount = Int(localDoc.int(forKey: "count"))
            let remoteCount = Int(remoteDoc.int(forKey: "count"))
            
            // Track seen entry IDs to avoid duplicates
            var seenEntryIds = Set<String>()
            var mergedCount = 0
            
            // First add entries from local document
            for i in 0..<localCount {
                if let id = localDoc.string(forKey: "entry_\(i)_id"),
                   !seenEntryIds.contains(id),
                   let text = localDoc.string(forKey: "entry_\(i)_text"),
                   let author = localDoc.string(forKey: "entry_\(i)_author"),
                   let timestamp = localDoc.date(forKey: "entry_\(i)_timestamp") {
                    
                    addEntryToDocument(mergedDoc, index: mergedCount, id: id,
                                      text: text, author: author, timestamp: timestamp)
                    seenEntryIds.insert(id)
                    mergedCount += 1
                }
            }
            
            // Then add any new entries from remote document
            for i in 0..<remoteCount {
                if let id = remoteDoc.string(forKey: "entry_\(i)_id"),
                   !seenEntryIds.contains(id),
                   let text = remoteDoc.string(forKey: "entry_\(i)_text"),
                   let author = remoteDoc.string(forKey: "entry_\(i)_author"),
                   let timestamp = remoteDoc.date(forKey: "entry_\(i)_timestamp") {
                    
                    addEntryToDocument(mergedDoc, index: mergedCount, id: id,
                                      text: text, author: author, timestamp: timestamp)
                    seenEntryIds.insert(id)
                    mergedCount += 1
                }
            }
            
            // Update metadata
            mergedDoc.setInt(mergedCount, forKey: "count")
            mergedDoc.setDate(Date(), forKey: "updatedAt")
            
            return mergedDoc
        }
        
        private func addEntryToDocument(_ document: MutableDocument,
                                      index: Int, id: String, text: String,
                                      author: String, timestamp: Date) {
            document.setString(id, forKey: "entry_\(index)_id")
            document.setString(text, forKey: "entry_\(index)_text")
            document.setString(author, forKey: "entry_\(index)_author")
            document.setDate(timestamp, forKey: "entry_\(index)_timestamp")
        }

    // WARNING: Time-based conflict resolution (commented below) causes data loss
    // Example scenario where this fails:
    // 1. Device A goes offline with 3 entries
    // 2. Device B adds entries 4-5 (timestamp 12:05)
    // 3. Device A (offline) adds entry 4 (timestamp 12:10)
    // 4. Device A reconnects
    // 5. Because Device A's timestamp is newer (12:10 > 12:05)
    //    Device B's entries 4-5 are completely discarded
    //
    // Our current implementation merges entries from both documents by:
    // - Preserving entries from both devices
    // - Using unique IDs to avoid duplicates
    // - Maintaining proper count and timestamps
    
//    func resolve(conflict: Conflict) -> Document? {
//        // Default strategy: use the revision with the most recent update
//        let localDoc = conflict.localDocument
//        let remoteDoc = conflict.remoteDocument
//        
//        guard let localDate = localDoc?.date(forKey: "updatedAt"),
//              let remoteDate = remoteDoc?.date(forKey: "updatedAt") else {
//            // If no dates exist, prefer remote document
//            return remoteDoc
//        }
//        
//        return localDate > remoteDate ? localDoc : remoteDoc
//    }
}

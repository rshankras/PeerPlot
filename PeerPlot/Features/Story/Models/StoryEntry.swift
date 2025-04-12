//
//  StoryEntry.swift
//  PeerPlot
//
//  Created by Ravi Shankar on 11/04/25.
//

import Foundation

struct StoryEntry: Identifiable {
    let id: String
    let text: String
    let author: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString, text: String,
         author: String, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.author = author
        self.timestamp = timestamp
    }
}

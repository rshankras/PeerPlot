//
//  StoryItem.swift
//  PeerPlot
//
//  Created by Ravi Shankar on 11/04/25.
//

import Foundation

struct StoryHistoryItem: Identifiable {
    let id: String
    let title: String
    let archivedAt: Date
    let entryCount: Int
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: archivedAt)
    }
}

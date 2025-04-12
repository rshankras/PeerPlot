//
//  LogManager.swift
//  PeerPlot
//
//  Created by Ravi Shankar on 12/04/25.
//


import os
import Foundation

/// Centralized logging utility for PeerPlot app
enum LogManager {
    // MARK: - Categories
    enum Category: String {
        case network
        case database
        case security
        case ui
        case general
    }
    
    // MARK: - Log Levels
    enum Level {
        case debug
        case info
        case warning
        case error
        case critical
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .info
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    // MARK: - Logging Methods
    
    /// Log a message with the specified category and level
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The subsystem category
    ///   - level: The severity level
    static func log(_ message: String, category: Category = .general, level: Level = .info) {
        let logger = OSLog(subsystem: "peerplot", category: category.rawValue)
        
        let isDebuggerAttached = isatty(STDERR_FILENO) != 0
        
        if isDebuggerAttached {
            let prefix: String
            switch level {
            case .debug: prefix = "📝"
            case .info: prefix = "ℹ️"
            case .warning: prefix = "⚠️"
            case .error: prefix = "❌"
            case .critical: prefix = "🔥"
            }
            print("\(prefix) [\(category.rawValue)] \(message)")
        } else {
            os_log("%{public}@", log: logger, type: level.osLogType, message)
        }
    }
    
    // MARK: - Convenience Methods
    
    static func debug(_ message: String, category: Category = .general) {
        log(message, category: category, level: .debug)
    }
    
    static func info(_ message: String, category: Category = .general) {
        log(message, category: category, level: .info)
    }
    
    static func warning(_ message: String, category: Category = .general) {
        log(message, category: category, level: .warning)
    }
    
    static func error(_ message: String, category: Category = .general) {
        log(message, category: category, level: .error)
    }
    
    static func critical(_ message: String, category: Category = .general) {
        log(message, category: category, level: .critical)
    }
}

import Foundation
import os.log

/// Centralized logging system for the app
struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "WanderMint"
    
    // Different log categories
    static let auth = OSLog(subsystem: subsystem, category: "Authentication")
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let data = OSLog(subsystem: subsystem, category: "Data")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    
    /// Log info level messages (only in debug builds)
    static func info(_ message: String, category: OSLog = .default) {
        #if DEBUG
        os_log("%@", log: category, type: .info, message)
        #endif
    }
    
    /// Log error messages (always logged)
    static func error(_ message: String, category: OSLog = .default) {
        os_log("%@", log: category, type: .error, message)
    }
    
    /// Log debug messages (only in debug builds)
    static func debug(_ message: String, category: OSLog = .default) {
        #if DEBUG
        os_log("%@", log: category, type: .debug, message)
        #endif
    }
    
    /// Log fault messages (always logged, for critical errors)
    static func fault(_ message: String, category: OSLog = .default) {
        os_log("%@", log: category, type: .fault, message)
    }
}
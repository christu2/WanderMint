import Foundation

/// Application configuration constants
struct AppConfig {
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://us-central1-travel-consulting-app-1.cloudfunctions.net"
        
        struct Endpoints {
            static let submitTrip = "\(baseURL)/submitTrip"
            static let deleteUserAccount = "\(baseURL)/deleteUserAccount"
        }
    }
    
    // MARK: - App Information
    struct App {
        static let name = "WanderMint"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleId = Bundle.main.bundleIdentifier ?? "com.christus.WanderMint"
        static let appStoreId = "6748586609"
        static var appStoreURL: URL? {
            guard !appStoreId.isEmpty else { return nil }
            return URL(string: "https://apps.apple.com/app/id\(appStoreId)")
        }
    }
    
    // MARK: - User Limits
    struct Limits {
        static let maxTripsPerDay = 10
        static let maxDestinationsPerTrip = 5
        static let maxGroupSize = 20
    }
    
    // MARK: - Points Valuation (in cents)
    struct PointsValues {
        static let defaultCreditCardValue = 1.2 // 1.2 cents per point
        static let defaultHotelValue = 0.5     // 0.5 cents per point
        static let defaultAirlineValue = 1.0   // 1.0 cents per point
    }
    
    // MARK: - Network Configuration
    struct Network {
        static let requestTimeout: TimeInterval = 30.0
        static let maxRetryAttempts = 3
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let isAnalyticsEnabled = false
        static let isDebugModeEnabled = false
        static let isOfflineModeEnabled = false
    }
    
    // MARK: - Support Information
    struct Support {
        static let email = "nchristus93@gmail.com"
        static let websiteURL = "https://travel-consulting-app-1.web.app"
        static let privacyPolicyURL = "https://travel-consulting-app-1.web.app/privacy"
        static let termsOfServiceURL = "https://travel-consulting-app-1.web.app/terms"
    }
}

// MARK: - Environment Detection
extension AppConfig {
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isTestFlight: Bool {
        // Check if running in TestFlight environment
        // TestFlight apps have a specific bundle identifier pattern or sandbox receipt
        guard let receiptURL = Bundle.main.url(forResource: "receipt", withExtension: nil) else {
            return false
        }
        return receiptURL.path.contains("sandboxReceipt")
    }
    
    static var isAppStore: Bool {
        // Check if running in App Store environment
        // App Store apps have a specific receipt structure
        guard let receiptURL = Bundle.main.url(forResource: "receipt", withExtension: nil) else {
            return false
        }
        let path = receiptURL.path
        return path.contains("receipt") && !path.contains("sandboxReceipt")
    }
    
    /// Validates and returns an external web URL only if it uses an explicit http/https scheme with a non-empty host.
    /// Prevents crashes from malformed strings and blocks unsafe schemes (javascript:, file:, tel:, sms:, etc.).
    static func safeExternalURL(from rawString: String?) -> URL? {
        guard let trimmed = rawString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              (scheme == "https" || scheme == "http"),
              let host = components.host,
              !host.isEmpty else {
            return nil
        }
        return components.url
    }
}
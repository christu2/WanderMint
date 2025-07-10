import Foundation

/// Application configuration constants
struct AppConfig {
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://us-central1-travel-consulting-app-1.cloudfunctions.net"
        
        struct Endpoints {
            static let submitTrip = "\(baseURL)/submitTrip"
        }
    }
    
    // MARK: - App Information
    struct App {
        static let name = "WanderMint"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleId = Bundle.main.bundleIdentifier ?? "com.travelconsulting.app"
    }
    
    // MARK: - User Limits
    struct Limits {
        static let maxTripsPerDay = 3
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
        static let email = "support@travelconsulting.app"
        static let websiteURL = "https://travelconsulting.app"
        static let privacyPolicyURL = "https://travelconsulting.app/privacy"
        static let termsOfServiceURL = "https://travelconsulting.app/terms"
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
        guard let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("sandboxReceipt")
    }
    
    static var isAppStore: Bool {
        guard let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("receipt") && !path.contains("sandboxReceipt")
    }
}
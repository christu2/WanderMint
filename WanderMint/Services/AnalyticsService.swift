import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif
#if canImport(FirebasePerformance)
import FirebasePerformance
#endif

/// Service for tracking user events and crashes in production
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - User Events
    
    /// Track when a user submits a new trip request
    func trackTripSubmission(destinationCount: Int, hasBudget: Bool, flexibleDates: Bool) {
        Analytics.logEvent("trip_submission", parameters: [
            "destination_count": destinationCount,
            "has_budget": hasBudget,
            "flexible_dates": flexibleDates
        ])
    }
    
    /// Track when a user completes onboarding
    func trackOnboardingCompleted(hasPointsData: Bool) {
        Analytics.logEvent("onboarding_completed", parameters: [
            "has_points_data": hasPointsData
        ])
    }
    
    /// Track user authentication events
    func trackUserSignIn(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    func trackUserSignUp(method: String) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    /// Track notification interactions
    func trackNotificationOpened(tripId: String, notificationType: String) {
        Analytics.logEvent("notification_opened", parameters: [
            "trip_id": tripId,
            "notification_type": notificationType
        ])
    }
    
    /// Track conversation interactions
    func trackMessageSent(tripId: String, messageLength: Int) {
        Analytics.logEvent("message_sent", parameters: [
            "trip_id": tripId,
            "message_length": messageLength
        ])
    }
    
    /// Track points management events
    func trackPointsAdded(provider: String, pointsType: String, amount: Int) {
        Analytics.logEvent("points_added", parameters: [
            "provider": provider,
            "points_type": pointsType,
            "amount": amount
        ])
    }
    
    // MARK: - Screen Views
    
    /// Track screen views for user flow analysis
    func trackScreenView(_ screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
    }
    
    // MARK: - User Properties
    
    /// Set user properties for better segmentation
    func setUserProperties(userId: String?, hasCompletedOnboarding: Bool = false) {
        if let userId = userId {
            Analytics.setUserID(userId)
            Crashlytics.crashlytics().setUserID(userId)
        }
        
        Analytics.setUserProperty(hasCompletedOnboarding ? "true" : "false", forName: "onboarding_completed")
    }
    
    // MARK: - Error Tracking
    
    /// Track non-fatal errors for debugging
    func trackError(_ error: Error, context: String = "") {
        let nsError = error as NSError
        
        // Log to Analytics
        Analytics.logEvent("app_error", parameters: [
            "error_domain": nsError.domain,
            "error_code": nsError.code,
            "error_description": error.localizedDescription,
            "context": context
        ])
        
        // Log to Crashlytics
        Crashlytics.crashlytics().record(error: error)
        
        #if DEBUG
        // Error tracked to Firebase Crashlytics
        #endif
    }
    
    /// Track API response times and errors
    func trackAPICall(endpoint: String, duration: TimeInterval, success: Bool, errorCode: String? = nil) {
        var parameters: [String: Any] = [
            "endpoint": endpoint,
            "duration_ms": Int(duration * 1000),
            "success": success
        ]
        
        if let errorCode = errorCode {
            parameters["error_code"] = errorCode
        }
        
        Analytics.logEvent("api_call", parameters: parameters)
    }
    
    // MARK: - Custom Events
    
    /// Track custom business events
    func trackCustomEvent(_ eventName: String, parameters: [String: Any] = [:]) {
        Analytics.logEvent(eventName, parameters: parameters)
        
        #if DEBUG
        // Custom event tracked to Firebase Analytics
        #endif
    }
    
    // MARK: - Performance Monitoring
    
    /// Start a performance trace
    func startTrace(name: String) -> Any? {
        #if !DEBUG && canImport(FirebasePerformance)
        return Performance.startTrace(name: name)
        #else
        return nil
        #endif
    }
    
    /// Track app launch performance
    func trackAppLaunchPerformance(launchTime: TimeInterval) {
        Analytics.logEvent("app_launch_performance", parameters: [
            "launch_time_ms": Int(launchTime * 1000)
        ])
    }
}

// MARK: - Performance Trace Helper

/// Wrapper for Firebase Performance traces
class PerformanceTrace {
    private let trace: Any?
    
    init(name: String) {
        #if !DEBUG
        // In production, we would use Firebase Performance
        // For now, just placeholder since Performance SDK not added
        self.trace = nil
        #else
        self.trace = nil
        #endif
    }
    
    func stop() {
        // Stop the trace in production
    }
    
    func setValue(_ value: Int64, forMetric metric: String) {
        // Set custom metrics
    }
}

// MARK: - Analytics Constants

extension AnalyticsService {
    struct Events {
        static let tripSubmitted = "trip_submitted"
        static let onboardingCompleted = "onboarding_completed"
        static let notificationOpened = "notification_opened"
        static let messageSent = "message_sent"
        static let pointsAdded = "points_added"
        static let errorOccurred = "app_error"
    }
    
    struct UserProperties {
        static let onboardingCompleted = "onboarding_completed"
        static let appVersion = "app_version"
        static let totalTrips = "total_trips"
        static let hasPointsData = "has_points_data"
    }
    
    struct ScreenNames {
        static let tripSubmission = "trip_submission"
        static let tripsList = "trips_list"
        static let tripDetail = "trip_detail"
        static let profileSetup = "profile_setup"
        static let authentication = "authentication"
        static let conversation = "conversation"
        static let pointsManagement = "points_management"
    }
}
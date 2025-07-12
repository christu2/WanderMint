import Foundation
import SwiftUI

/// Comprehensive error recovery and user guidance system
class ErrorRecoveryService {
    static let shared = ErrorRecoveryService()
    
    private init() {}
    
    // MARK: - Error Recovery Strategies
    
    /// Get user-friendly error message and recovery actions
    func getErrorRecovery(for error: Error) -> ErrorRecovery {
        if let travelError = error as? TravelAppError {
            return getRecoveryForTravelError(travelError)
        } else {
            return getRecoveryForGenericError(error)
        }
    }
    
    // MARK: - Travel App Error Recovery
    
    private func getRecoveryForTravelError(_ error: TravelAppError) -> ErrorRecovery {
        switch error {
        case .authenticationFailed:
            return ErrorRecovery(
                title: "Authentication Required",
                message: "Please sign in again to continue.",
                actions: [
                    .signInAgain,
                    .contactSupport
                ],
                isRetryable: false,
                severity: .high
            )
            
        case .networkError(let message):
            return ErrorRecovery(
                title: "Connection Problem",
                message: "We're having trouble connecting to our servers. \(message)",
                actions: [
                    .retry,
                    .checkConnection,
                    .tryOfflineMode
                ],
                isRetryable: true,
                severity: .medium
            )
            
        case .dataError(let message):
            return ErrorRecovery(
                title: "Data Error",
                message: "There was a problem with your data. \(message)",
                actions: [
                    .retry,
                    .clearFormAndRestart,
                    .contactSupport
                ],
                isRetryable: true,
                severity: .medium
            )
            
        case .submissionFailed(let message):
            return ErrorRecovery(
                title: "Submission Failed",
                message: message.isEmpty ? "We couldn't process your request. Please try again." : message,
                actions: [
                    .retry,
                    .editAndResubmit,
                    .saveDraft,
                    .contactSupport
                ],
                isRetryable: true,
                severity: .high
            )
            
        case .networkUnavailable:
            return ErrorRecovery(
                title: "No Internet Connection",
                message: "Please check your internet connection and try again.",
                actions: [
                    .checkConnection,
                    .retry,
                    .tryOfflineMode
                ],
                isRetryable: true,
                severity: .high
            )
            
        case .requestTimeout:
            return ErrorRecovery(
                title: "Request Timed Out",
                message: "The request took too long to complete. This might be due to a slow connection.",
                actions: [
                    .retry,
                    .checkConnection,
                    .tryAgainLater
                ],
                isRetryable: true,
                severity: .medium
            )
            
        case .unknown:
            return ErrorRecovery(
                title: "Something Went Wrong",
                message: "An unexpected error occurred. Our team has been notified.",
                actions: [
                    .retry,
                    .restart,
                    .contactSupport
                ],
                isRetryable: true,
                severity: .medium
            )
        }
    }
    
    // MARK: - Generic Error Recovery
    
    private func getRecoveryForGenericError(_ error: Error) -> ErrorRecovery {
        return ErrorRecovery(
            title: "Unexpected Error",
            message: "Something unexpected happened: \(error.localizedDescription)",
            actions: [
                .retry,
                .restart,
                .contactSupport
            ],
            isRetryable: true,
            severity: .medium
        )
    }
    
    // MARK: - Contextual Recovery
    
    /// Get context-specific error recovery (e.g., during trip submission vs. data loading)
    func getContextualRecovery(for error: Error, context: ErrorContext) -> ErrorRecovery {
        var recovery = getErrorRecovery(for: error)
        
        // Customize actions based on context
        switch context {
        case .tripSubmission:
            recovery.actions.append(.saveDraft)
            recovery.contextualMessage = "Your trip details have been saved locally."
            
        case .dataLoading:
            recovery.actions.insert(.refreshData, at: 0)
            recovery.contextualMessage = "You can continue using cached data."
            
        case .authentication:
            recovery.actions = [.signInAgain, .resetPassword, .createNewAccount]
            
        case .conversation:
            recovery.actions.append(.tryOfflineMode)
            recovery.contextualMessage = "Your message will be sent when connection is restored."
            
        case .pointsManagement:
            recovery.actions.append(.skipForNow)
            recovery.contextualMessage = "You can add points information later in your profile."
        }
        
        return recovery
    }
}

// MARK: - Error Recovery Data Models

struct ErrorRecovery {
    let title: String
    let message: String
    var actions: [RecoveryAction]
    let isRetryable: Bool
    let severity: ErrorSeverity
    var contextualMessage: String?
    
    var primaryAction: RecoveryAction {
        return actions.first ?? .contactSupport
    }
    
    var secondaryActions: [RecoveryAction] {
        return Array(actions.dropFirst())
    }
}

enum RecoveryAction: CaseIterable {
    case retry
    case signInAgain
    case checkConnection
    case tryOfflineMode
    case contactSupport
    case clearFormAndRestart
    case editAndResubmit
    case saveDraft
    case refreshData
    case restart
    case tryAgainLater
    case resetPassword
    case createNewAccount
    case skipForNow
    
    var title: String {
        switch self {
        case .retry:
            return "Try Again"
        case .signInAgain:
            return "Sign In Again"
        case .checkConnection:
            return "Check Connection"
        case .tryOfflineMode:
            return "Continue Offline"
        case .contactSupport:
            return "Contact Support"
        case .clearFormAndRestart:
            return "Start Over"
        case .editAndResubmit:
            return "Edit & Resubmit"
        case .saveDraft:
            return "Save Draft"
        case .refreshData:
            return "Refresh"
        case .restart:
            return "Restart App"
        case .tryAgainLater:
            return "Try Later"
        case .resetPassword:
            return "Reset Password"
        case .createNewAccount:
            return "Create Account"
        case .skipForNow:
            return "Skip for Now"
        }
    }
    
    var systemImage: String {
        switch self {
        case .retry:
            return "arrow.clockwise"
        case .signInAgain:
            return "person.circle"
        case .checkConnection:
            return "wifi"
        case .tryOfflineMode:
            return "icloud.slash"
        case .contactSupport:
            return "questionmark.circle"
        case .clearFormAndRestart:
            return "trash"
        case .editAndResubmit:
            return "pencil"
        case .saveDraft:
            return "square.and.arrow.down"
        case .refreshData:
            return "arrow.clockwise.circle"
        case .restart:
            return "power"
        case .tryAgainLater:
            return "clock"
        case .resetPassword:
            return "key"
        case .createNewAccount:
            return "person.badge.plus"
        case .skipForNow:
            return "arrow.right"
        }
    }
    
    var style: RecoveryActionStyle {
        switch self {
        case .retry, .refreshData, .editAndResubmit:
            return .primary
        case .signInAgain, .checkConnection, .saveDraft:
            return .secondary
        case .contactSupport, .tryAgainLater, .skipForNow:
            return .tertiary
        case .clearFormAndRestart, .restart:
            return .destructive
        default:
            return .secondary
        }
    }
}

enum RecoveryActionStyle {
    case primary
    case secondary
    case tertiary
    case destructive
}

enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
    
    var color: Color {
        switch self {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
}

enum ErrorContext {
    case tripSubmission
    case dataLoading
    case authentication
    case conversation
    case pointsManagement
}

// MARK: - SwiftUI Error Recovery View

struct ErrorRecoveryView: View {
    let recovery: ErrorRecovery
    let onAction: (RecoveryAction) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: iconForSeverity(recovery.severity))
                .font(.system(size: 50))
                .foregroundColor(recovery.severity.color)
            
            // Error Details
            VStack(spacing: 8) {
                Text(recovery.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(recovery.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let contextualMessage = recovery.contextualMessage {
                    Text(contextualMessage)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            
            // Recovery Actions
            VStack(spacing: 12) {
                // Primary Action
                Button(action: {
                    onAction(recovery.primaryAction)
                }) {
                    HStack {
                        Image(systemName: recovery.primaryAction.systemImage)
                        Text(recovery.primaryAction.title)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(recovery.primaryAction.style == .primary ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(recovery.primaryAction.style == .primary ? .white : .primary)
                    .cornerRadius(12)
                }
                
                // Secondary Actions
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(recovery.secondaryActions, id: \.title) { action in
                        Button(action: {
                            onAction(action)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: action.systemImage)
                                Text(action.title)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(action.style == .destructive ? .red : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(24)
    }
    
    private func iconForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .low:
            return "info.circle"
        case .medium:
            return "exclamationmark.triangle"
        case .high:
            return "xmark.circle"
        case .critical:
            return "exclamationmark.octagon"
        }
    }
}

// MARK: - Error Recovery Extensions

extension View {
    /// Show error recovery overlay for any error
    func errorRecovery(
        error: Binding<Error?>,
        context: ErrorContext = .dataLoading,
        onAction: @escaping (RecoveryAction) -> Void
    ) -> some View {
        self.overlay(
            Group {
                if let currentError = error.wrappedValue {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // Don't dismiss on tap - require explicit action
                        }
                    
                    ErrorRecoveryView(
                        recovery: ErrorRecoveryService.shared.getContextualRecovery(
                            for: currentError,
                            context: context
                        ),
                        onAction: { action in
                            onAction(action)
                            // Clear error after action
                            error.wrappedValue = nil
                        }
                    )
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 20)
                    .padding(20)
                }
            }
        )
    }
}
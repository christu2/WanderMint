import XCTest
@testable import WanderMint

class ErrorRecoveryTests: XCTestCase {
    
    var errorRecoveryService: ErrorRecoveryService!
    
    override func setUp() {
        super.setUp()
        errorRecoveryService = ErrorRecoveryService.shared
    }
    
    override func tearDown() {
        errorRecoveryService = nil
        super.tearDown()
    }
    
    // MARK: - Travel App Error Recovery Tests
    
    func testAuthenticationFailedRecovery() {
        let error = TravelAppError.authenticationFailed
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        XCTAssertEqual(recovery.title, "Authentication Required")
        XCTAssertTrue(recovery.message.contains("sign in"))
        XCTAssertTrue(recovery.actions.contains(.signInAgain))
        XCTAssertTrue(recovery.actions.contains(.contactSupport))
        XCTAssertFalse(recovery.isRetryable)
        XCTAssertEqual(recovery.severity, .high)
    }
    
    func testNetworkErrorRecovery() {
        let error = TravelAppError.networkError("Connection timeout")
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        XCTAssertEqual(recovery.title, "Connection Problem")
        XCTAssertTrue(recovery.message.contains("Connection timeout"))
        XCTAssertTrue(recovery.actions.contains(.retry))
        XCTAssertTrue(recovery.actions.contains(.checkConnection))
        XCTAssertTrue(recovery.actions.contains(.tryOfflineMode))
        XCTAssertTrue(recovery.isRetryable)
        XCTAssertEqual(recovery.severity, .medium)
    }
    
    func testDataErrorRecovery() {
        let error = TravelAppError.dataError("Invalid format")
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        XCTAssertEqual(recovery.title, "Data Error")
        XCTAssertTrue(recovery.message.contains("Invalid format"))
        XCTAssertTrue(recovery.actions.contains(.retry))
        XCTAssertTrue(recovery.actions.contains(.clearFormAndRestart))
        XCTAssertTrue(recovery.actions.contains(.contactSupport))
        XCTAssertTrue(recovery.isRetryable)
        XCTAssertEqual(recovery.severity, .medium)
    }
    
    func testSubmissionFailedRecovery() {
        let error = TravelAppError.submissionFailed("Server error")
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        XCTAssertEqual(recovery.title, "Submission Failed")
        XCTAssertTrue(recovery.message.contains("Server error"))
        XCTAssertTrue(recovery.actions.contains(.retry))
        XCTAssertTrue(recovery.actions.contains(.editAndResubmit))
        XCTAssertTrue(recovery.actions.contains(.saveDraft))
        XCTAssertTrue(recovery.actions.contains(.contactSupport))
        XCTAssertTrue(recovery.isRetryable)
        XCTAssertEqual(recovery.severity, .high)
    }
    
    func testNetworkUnavailableRecovery() {
        let error = TravelAppError.networkUnavailable
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        XCTAssertEqual(recovery.title, "No Internet Connection")
        XCTAssertTrue(recovery.message.contains("internet connection"))
        XCTAssertTrue(recovery.actions.contains(.checkConnection))
        XCTAssertTrue(recovery.actions.contains(.retry))
        XCTAssertTrue(recovery.actions.contains(.tryOfflineMode))
        XCTAssertTrue(recovery.isRetryable)
        XCTAssertEqual(recovery.severity, .high)
    }
    
    func testRequestTimeoutRecovery() {
        let error = TravelAppError.requestTimeout
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        XCTAssertEqual(recovery.title, "Request Timed Out")
        XCTAssertTrue(recovery.message.contains("took too long"))
        XCTAssertTrue(recovery.actions.contains(.retry))
        XCTAssertTrue(recovery.actions.contains(.checkConnection))
        XCTAssertTrue(recovery.actions.contains(.tryAgainLater))
        XCTAssertTrue(recovery.isRetryable)
        XCTAssertEqual(recovery.severity, .medium)
    }
    
    func testUnknownErrorRecovery() {
        let error = TravelAppError.unknown
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        XCTAssertEqual(recovery.title, "Something Went Wrong")
        XCTAssertTrue(recovery.message.contains("unexpected error"))
        XCTAssertTrue(recovery.actions.contains(.retry))
        XCTAssertTrue(recovery.actions.contains(.restart))
        XCTAssertTrue(recovery.actions.contains(.contactSupport))
        XCTAssertTrue(recovery.isRetryable)
        XCTAssertEqual(recovery.severity, .medium)
    }
    
    // MARK: - Generic Error Recovery Tests
    
    func testGenericErrorRecovery() {
        let error = NSError(domain: "TestError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        XCTAssertEqual(recovery.title, "Unexpected Error")
        XCTAssertTrue(recovery.message.contains("Test error"))
        XCTAssertTrue(recovery.actions.contains(.retry))
        XCTAssertTrue(recovery.actions.contains(.restart))
        XCTAssertTrue(recovery.actions.contains(.contactSupport))
        XCTAssertTrue(recovery.isRetryable)
        XCTAssertEqual(recovery.severity, .medium)
    }
    
    // MARK: - Contextual Recovery Tests
    
    func testTripSubmissionContextRecovery() {
        let error = TravelAppError.submissionFailed("Network error")
        let recovery = errorRecoveryService.getContextualRecovery(for: error, context: .tripSubmission)
        
        XCTAssertTrue(recovery.actions.contains(.saveDraft))
        XCTAssertEqual(recovery.contextualMessage, "Your trip details have been saved locally.")
    }
    
    func testDataLoadingContextRecovery() {
        let error = TravelAppError.networkError("Connection failed")
        let recovery = errorRecoveryService.getContextualRecovery(for: error, context: .dataLoading)
        
        XCTAssertTrue(recovery.actions.contains(.refreshData))
        XCTAssertEqual(recovery.contextualMessage, "You can continue using cached data.")
        XCTAssertEqual(recovery.actions.first, .refreshData)
    }
    
    func testAuthenticationContextRecovery() {
        let error = TravelAppError.authenticationFailed
        let recovery = errorRecoveryService.getContextualRecovery(for: error, context: .authentication)
        
        XCTAssertTrue(recovery.actions.contains(.signInAgain))
        XCTAssertTrue(recovery.actions.contains(.resetPassword))
        XCTAssertTrue(recovery.actions.contains(.createNewAccount))
        XCTAssertEqual(recovery.actions, [.signInAgain, .resetPassword, .createNewAccount])
    }
    
    func testConversationContextRecovery() {
        let error = TravelAppError.networkUnavailable
        let recovery = errorRecoveryService.getContextualRecovery(for: error, context: .conversation)
        
        XCTAssertTrue(recovery.actions.contains(.tryOfflineMode))
        XCTAssertEqual(recovery.contextualMessage, "Your message will be sent when connection is restored.")
    }
    
    func testPointsManagementContextRecovery() {
        let error = TravelAppError.dataError("Invalid points data")
        let recovery = errorRecoveryService.getContextualRecovery(for: error, context: .pointsManagement)
        
        XCTAssertTrue(recovery.actions.contains(.skipForNow))
        XCTAssertEqual(recovery.contextualMessage, "You can add points information later in your profile.")
    }
    
    // MARK: - Recovery Action Tests
    
    func testRecoveryActionTitles() {
        let expectedTitles: [RecoveryAction: String] = [
            .retry: "Try Again",
            .signInAgain: "Sign In Again",
            .checkConnection: "Check Connection",
            .tryOfflineMode: "Continue Offline",
            .contactSupport: "Contact Support",
            .clearFormAndRestart: "Start Over",
            .editAndResubmit: "Edit & Resubmit",
            .saveDraft: "Save Draft",
            .refreshData: "Refresh",
            .restart: "Restart App",
            .tryAgainLater: "Try Later",
            .resetPassword: "Reset Password",
            .createNewAccount: "Create Account",
            .skipForNow: "Skip for Now"
        ]
        
        for (action, expectedTitle) in expectedTitles {
            XCTAssertEqual(action.title, expectedTitle, "Action \(action) should have title '\(expectedTitle)'")
        }
    }
    
    func testRecoveryActionSystemImages() {
        let expectedImages: [RecoveryAction: String] = [
            .retry: "arrow.clockwise",
            .signInAgain: "person.circle",
            .checkConnection: "wifi",
            .tryOfflineMode: "icloud.slash",
            .contactSupport: "questionmark.circle",
            .clearFormAndRestart: "trash",
            .editAndResubmit: "pencil",
            .saveDraft: "square.and.arrow.down",
            .refreshData: "arrow.clockwise.circle",
            .restart: "power",
            .tryAgainLater: "clock",
            .resetPassword: "key",
            .createNewAccount: "person.badge.plus",
            .skipForNow: "arrow.right"
        ]
        
        for (action, expectedImage) in expectedImages {
            XCTAssertEqual(action.systemImage, expectedImage, "Action \(action) should have system image '\(expectedImage)'")
        }
    }
    
    func testRecoveryActionStyles() {
        let primaryActions: [RecoveryAction] = [.retry, .refreshData, .editAndResubmit]
        let secondaryActions: [RecoveryAction] = [.signInAgain, .checkConnection, .saveDraft]
        let tertiaryActions: [RecoveryAction] = [.contactSupport, .tryAgainLater, .skipForNow]
        let destructiveActions: [RecoveryAction] = [.clearFormAndRestart, .restart]
        
        for action in primaryActions {
            XCTAssertEqual(action.style, .primary, "Action \(action) should have primary style")
        }
        
        for action in secondaryActions {
            XCTAssertEqual(action.style, .secondary, "Action \(action) should have secondary style")
        }
        
        for action in tertiaryActions {
            XCTAssertEqual(action.style, .tertiary, "Action \(action) should have tertiary style")
        }
        
        for action in destructiveActions {
            XCTAssertEqual(action.style, .destructive, "Action \(action) should have destructive style")
        }
    }
    
    // MARK: - Error Severity Tests
    
    func testErrorSeverityColors() {
        XCTAssertEqual(ErrorSeverity.low.color, .blue)
        XCTAssertEqual(ErrorSeverity.medium.color, .orange)
        XCTAssertEqual(ErrorSeverity.high.color, .red)
        XCTAssertEqual(ErrorSeverity.critical.color, .purple)
    }
    
    // MARK: - Error Recovery Structure Tests
    
    func testPrimaryAction() {
        let error = TravelAppError.networkError("Test")
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        XCTAssertEqual(recovery.primaryAction, recovery.actions.first)
    }
    
    func testSecondaryActions() {
        let error = TravelAppError.networkError("Test")
        let recovery = errorRecoveryService.getErrorRecovery(for: error)
        
        let expectedSecondaryActions = Array(recovery.actions.dropFirst())
        XCTAssertEqual(recovery.secondaryActions, expectedSecondaryActions)
    }
    
    func testEmptyActionsArray() {
        // Create a custom error recovery with empty actions
        let recovery = ErrorRecovery(
            title: "Test",
            message: "Test message",
            actions: [],
            isRetryable: false,
            severity: .low
        )
        
        XCTAssertEqual(recovery.primaryAction, .contactSupport)
        XCTAssertTrue(recovery.secondaryActions.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testErrorRecoveryPerformance() {
        let errors: [Error] = [
            TravelAppError.authenticationFailed,
            TravelAppError.networkError("Test"),
            TravelAppError.dataError("Test"),
            TravelAppError.submissionFailed("Test"),
            TravelAppError.networkUnavailable,
            TravelAppError.requestTimeout,
            TravelAppError.unknown
        ]
        
        measure {
            for error in errors {
                _ = errorRecoveryService.getErrorRecovery(for: error)
            }
        }
    }
    
    func testContextualRecoveryPerformance() {
        let error = TravelAppError.networkError("Test")
        let contexts: [ErrorContext] = [
            .tripSubmission,
            .dataLoading,
            .authentication,
            .conversation,
            .pointsManagement
        ]
        
        measure {
            for context in contexts {
                _ = errorRecoveryService.getContextualRecovery(for: error, context: context)
            }
        }
    }
}
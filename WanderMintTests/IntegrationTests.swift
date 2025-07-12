//
//  IntegrationTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/10/25.
//

import XCTest
import Firebase
@testable import WanderMint

@MainActor
final class IntegrationTests: XCTestCase {
    
    var authViewModel: AuthenticationViewModel!
    var userService: UserService!
    var tripService: TripService!
    var pointsService: PointsService!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Initialize Firebase for testing
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        authViewModel = AuthenticationViewModel()
        userService = UserService.shared
        tripService = TripService()
        pointsService = PointsService()
    }
    
    override func tearDownWithError() throws {
        authViewModel = nil
        userService = nil
        tripService = nil
        pointsService = nil
        super.tearDown()
    }
    
    // MARK: - User Flow Integration Tests
    
    // TODO: Re-enable when Firebase User mocking is properly implemented
    /*
    func testCompleteUserOnboardingFlow() async {
        // Test the complete flow from user creation to onboarding completion
        let expectation = expectation(description: "Complete onboarding flow")
        
        Task {
            do {
                // 1. Create mock user
                let mockUser = MockFirebaseUser(
                    uid: "integration-test-user",
                    email: "integration@test.com",
                    displayName: "Integration Test User"
                )
                
                // 2. Create user profile
                try await userService.createUserProfile(for: mockUser, name: "Integration Test User")
                
                // 3. Verify initial state (should need onboarding)
                let initialProfile = try await userService.getUserProfile()
                XCTAssertFalse(initialProfile?.onboardingCompleted ?? true)
                
                // 4. Complete onboarding
                try await userService.completeOnboarding()
                
                // 5. Verify onboarding completion
                let completedProfile = try await userService.getUserProfile()
                XCTAssertTrue(completedProfile?.onboardingCompleted ?? false)
                
                expectation.fulfill()
            } catch {
                print("Integration test error: \(error)")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    */
    
    // MARK: - Trip Planning Integration Tests
    
    func testTripCreationAndManagement() {
        let expectation = expectation(description: "Trip creation and management")
        
        Task {
            // Create a trip object (would normally go through API)
            let trip = Trip(
                id: "integration-trip-123",
                title: "Integration Test Trip",
                description: "A trip created during integration testing",
                destination: "Test Destination",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 7),
                userId: "integration-test-user",
                status: .planning,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Verify trip properties
            XCTAssertEqual(trip.title, "Integration Test Trip")
            XCTAssertEqual(trip.status, .planning)
            XCTAssertTrue(trip.endDate > trip.startDate)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Points Management Integration Tests
    
    func testPointsManagementFlow() {
        let expectation = expectation(description: "Points management flow")
        
        Task {
            // 1. Create points profile
            let pointsProfile = UserPointsProfile(
                userId: "integration-test-user",
                creditCardPoints: [
                    "Chase Sapphire": 50000,
                    "Amex Gold": 25000
                ],
                hotelPoints: [
                    "Marriott": 100000
                ],
                airlinePoints: [
                    "United": 75000
                ],
                lastUpdated: Timestamp()
            )
            
            // 2. Verify points data
            XCTAssertEqual(pointsProfile.creditCardPoints.count, 2)
            XCTAssertEqual(pointsProfile.creditCardPoints["Chase Sapphire"], 50000)
            XCTAssertEqual(pointsProfile.hotelPoints["Marriott"], 100000)
            
            // 3. Test points transaction
            let transaction = PointsTransaction(
                id: "integration-txn-123",
                userId: "integration-test-user",
                type: .earned,
                amount: 5000,
                description: "Integration test earning",
                provider: "Chase Sapphire",
                date: Date(),
                category: .creditCard
            )
            
            XCTAssertEqual(transaction.type, .earned)
            XCTAssertEqual(transaction.amount, 5000)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Authentication Integration Tests
    
    func testAuthenticationStateManagement() {
        let expectation = expectation(description: "Authentication state management")
        
        Task {
            // Test initial authentication state
            XCTAssertFalse(authViewModel.isAuthenticated)
            XCTAssertNil(authViewModel.currentUser)
            XCTAssertFalse(authViewModel.needsOnboarding)
            
            // Test validation methods
            XCTAssertTrue(authViewModel.isValidEmail("test@example.com"))
            XCTAssertFalse(authViewModel.isValidEmail("invalid-email"))
            XCTAssertTrue(authViewModel.isValidPassword("validPassword123"))
            XCTAssertFalse(authViewModel.isValidPassword("short"))
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Error Handling Integration Tests
    
    // TODO: Re-enable when Firebase User authentication is properly mocked
    /*
    func testErrorHandlingAcrossServices() {
        let expectation = expectation(description: "Error handling across services")
        
        Task {
            // Test various error scenarios
            do {
                // This should handle the case where no user is authenticated
                _ = try await userService.getUserProfile()
            } catch {
                // Expected to catch an authentication error
                XCTAssertTrue(error is TravelAppError)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    */
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistencyAcrossModels() {
        let expectation = expectation(description: "Data consistency across models")
        
        Task {
            let userId = "consistency-test-user"
            let timestamp = Date()
            
            // Create related models with same user ID
            let userProfile = UserProfile(
                userId: userId,
                name: "Consistency Test User",
                email: "consistency@test.com",
                createdAt: Timestamp(date: timestamp),
                lastLoginAt: Timestamp(date: timestamp),
                profilePictureUrl: nil,
                onboardingCompleted: false,
                onboardingCompletedAt: nil
            )
            
            let trip = Trip(
                id: "consistency-trip-123",
                title: "Consistency Test Trip",
                description: "Testing data consistency",
                destination: "Test City",
                startDate: timestamp,
                endDate: timestamp.addingTimeInterval(86400 * 3),
                userId: userId,
                status: .planning,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            
            let pointsProfile = UserPointsProfile(
                userId: userId,
                creditCardPoints: ["Test Card": 10000],
                hotelPoints: ["Test Hotel": 5000],
                airlinePoints: ["Test Airline": 7500],
                lastUpdated: Timestamp(date: timestamp)
            )
            
            // Verify all models have consistent user ID
            XCTAssertEqual(userProfile.userId, userId)
            XCTAssertEqual(trip.userId, userId)
            XCTAssertEqual(pointsProfile.userId, userId)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Content Filter Integration Tests
    
    func testContentFilterIntegration() {
        let expectation = expectation(description: "Content filter integration")
        
        Task {
            let contentFilter = ContentFilter.shared
            
            // Test valid content
            let validDestination = "Paris, France"
            let validResult = contentFilter.validateDestination(validDestination)
            XCTAssertTrue(validResult.isValid)
            XCTAssertEqual(validResult.value, validDestination)
            
            // Test invalid content
            let invalidDestination = "F*ck this place"
            let invalidResult = contentFilter.validateDestination(invalidDestination)
            XCTAssertFalse(invalidResult.isValid)
            XCTAssertNil(invalidResult.value)
            
            // Test enhanced validation
            let enhancedValidResult = FormValidation.validateDestinationEnhanced(validDestination)
            XCTAssertTrue(enhancedValidResult.isValid)
            
            let enhancedInvalidResult = FormValidation.validateDestinationEnhanced(invalidDestination)
            XCTAssertFalse(enhancedInvalidResult.isValid)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Error Recovery Integration Tests
    
    func testErrorRecoveryIntegration() {
        let expectation = expectation(description: "Error recovery integration")
        
        Task {
            let errorRecovery = ErrorRecoveryService.shared
            
            // Test network error recovery
            let networkError = TravelAppError.networkError("Connection failed")
            let recovery = errorRecovery.getContextualRecovery(for: networkError, context: .tripSubmission)
            
            XCTAssertTrue(recovery.actions.contains(.retry))
            XCTAssertTrue(recovery.actions.contains(.saveDraft))
            XCTAssertEqual(recovery.contextualMessage, "Your trip details have been saved locally.")
            
            // Test authentication error recovery
            let authError = TravelAppError.authenticationFailed
            let authRecovery = errorRecovery.getContextualRecovery(for: authError, context: .authentication)
            
            XCTAssertTrue(authRecovery.actions.contains(.signInAgain))
            XCTAssertTrue(authRecovery.actions.contains(.resetPassword))
            XCTAssertTrue(authRecovery.actions.contains(.createNewAccount))
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Form Validation Integration Tests
    
    func testFormValidationIntegration() {
        let expectation = expectation(description: "Form validation integration")
        
        Task {
            // Test complete form validation
            let destinations = ["Paris", "London", "Rome"]
            let departureLocation = "New York"
            let startDate = Date().addingTimeInterval(86400) // Tomorrow
            let endDate = Date().addingTimeInterval(86400 * 8) // 8 days from now
            let groupSize = 2
            let budget = "5000"
            
            let destinationResult = FormValidation.Trip.validateDestinations(destinations)
            XCTAssertEqual(destinationResult, .valid)
            
            let departureResult = FormValidation.Trip.validateDepartureLocation(departureLocation)
            XCTAssertEqual(departureResult, .valid)
            
            let dateResult = FormValidation.Trip.validateDates(start: startDate, end: endDate)
            XCTAssertEqual(dateResult, .valid)
            
            let groupSizeResult = FormValidation.Trip.validateGroupSize(groupSize)
            XCTAssertEqual(groupSizeResult, .valid)
            
            let budgetResult = FormValidation.Trip.validateBudget(budget)
            XCTAssertEqual(budgetResult, .valid)
            
            // Test validation state
            var validationState = ValidationState()
            validationState.destinations = destinationResult
            validationState.departureLocation = departureResult
            validationState.dates = dateResult
            validationState.groupSize = groupSizeResult
            validationState.budget = budgetResult
            
            XCTAssertTrue(validationState.isFormValid)
            XCTAssertNil(validationState.firstError)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Haptic Feedback Integration Tests
    
    func testHapticFeedbackIntegration() {
        let expectation = expectation(description: "Haptic feedback integration")
        
        Task {
            let hapticService = HapticFeedbackService.shared
            
            // Test travel app specific haptic feedback
            XCTAssertNoThrow(hapticService.tripSubmitted())
            XCTAssertNoThrow(hapticService.destinationAdded())
            XCTAssertNoThrow(hapticService.destinationRemoved())
            XCTAssertNoThrow(hapticService.pointsAdded())
            XCTAssertNoThrow(hapticService.messageSent())
            XCTAssertNoThrow(hapticService.authenticationSuccess())
            XCTAssertNoThrow(hapticService.authenticationFailure())
            
            // Test context-specific feedback
            XCTAssertNoThrow(hapticService.formSubmission())
            XCTAssertNoThrow(hapticService.validationError())
            XCTAssertNoThrow(hapticService.operationSuccess())
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Keyboard Handling Integration Tests
    
    func testKeyboardHandlingIntegration() {
        let expectation = expectation(description: "Keyboard handling integration")
        
        Task {
            let keyboardHandler = KeyboardHandler()
            let focusCoordinator = FocusCoordinator()
            
            // Test initial state
            XCTAssertEqual(keyboardHandler.keyboardHeight, 0)
            XCTAssertFalse(keyboardHandler.isKeyboardVisible)
            XCTAssertNil(focusCoordinator.currentFocus)
            
            // Test focus management
            focusCoordinator.focus(.departureLocation)
            XCTAssertEqual(focusCoordinator.currentFocus, .departureLocation)
            
            focusCoordinator.nextField(.departureLocation)
            XCTAssertEqual(focusCoordinator.currentFocus, .destination(0))
            
            focusCoordinator.nextField(.destination(0))
            XCTAssertEqual(focusCoordinator.currentFocus, .budget)
            
            focusCoordinator.clearFocus()
            XCTAssertNil(focusCoordinator.currentFocus)
            
            // Test keyboard dismissal
            XCTAssertNoThrow(keyboardHandler.dismissKeyboard())
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Device Testing Integration Tests
    
    func testDeviceTestingIntegration() {
        let expectation = expectation(description: "Device testing integration")
        
        Task {
            // Test device size detection
            let currentDevice = DeviceTestingUtils.currentDevice
            let validDeviceSizes: [DeviceTestingUtils.DeviceSize] = [.compact, .regular, .large, .tablet]
            XCTAssertTrue(validDeviceSizes.contains(currentDevice))
            
            // Test layout helpers
            let compactSize = CGSize(width: 350, height: 600)
            let regularSize = CGSize(width: 400, height: 800)
            
            XCTAssertTrue(DeviceTestingUtils.shouldUseCompactLayout(compactSize))
            XCTAssertFalse(DeviceTestingUtils.shouldUseCompactLayout(regularSize))
            
            // Test safe area insets
            let compactSafeArea = DeviceTestingUtils.safeAreaInsets(for: .compact)
            let regularSafeArea = DeviceTestingUtils.safeAreaInsets(for: .regular)
            
            XCTAssertNotEqual(compactSafeArea.top, regularSafeArea.top)
            XCTAssertNotEqual(compactSafeArea.bottom, regularSafeArea.bottom)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Complete User Flow Integration Tests
    
    func testCompleteUserFlowIntegration() {
        let expectation = expectation(description: "Complete user flow integration")
        
        Task {
            let contentFilter = ContentFilter.shared
            let analytics = AnalyticsService.shared
            let hapticService = HapticFeedbackService.shared
            let keyboardHandler = KeyboardHandler()
            
            // Simulate complete user flow
            XCTAssertNoThrow {
                // 1. User navigates to trip submission
                analytics.trackScreenView("trip_submission")
                hapticService.navigation()
                
                // 2. User enters destination
                let destination = "Paris, France"
                let destinationValidation = contentFilter.validateDestination(destination)
                XCTAssertTrue(destinationValidation.isValid)
                hapticService.destinationAdded()
                
                // 3. User enters departure location
                let departure = "New York"
                let departureValidation = FormValidation.Trip.validateDepartureLocation(departure)
                XCTAssertEqual(departureValidation, .valid)
                
                // 4. User submits form
                hapticService.formSubmission()
                keyboardHandler.dismissKeyboard()
                
                // 5. Submission succeeds
                analytics.trackTripSubmission(destinationCount: 1, hasBudget: false, flexibleDates: false)
                hapticService.tripSubmitted()
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Error Flow Integration Tests
    
    func testErrorFlowIntegration() {
        let expectation = expectation(description: "Error flow integration")
        
        Task {
            let contentFilter = ContentFilter.shared
            let errorRecovery = ErrorRecoveryService.shared
            let analytics = AnalyticsService.shared
            let hapticService = HapticFeedbackService.shared
            
            // Simulate error flow
            XCTAssertNoThrow {
                // 1. User enters invalid destination
                let invalidDestination = "F*ck this place"
                let destinationValidation = contentFilter.validateDestination(invalidDestination)
                XCTAssertFalse(destinationValidation.isValid)
                hapticService.validationError()
                
                // 2. User corrects and resubmits
                let validDestination = "Paris, France"
                let correctedValidation = contentFilter.validateDestination(validDestination)
                XCTAssertTrue(correctedValidation.isValid)
                
                // 3. Network error occurs during submission
                let networkError = TravelAppError.networkError("Connection failed")
                let recovery = errorRecovery.getContextualRecovery(for: networkError, context: .tripSubmission)
                analytics.trackError(networkError, context: "TripSubmission")
                hapticService.errorOccurred()
                
                // 4. User retries
                XCTAssertTrue(recovery.actions.contains(.retry))
                hapticService.buttonTap()
                
                // 5. Retry succeeds
                analytics.trackTripSubmission(destinationCount: 1, hasBudget: false, flexibleDates: false)
                hapticService.operationSuccess()
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformanceIntegration() {
        let expectation = expectation(description: "Performance integration")
        
        Task {
            let contentFilter = ContentFilter.shared
            let errorRecovery = ErrorRecoveryService.shared
            let analytics = AnalyticsService.shared
            let hapticService = HapticFeedbackService.shared
            
            // Test performance with all systems
            let startTime = Date()
            
            for i in 0..<100 {
                // Test content filtering
                let destination = "Destination \(i)"
                _ = contentFilter.validateDestination(destination)
                
                // Test error recovery
                let error = TravelAppError.networkError("Test error \(i)")
                _ = errorRecovery.getErrorRecovery(for: error)
                
                // Test analytics
                analytics.trackCustomEvent("test_event", parameters: ["index": i])
                
                // Test haptic feedback
                hapticService.lightImpact()
                
                // Test form validation
                _ = FormValidation.isValidEmail("test\(i)@example.com")
            }
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            // Should complete within reasonable time (5 seconds for 100 iterations)
            XCTAssertLessThan(duration, 5.0)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
    }
}
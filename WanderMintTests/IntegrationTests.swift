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
}
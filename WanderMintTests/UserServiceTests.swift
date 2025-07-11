//
//  UserServiceTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/10/25.
//

import XCTest
import Firebase
import FirebaseFirestore
@testable import WanderMint

@MainActor
final class UserServiceTests: XCTestCase {
    
    var userService: UserService!
    
    override func setUpWithError() throws {
        super.setUp()
        // Initialize Firebase if not already initialized
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        userService = UserService.shared
    }
    
    override func tearDownWithError() throws {
        userService = nil
        super.tearDown()
    }
    
    // MARK: - User Profile Creation Tests
    
    // TODO: Re-enable when Firebase User mocking is properly implemented
    /*
    func testUserProfileCreation() {
        let mockUser = MockFirebaseUser(
            uid: "test-uid-123",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        let expectation = expectation(description: "User profile creation should complete")
        
        Task {
            do {
                try await userService.createUserProfile(for: mockUser, name: "Test User")
                expectation.fulfill()
            } catch {
                XCTFail("User profile creation should not fail: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    */
    
    // MARK: - Profile Data Validation Tests
    
    func testUserProfileDataStructure() {
        let userProfile = UserProfile(
            userId: "test-user-123",
            name: "John Doe",
            email: "john.doe@example.com",
            createdAt: Timestamp(),
            lastLoginAt: Timestamp(),
            profilePictureUrl: nil,
            onboardingCompleted: false,
            onboardingCompletedAt: nil
        )
        
        XCTAssertEqual(userProfile.userId, "test-user-123")
        XCTAssertEqual(userProfile.name, "John Doe")
        XCTAssertEqual(userProfile.email, "john.doe@example.com")
        XCTAssertFalse(userProfile.onboardingCompleted)
        XCTAssertNil(userProfile.onboardingCompletedAt)
    }
    
    func testOnboardingCompletion() {
        var userProfile = UserProfile(
            userId: "test-user-123",
            name: "Jane Doe",
            email: "jane.doe@example.com",
            createdAt: Timestamp(),
            lastLoginAt: Timestamp(),
            profilePictureUrl: nil,
            onboardingCompleted: false,
            onboardingCompletedAt: nil
        )
        
        XCTAssertFalse(userProfile.onboardingCompleted)
        
        // Simulate onboarding completion
        userProfile.onboardingCompleted = true
        userProfile.onboardingCompletedAt = Timestamp()
        
        XCTAssertTrue(userProfile.onboardingCompleted)
        XCTAssertNotNil(userProfile.onboardingCompletedAt)
    }
}
//
//  AuthenticationViewModelTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/10/25.
//

import XCTest
import Firebase
import FirebaseAuth
@testable import WanderMint

@MainActor
final class AuthenticationViewModelTests: XCTestCase {
    
    var viewModel: AuthenticationViewModel!
    var mockUserService: MockUserService!
    
    override func setUpWithError() throws {
        super.setUp()
        // Initialize Firebase if not already initialized
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        mockUserService = MockUserService()
        viewModel = AuthenticationViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockUserService = nil
        super.tearDown()
    }
    
    // MARK: - Email Validation Tests
    
    func testValidEmailFormat() {
        XCTAssertTrue(viewModel.isValidEmail("test@example.com"))
        XCTAssertTrue(viewModel.isValidEmail("user.name+tag@example.com"))
        XCTAssertTrue(viewModel.isValidEmail("test123@domain.co.uk"))
    }
    
    func testInvalidEmailFormat() {
        XCTAssertFalse(viewModel.isValidEmail(""))
        XCTAssertFalse(viewModel.isValidEmail("invalid-email"))
        XCTAssertFalse(viewModel.isValidEmail("@example.com"))
        XCTAssertFalse(viewModel.isValidEmail("test@"))
        XCTAssertFalse(viewModel.isValidEmail("test.example.com"))
    }
    
    // MARK: - Password Validation Tests
    
    func testValidPassword() {
        XCTAssertTrue(viewModel.isValidPassword("123456"))
        XCTAssertTrue(viewModel.isValidPassword("strongPassword123"))
        XCTAssertTrue(viewModel.isValidPassword("minimumLength"))
    }
    
    func testInvalidPassword() {
        XCTAssertFalse(viewModel.isValidPassword(""))
        XCTAssertFalse(viewModel.isValidPassword("12345"))
        XCTAssertFalse(viewModel.isValidPassword("short"))
    }
    
    // MARK: - State Management Tests
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertNil(viewModel.userProfile)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.needsOnboarding)
    }
    
    func testClearError() {
        viewModel.errorMessage = "Test error"
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadingStateManagement() {
        // Test loading state is set during sign in
        let expectation = expectation(description: "Loading state should be managed")
        
        viewModel.signIn(email: "test@example.com", password: "password123")
        
        // Initially loading should be true
        XCTAssertTrue(viewModel.isLoading)
        
        // After completion, loading should be false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertFalse(self.viewModel.isLoading)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3.0)
    }
}

// MARK: - Mock Classes

class MockUserService: UserService {
    var shouldSucceed = true
    var mockUserProfile: UserProfile?
    
    override func createUserProfile(for user: User, name: String = "") async throws {
        if !shouldSucceed {
            throw TravelAppError.dataError("Mock create user profile error")
        }
    }
    
    override func getUserProfile() async throws -> UserProfile? {
        if !shouldSucceed {
            throw TravelAppError.dataError("Mock get user profile error")
        }
        return mockUserProfile
    }
    
    override func updateUserProfile(name: String) async throws {
        if !shouldSucceed {
            throw TravelAppError.dataError("Mock update user profile error")
        }
    }
    
    override func completeOnboarding() async throws {
        if !shouldSucceed {
            throw TravelAppError.dataError("Mock complete onboarding error")
        }
    }
}
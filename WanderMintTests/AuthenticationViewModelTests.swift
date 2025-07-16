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
        XCTAssertTrue(viewModel.isValidPassword("Password123!"))
        XCTAssertTrue(viewModel.isValidPassword("StrongPass1@"))
        XCTAssertTrue(viewModel.isValidPassword("MySecure123#"))
    }
    
    func testInvalidPassword() {
        XCTAssertFalse(viewModel.isValidPassword(""))
        XCTAssertFalse(viewModel.isValidPassword("12345"))
        XCTAssertFalse(viewModel.isValidPassword("short"))
        XCTAssertFalse(viewModel.isValidPassword("password123"))  // No uppercase or special char
        XCTAssertFalse(viewModel.isValidPassword("PASSWORD123"))  // No lowercase or special char
        XCTAssertFalse(viewModel.isValidPassword("Password"))     // No digit or special char
        XCTAssertFalse(viewModel.isValidPassword("Password123"))  // No special char
    }
    
    // MARK: - Password Requirements Integration Tests
    
    func testPasswordRequirementsMatchValidation() {
        // Test that individual requirement checks match overall validation
        let testPasswords = [
            ("", false),
            ("short", false),
            ("password", false),
            ("Password", false),
            ("Password123", false),
            ("Password123!", true),
            ("MySecure1@", true),
            ("ComplexP@ssw0rd!", true)
        ]
        
        for (password, shouldBeValid) in testPasswords {
            let isValid = viewModel.isValidPassword(password)
            XCTAssertEqual(isValid, shouldBeValid, "Password '\(password)' validation mismatch")
            
            // Also test that individual requirements align with overall validation
            if shouldBeValid {
                XCTAssertTrue(password.count >= 8, "Valid password should meet length requirement")
                XCTAssertTrue(password.range(of: "[A-Z]", options: .regularExpression) != nil, "Valid password should have uppercase")
                XCTAssertTrue(password.range(of: "[a-z]", options: .regularExpression) != nil, "Valid password should have lowercase")
                XCTAssertTrue(password.range(of: "[0-9]", options: .regularExpression) != nil, "Valid password should have number")
                XCTAssertTrue(password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil, "Valid password should have special char")
            }
        }
    }
    
    func testPasswordRequirementsConsistency() {
        // Ensure the password requirements logic is consistent between
        // AuthenticationViewModel and PasswordRequirementsView
        let passwords = [
            "Password123!",
            "weak",
            "StrongP@ss1",
            "NoSpecialChar123",
            "nouppercasE1!",
            "NOLOWERCASE1!"
        ]
        
        for password in passwords {
            let authViewModelValid = viewModel.isValidPassword(password)
            
            // Simulate the logic from PasswordRequirementsView
            let lengthMet = password.count >= 8
            let upperMet = password.range(of: "[A-Z]", options: .regularExpression) != nil
            let lowerMet = password.range(of: "[a-z]", options: .regularExpression) != nil
            let numberMet = password.range(of: "[0-9]", options: .regularExpression) != nil
            let specialMet = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
            
            let allRequirementsMet = lengthMet && upperMet && lowerMet && numberMet && specialMet
            
            XCTAssertEqual(authViewModelValid, allRequirementsMet, 
                          "AuthenticationViewModel validation should match individual requirements for password: '\(password)'")
        }
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
        
        viewModel.signIn(email: "test@example.com", password: "Password123!")
        
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

@MainActor
class MockUserService {
    var shouldSucceed = true
    var mockUserProfile: UserProfile?
    
    init() {}
    
    func createUserProfile(for user: User, name: String = "") async throws {
        if !shouldSucceed {
            throw TravelAppError.dataError("Mock create user profile error")
        }
    }
    
    func getUserProfile() async throws -> UserProfile? {
        if !shouldSucceed {
            throw TravelAppError.dataError("Mock get user profile error")
        }
        return mockUserProfile
    }
    
    func updateUserProfile(name: String) async throws {
        if !shouldSucceed {
            throw TravelAppError.dataError("Mock update user profile error")
        }
    }
    
    func completeOnboarding() async throws {
        if !shouldSucceed {
            throw TravelAppError.dataError("Mock complete onboarding error")
        }
    }
}
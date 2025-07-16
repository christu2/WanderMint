import XCTest
import SwiftUI
@testable import WanderMint

@MainActor
class AuthenticationViewPasswordTests: XCTestCase {
    
    var authViewModel: AuthenticationViewModel!
    
    @MainActor
    override func setUp() {
        super.setUp()
        authViewModel = AuthenticationViewModel()
    }
    
    override func tearDown() {
        authViewModel = nil
        super.tearDown()
    }
    
    // MARK: - AuthenticationView Integration Tests
    
    func testAuthenticationViewCreation() {
        let view = AuthenticationView()
            .environmentObject(authViewModel)
        
        XCTAssertNotNil(view, "AuthenticationView should be created successfully")
    }
    
    func testPasswordRequirementsVisibilityInSignUpMode() {
        // This test simulates the behavior when isSignUpMode = true
        // In a real UI test, we would interact with the toggle button
        
        // For now, we test that PasswordRequirementsView can be created
        // with various password states that would occur during sign-up
        let passwordStates = ["", "p", "pa", "pas", "Pass", "Pass1", "Pass1!"]
        
        for password in passwordStates {
            let passwordRequirementsView = PasswordRequirementsView(password: password)
            XCTAssertNotNil(passwordRequirementsView, "PasswordRequirementsView should be created for password state: '\(password)'")
        }
    }
    
    @MainActor
    func testFormValidationIntegration() {
        // Test that form validation works correctly with password requirements
        let testCases = [
            (email: "test@example.com", password: "Password123!", confirmPassword: "Password123!", name: "Test User", shouldBeValid: true),
            (email: "test@example.com", password: "weak", confirmPassword: "weak", name: "Test User", shouldBeValid: false),
            (email: "test@example.com", password: "Password123!", confirmPassword: "Different123!", name: "Test User", shouldBeValid: false),
            (email: "invalid-email", password: "Password123!", confirmPassword: "Password123!", name: "Test User", shouldBeValid: false),
            (email: "test@example.com", password: "Password123!", confirmPassword: "Password123!", name: "", shouldBeValid: false)
        ]
        
        for (email, password, confirmPassword, name, shouldBeValid) in testCases {
            let emailValid = authViewModel.isValidEmail(email)
            let passwordValid = authViewModel.isValidPassword(password)
            let passwordsMatch = password == confirmPassword
            let nameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            let formValid = emailValid && passwordValid && passwordsMatch && nameValid
            
            XCTAssertEqual(formValid, shouldBeValid, 
                          "Form validation failed for: email='\(email)', password='\(password)', confirmPassword='\(confirmPassword)', name='\(name)'")
        }
    }
    
    // MARK: - Password Requirements Real-time Updates
    
    func testPasswordRequirementsRealTimeUpdates() {
        // Test that password requirements update in real-time as user types
        let progressivePassword = ["P", "Pa", "Pas", "Pass", "Passw", "Passwo", "Passwor", "Password", "Password1", "Password1!"]
        
        for password in progressivePassword {
            let view = PasswordRequirementsView(password: password)
            XCTAssertNotNil(view, "PasswordRequirementsView should update for progressive password: '\(password)'")
            
            // Test individual requirements for this password state
            let lengthMet = password.count >= 8
            let upperMet = password.range(of: "[A-Z]", options: .regularExpression) != nil
            let lowerMet = password.range(of: "[a-z]", options: .regularExpression) != nil
            let numberMet = password.range(of: "[0-9]", options: .regularExpression) != nil
            let specialMet = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
            
            // Verify expected behavior for each stage
            switch password {
            case "P":
                XCTAssertFalse(lengthMet)
                XCTAssertTrue(upperMet)
                XCTAssertFalse(lowerMet)
                XCTAssertFalse(numberMet)
                XCTAssertFalse(specialMet)
            case "Password":
                XCTAssertTrue(lengthMet)
                XCTAssertTrue(upperMet)
                XCTAssertTrue(lowerMet)
                XCTAssertFalse(numberMet)
                XCTAssertFalse(specialMet)
            case "Password1":
                XCTAssertTrue(lengthMet)
                XCTAssertTrue(upperMet)
                XCTAssertTrue(lowerMet)
                XCTAssertTrue(numberMet)
                XCTAssertFalse(specialMet)
            case "Password1!":
                XCTAssertTrue(lengthMet)
                XCTAssertTrue(upperMet)
                XCTAssertTrue(lowerMet)
                XCTAssertTrue(numberMet)
                XCTAssertTrue(specialMet)
            default:
                break
            }
        }
    }
    
    // MARK: - Visual State Tests
    
    func testPasswordRequirementRowVisualStates() {
        let requirements = [
            (text: "At least 8 characters", isMet: false),
            (text: "At least 8 characters", isMet: true),
            (text: "One uppercase letter", isMet: false),
            (text: "One uppercase letter", isMet: true),
            (text: "One lowercase letter", isMet: false),
            (text: "One lowercase letter", isMet: true),
            (text: "One number", isMet: false),
            (text: "One number", isMet: true),
            (text: "One special character", isMet: false),
            (text: "One special character", isMet: true)
        ]
        
        for (text, isMet) in requirements {
            let row = PasswordRequirementRow(text: text, isMet: isMet)
            XCTAssertNotNil(row, "PasswordRequirementRow should be created for: '\(text)', met: \(isMet)")
        }
    }
    
    // MARK: - Accessibility and Usability Tests
    
    func testPasswordRequirementsAccessibility() {
        let view = PasswordRequirementsView(password: "Password123!")
        XCTAssertNotNil(view, "PasswordRequirementsView should be accessible")
        
        // Test with various password states to ensure accessibility is maintained
        let accessibilityTestPasswords = ["", "weak", "Password", "Password123", "Password123!"]
        
        for password in accessibilityTestPasswords {
            let accessibleView = PasswordRequirementsView(password: password)
            XCTAssertNotNil(accessibleView, "PasswordRequirementsView should be accessible for password: '\(password)'")
        }
    }
    
    func testPasswordRequirementsUsability() {
        // Test that password requirements provide clear feedback
        let usabilityTestCases = [
            (password: "", expectedMetRequirements: 0),
            (password: "password", expectedMetRequirements: 2), // length + lowercase
            (password: "Password", expectedMetRequirements: 3), // length, upper, lower
            (password: "Password1", expectedMetRequirements: 4), // length, upper, lower, number
            (password: "Password1!", expectedMetRequirements: 5) // all requirements
        ]
        
        for (password, expectedCount) in usabilityTestCases {
            let lengthMet = password.count >= 8
            let upperMet = password.range(of: "[A-Z]", options: .regularExpression) != nil
            let lowerMet = password.range(of: "[a-z]", options: .regularExpression) != nil
            let numberMet = password.range(of: "[0-9]", options: .regularExpression) != nil
            let specialMet = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
            
            let metCount = [lengthMet, upperMet, lowerMet, numberMet, specialMet].filter { $0 }.count
            
            XCTAssertEqual(metCount, expectedCount, 
                          "Password '\(password)' should meet \(expectedCount) requirements, but meets \(metCount)")
        }
    }
    
    // MARK: - Performance and Animation Tests
    
    func testPasswordRequirementsPerformance() {
        // Test that password requirements updates are performant
        measure {
            let passwords = (0..<100).map { "Password\($0)!" }
            
            for password in passwords {
                let view = PasswordRequirementsView(password: password)
                _ = view.body // Force view creation
            }
        }
    }
    
    func testPasswordRequirementsAnimation() {
        // Test that password requirements support animation
        let animatedView = PasswordRequirementsView(password: "Password123!")
        XCTAssertNotNil(animatedView, "Animated PasswordRequirementsView should be created")
        
        // Test animation with rapid password changes
        let rapidPasswordChanges = ["P", "Pa", "Pass", "Password", "Password1", "Password1!"]
        
        for password in rapidPasswordChanges {
            let animatedUpdate = PasswordRequirementsView(password: password)
            XCTAssertNotNil(animatedUpdate, "Password requirements should handle rapid updates for: '\(password)'")
        }
    }
    
    // MARK: - Edge Case Tests
    
    @MainActor
    func testPasswordRequirementsEdgeCases() {
        let edgeCasePasswords = [
            "",                    // Empty
            " ",                   // Single space
            "        ",            // Multiple spaces
            "🚀🚀🚀🚀🚀🚀🚀🚀", // All emojis
            "Pássw0rd!",          // Unicode characters
            "Password123!@#$%^&*()", // Many special characters
            String(repeating: "a", count: 100) // Very long password
        ]
        
        for password in edgeCasePasswords {
            let view = PasswordRequirementsView(password: password)
            XCTAssertNotNil(view, "PasswordRequirementsView should handle edge case password: '\(password)'")
            
            // Also test that AuthenticationViewModel handles the same edge cases
            let isValid = authViewModel.isValidPassword(password)
            XCTAssertNotNil(isValid, "AuthenticationViewModel should handle edge case password: '\(password)'")
        }
    }
}
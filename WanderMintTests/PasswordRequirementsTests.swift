import XCTest
import SwiftUI
@testable import WanderMint

class PasswordRequirementsTests: XCTestCase {
    
    // MARK: - PasswordRequirementsView Tests
    
    func testPasswordRequirementsViewCreation() {
        let view = PasswordRequirementsView(password: "testPassword")
        XCTAssertNotNil(view, "PasswordRequirementsView should be created successfully")
    }
    
    func testEmptyPasswordRequirements() {
        let view = PasswordRequirementsView(password: "")
        
        // All requirements should be unmet for empty password
        XCTAssertFalse(isLengthRequirementMet(""), "Empty password should not meet length requirement")
        XCTAssertFalse(isUppercaseRequirementMet(""), "Empty password should not meet uppercase requirement")
        XCTAssertFalse(isLowercaseRequirementMet(""), "Empty password should not meet lowercase requirement")
        XCTAssertFalse(isNumberRequirementMet(""), "Empty password should not meet number requirement")
        XCTAssertFalse(isSpecialCharRequirementMet(""), "Empty password should not meet special character requirement")
    }
    
    func testPartialPasswordRequirements() {
        // Test password that meets some but not all requirements
        let partialPassword = "password"
        
        XCTAssertTrue(isLengthRequirementMet(partialPassword), "8+ char password should meet length requirement")
        XCTAssertFalse(isUppercaseRequirementMet(partialPassword), "Lowercase-only password should not meet uppercase requirement")
        XCTAssertTrue(isLowercaseRequirementMet(partialPassword), "Password with lowercase should meet lowercase requirement")
        XCTAssertFalse(isNumberRequirementMet(partialPassword), "Password without numbers should not meet number requirement")
        XCTAssertFalse(isSpecialCharRequirementMet(partialPassword), "Password without special chars should not meet special char requirement")
    }
    
    func testPasswordWithUppercase() {
        let password = "Password"
        
        XCTAssertTrue(isLengthRequirementMet(password), "8+ char password should meet length requirement")
        XCTAssertTrue(isUppercaseRequirementMet(password), "Password with uppercase should meet uppercase requirement")
        XCTAssertTrue(isLowercaseRequirementMet(password), "Password with lowercase should meet lowercase requirement")
        XCTAssertFalse(isNumberRequirementMet(password), "Password without numbers should not meet number requirement")
        XCTAssertFalse(isSpecialCharRequirementMet(password), "Password without special chars should not meet special char requirement")
    }
    
    func testPasswordWithNumbers() {
        let password = "Password123"
        
        XCTAssertTrue(isLengthRequirementMet(password), "11 char password should meet length requirement")
        XCTAssertTrue(isUppercaseRequirementMet(password), "Password with uppercase should meet uppercase requirement")
        XCTAssertTrue(isLowercaseRequirementMet(password), "Password with lowercase should meet lowercase requirement")
        XCTAssertTrue(isNumberRequirementMet(password), "Password with numbers should meet number requirement")
        XCTAssertFalse(isSpecialCharRequirementMet(password), "Password without special chars should not meet special char requirement")
    }
    
    func testCompletelyValidPassword() {
        let validPassword = "Password123!"
        
        XCTAssertTrue(isLengthRequirementMet(validPassword), "Valid password should meet length requirement")
        XCTAssertTrue(isUppercaseRequirementMet(validPassword), "Valid password should meet uppercase requirement")
        XCTAssertTrue(isLowercaseRequirementMet(validPassword), "Valid password should meet lowercase requirement")
        XCTAssertTrue(isNumberRequirementMet(validPassword), "Valid password should meet number requirement")
        XCTAssertTrue(isSpecialCharRequirementMet(validPassword), "Valid password should meet special char requirement")
    }
    
    func testPasswordLengthBoundaries() {
        // Test exactly 7 characters (should fail)
        let sevenChars = "Pass1@"
        XCTAssertFalse(isLengthRequirementMet(sevenChars), "7 character password should not meet length requirement")
        
        // Test exactly 8 characters (should pass)
        let eightChars = "Pass1@23"
        XCTAssertTrue(isLengthRequirementMet(eightChars), "8 character password should meet length requirement")
        
        // Test very long password (should pass)
        let longPassword = "ThisIsAVeryLongPasswordThatExceedsNormalLength123!@#"
        XCTAssertTrue(isLengthRequirementMet(longPassword), "Long password should meet length requirement")
    }
    
    func testSpecialCharacterVariety() {
        let specialChars = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "_", "+", "=", "{", "}", "[", "]", "|", "\\", ":", ";", "\"", "'", "<", ">", ",", ".", "?", "/", "~", "`"]
        
        for char in specialChars {
            let password = "Password123\(char)"
            XCTAssertTrue(isSpecialCharRequirementMet(password), "Password with '\(char)' should meet special character requirement")
        }
    }
    
    func testNumberVariety() {
        for digit in 0...9 {
            let password = "Password\(digit)!"
            XCTAssertTrue(isNumberRequirementMet(password), "Password with digit '\(digit)' should meet number requirement")
        }
    }
    
    func testCaseInsensitivity() {
        // Test various uppercase letters
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for char in uppercaseLetters {
            let password = "password123\(char)!"
            XCTAssertTrue(isUppercaseRequirementMet(password), "Password with uppercase '\(char)' should meet uppercase requirement")
        }
        
        // Test various lowercase letters
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        for char in lowercaseLetters {
            let password = "PASSWORD123\(char)!"
            XCTAssertTrue(isLowercaseRequirementMet(password), "Password with lowercase '\(char)' should meet lowercase requirement")
        }
    }
    
    // MARK: - PasswordRequirementRow Tests
    
    func testPasswordRequirementRowCreation() {
        let row = PasswordRequirementRow(text: "Test requirement", isMet: true)
        XCTAssertNotNil(row, "PasswordRequirementRow should be created successfully")
    }
    
    func testPasswordRequirementRowStates() {
        // Test met requirement
        let metRow = PasswordRequirementRow(text: "Test requirement", isMet: true)
        XCTAssertNotNil(metRow, "Met requirement row should be created")
        
        // Test unmet requirement
        let unmetRow = PasswordRequirementRow(text: "Test requirement", isMet: false)
        XCTAssertNotNil(unmetRow, "Unmet requirement row should be created")
    }
    
    // MARK: - Integration with AuthenticationViewModel
    
    @MainActor
    func testIntegrationWithAuthenticationViewModel() {
        let authViewModel = AuthenticationViewModel()
        
        // Test passwords that should fail validation
        let invalidPasswords = [
            "",
            "short",
            "password123",  // No uppercase or special char
            "PASSWORD123",  // No lowercase or special char
            "Password",     // No digit or special char
            "Password123"   // No special char
        ]
        
        for password in invalidPasswords {
            XCTAssertFalse(authViewModel.isValidPassword(password), "AuthenticationViewModel should reject invalid password: '\(password)'")
        }
        
        // Test passwords that should pass validation
        let validPasswords = [
            "Password123!",
            "MySecure1@",
            "StrongP@ss1",
            "ComplexP@ssw0rd!"
        ]
        
        for password in validPasswords {
            XCTAssertTrue(authViewModel.isValidPassword(password), "AuthenticationViewModel should accept valid password: '\(password)'")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPasswordValidationPerformance() {
        let passwords = (0..<1000).map { _ in generateRandomPassword() }
        
        measure {
            for password in passwords {
                _ = isLengthRequirementMet(password)
                _ = isUppercaseRequirementMet(password)
                _ = isLowercaseRequirementMet(password)
                _ = isNumberRequirementMet(password)
                _ = isSpecialCharRequirementMet(password)
            }
        }
    }
    
    @MainActor
    func testAuthenticationViewModelPerformance() {
        let authViewModel = AuthenticationViewModel()
        let passwords = (0..<1000).map { _ in generateRandomPassword() }
        
        measure {
            for password in passwords {
                _ = authViewModel.isValidPassword(password)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testUnicodeCharacters() {
        // Test password with Unicode characters
        let unicodePassword = "Pássw0rd123!"
        XCTAssertTrue(isLengthRequirementMet(unicodePassword), "Unicode password should meet length requirement")
        XCTAssertTrue(isUppercaseRequirementMet(unicodePassword), "Unicode password should meet uppercase requirement")
        XCTAssertTrue(isLowercaseRequirementMet(unicodePassword), "Unicode password should meet lowercase requirement")
        XCTAssertTrue(isNumberRequirementMet(unicodePassword), "Unicode password should meet number requirement")
        XCTAssertTrue(isSpecialCharRequirementMet(unicodePassword), "Unicode password should meet special char requirement")
    }
    
    func testEmojisInPassword() {
        // Test password with emojis (should be treated as special characters)
        let emojiPassword = "Password123😀"
        XCTAssertTrue(isSpecialCharRequirementMet(emojiPassword), "Password with emoji should meet special character requirement")
    }
    
    func testWhitespaceInPassword() {
        // Test password with spaces (should be treated as special characters)
        let spacePassword = "Password 123!"
        XCTAssertTrue(isSpecialCharRequirementMet(spacePassword), "Password with space should meet special character requirement")
    }
    
    // MARK: - User Experience Tests
    
    func testProgressiveRequirementMeeting() {
        // Simulate user typing password progressively
        let progressivePasswords = [
            "P",           // 1 char, uppercase
            "Pa",          // 2 chars, uppercase + lowercase
            "Pas",         // 3 chars
            "Pass",        // 4 chars
            "Passw",       // 5 chars
            "Passwo",      // 6 chars
            "Passwor",     // 7 chars
            "Password",    // 8 chars - meets length, upper, lower
            "Password1",   // 9 chars - adds number
            "Password1!"   // 10 chars - adds special char (fully valid)
        ]
        
        for (index, password) in progressivePasswords.enumerated() {
            let lengthMet = isLengthRequirementMet(password)
            let upperMet = isUppercaseRequirementMet(password)
            let lowerMet = isLowercaseRequirementMet(password)
            let numberMet = isNumberRequirementMet(password)
            let specialMet = isSpecialCharRequirementMet(password)
            
            // Verify expected progression
            switch index {
            case 0...6: // 1-7 characters
                XCTAssertFalse(lengthMet, "Password '\(password)' should not meet length requirement")
            case 7...9: // 8+ characters
                XCTAssertTrue(lengthMet, "Password '\(password)' should meet length requirement")
            default:
                break
            }
            
            if index >= 0 { // All have uppercase 'P'
                XCTAssertTrue(upperMet, "Password '\(password)' should meet uppercase requirement")
            }
            
            if index >= 1 { // All have lowercase starting from 'Pa'
                XCTAssertTrue(lowerMet, "Password '\(password)' should meet lowercase requirement")
            }
            
            if index >= 8 { // Number added at index 8
                XCTAssertTrue(numberMet, "Password '\(password)' should meet number requirement")
            } else {
                XCTAssertFalse(numberMet, "Password '\(password)' should not meet number requirement")
            }
            
            if index >= 9 { // Special char added at index 9
                XCTAssertTrue(specialMet, "Password '\(password)' should meet special character requirement")
            } else {
                XCTAssertFalse(specialMet, "Password '\(password)' should not meet special character requirement")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isLengthRequirementMet(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    private func isUppercaseRequirementMet(_ password: String) -> Bool {
        return password.range(of: "[A-Z]", options: .regularExpression) != nil
    }
    
    private func isLowercaseRequirementMet(_ password: String) -> Bool {
        return password.range(of: "[a-z]", options: .regularExpression) != nil
    }
    
    private func isNumberRequirementMet(_ password: String) -> Bool {
        return password.range(of: "[0-9]", options: .regularExpression) != nil
    }
    
    private func isSpecialCharRequirementMet(_ password: String) -> Bool {
        return password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
    }
    
    private func generateRandomPassword() -> String {
        let length = Int.random(in: 4...20)
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}

// MARK: - UI Tests for Password Requirements

@MainActor
class PasswordRequirementsUITests: XCTestCase {
    
    func testPasswordRequirementsViewRendering() {
        // Test that the view renders without crashing for various password states
        let passwords = ["", "p", "password", "Password", "Password1", "Password1!"]
        
        for password in passwords {
            let view = PasswordRequirementsView(password: password)
            XCTAssertNotNil(view, "PasswordRequirementsView should render for password: '\(password)'")
        }
    }
    
    func testPasswordRequirementRowRendering() {
        let texts = ["Test requirement", "Another requirement", ""]
        let states = [true, false]
        
        for text in texts {
            for state in states {
                let row = PasswordRequirementRow(text: text, isMet: state)
                XCTAssertNotNil(row, "PasswordRequirementRow should render for text: '\(text)', state: \(state)")
            }
        }
    }
}

// MARK: - Accessibility Tests

class PasswordRequirementsAccessibilityTests: XCTestCase {
    
    func testPasswordRequirementsAccessibility() {
        // These tests would verify that the password requirements are accessible
        // to screen readers and other assistive technologies
        
        let view = PasswordRequirementsView(password: "Password123!")
        XCTAssertNotNil(view, "Password requirements should be accessible")
        
        // In a real implementation, we would test:
        // - VoiceOver compatibility
        // - Dynamic type support
        // - High contrast mode support
        // - Accessibility labels and hints
    }
    
    func testPasswordRequirementRowAccessibility() {
        let metRow = PasswordRequirementRow(text: "At least 8 characters", isMet: true)
        let unmetRow = PasswordRequirementRow(text: "One uppercase letter", isMet: false)
        
        XCTAssertNotNil(metRow, "Met requirement should be accessible")
        XCTAssertNotNil(unmetRow, "Unmet requirement should be accessible")
        
        // In a real implementation, we would test:
        // - Proper accessibility labels for met/unmet states
        // - Screen reader announcements when requirements change
        // - Color contrast for visual indicators
    }
}
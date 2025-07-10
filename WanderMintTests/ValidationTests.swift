//
//  ValidationTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/10/25.
//

import XCTest
@testable import WanderMint

final class ValidationTests: XCTestCase {
    
    // MARK: - Form Validation Tests
    
    func testEmailValidation() {
        // Valid email formats
        XCTAssertTrue(FormValidation.isValidEmail("test@example.com"))
        XCTAssertTrue(FormValidation.isValidEmail("user.name+tag@example.co.uk"))
        XCTAssertTrue(FormValidation.isValidEmail("user123@domain-name.com"))
        XCTAssertTrue(FormValidation.isValidEmail("test.email-with-dash@example.com"))
        
        // Invalid email formats
        XCTAssertFalse(FormValidation.isValidEmail(""))
        XCTAssertFalse(FormValidation.isValidEmail("invalid-email"))
        XCTAssertFalse(FormValidation.isValidEmail("@example.com"))
        XCTAssertFalse(FormValidation.isValidEmail("test@"))
        XCTAssertFalse(FormValidation.isValidEmail("test.example.com"))
        XCTAssertFalse(FormValidation.isValidEmail("test@.com"))
        XCTAssertFalse(FormValidation.isValidEmail("test..email@example.com"))
    }
    
    func testPasswordStrengthValidation() {
        // Valid passwords
        XCTAssertTrue(FormValidation.isValidPassword("password123"))
        XCTAssertTrue(FormValidation.isValidPassword("strongPassword!"))
        XCTAssertTrue(FormValidation.isValidPassword("mySecureP@ss1"))
        
        // Invalid passwords (too short)
        XCTAssertFalse(FormValidation.isValidPassword(""))
        XCTAssertFalse(FormValidation.isValidPassword("12345"))
        XCTAssertFalse(FormValidation.isValidPassword("short"))
    }
    
    func testNameValidation() {
        // Valid names
        XCTAssertTrue(FormValidation.isValidName("John Doe"))
        XCTAssertTrue(FormValidation.isValidName("Jane"))
        XCTAssertTrue(FormValidation.isValidName("Mary-Jane"))
        XCTAssertTrue(FormValidation.isValidName("José García"))
        
        // Invalid names
        XCTAssertFalse(FormValidation.isValidName(""))
        XCTAssertFalse(FormValidation.isValidName("   "))
        XCTAssertFalse(FormValidation.isValidName("123"))
        XCTAssertFalse(FormValidation.isValidName("User@Name"))
    }
    
    // MARK: - Trip Validation Tests
    
    func testTripDateValidation() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        
        // Valid date ranges
        XCTAssertTrue(FormValidation.isValidDateRange(start: today, end: tomorrow))
        XCTAssertTrue(FormValidation.isValidDateRange(start: tomorrow, end: nextWeek))
        
        // Invalid date ranges
        XCTAssertFalse(FormValidation.isValidDateRange(start: tomorrow, end: today))
        XCTAssertFalse(FormValidation.isValidDateRange(start: today, end: yesterday))
    }
    
    func testTripTitleValidation() {
        // Valid titles
        XCTAssertTrue(FormValidation.isValidTripTitle("Paris Adventure"))
        XCTAssertTrue(FormValidation.isValidTripTitle("Weekend Getaway"))
        XCTAssertTrue(FormValidation.isValidTripTitle("Business Trip to Tokyo"))
        
        // Invalid titles
        XCTAssertFalse(FormValidation.isValidTripTitle(""))
        XCTAssertFalse(FormValidation.isValidTripTitle("   "))
        XCTAssertFalse(FormValidation.isValidTripTitle("A")) // Too short
    }
    
    func testDestinationValidation() {
        // Valid destinations
        XCTAssertTrue(FormValidation.isValidDestination("Paris, France"))
        XCTAssertTrue(FormValidation.isValidDestination("New York"))
        XCTAssertTrue(FormValidation.isValidDestination("Tokyo"))
        
        // Invalid destinations
        XCTAssertFalse(FormValidation.isValidDestination(""))
        XCTAssertFalse(FormValidation.isValidDestination("   "))
        XCTAssertFalse(FormValidation.isValidDestination("A"))
    }
    
    // MARK: - Points Validation Tests
    
    func testPointsAmountValidation() {
        // Valid point amounts
        XCTAssertTrue(FormValidation.isValidPointsAmount(0))
        XCTAssertTrue(FormValidation.isValidPointsAmount(1000))
        XCTAssertTrue(FormValidation.isValidPointsAmount(999999))
        
        // Invalid point amounts
        XCTAssertFalse(FormValidation.isValidPointsAmount(-1))
        XCTAssertFalse(FormValidation.isValidPointsAmount(-1000))
    }
    
    func testProviderNameValidation() {
        // Valid provider names
        XCTAssertTrue(FormValidation.isValidProviderName("Chase Sapphire"))
        XCTAssertTrue(FormValidation.isValidProviderName("Marriott"))
        XCTAssertTrue(FormValidation.isValidProviderName("United Airlines"))
        
        // Invalid provider names
        XCTAssertFalse(FormValidation.isValidProviderName(""))
        XCTAssertFalse(FormValidation.isValidProviderName("   "))
    }
    
    // MARK: - Input Sanitization Tests
    
    func testStringTrimming() {
        XCTAssertEqual(FormValidation.trimWhitespace("  hello  "), "hello")
        XCTAssertEqual(FormValidation.trimWhitespace("\n\ttest\n\t"), "test")
        XCTAssertEqual(FormValidation.trimWhitespace("normal"), "normal")
        XCTAssertEqual(FormValidation.trimWhitespace(""), "")
    }
    
    func testSpecialCharacterSanitization() {
        // Test basic sanitization
        XCTAssertEqual(FormValidation.sanitizeInput("Hello<script>"), "Hello")
        XCTAssertEqual(FormValidation.sanitizeInput("Test & Input"), "Test  Input")
        XCTAssertEqual(FormValidation.sanitizeInput("Normal text"), "Normal text")
    }
}
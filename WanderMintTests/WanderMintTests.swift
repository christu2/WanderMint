//
//  WanderMintTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/10/25.
//

import XCTest
import Firebase
@testable import WanderMint

/// Main test suite for WanderMint application
final class WanderMintTests: XCTestCase {
    
    override func setUpWithError() throws {
        super.setUp()
        TestConfiguration.configureFirebaseForTesting()
    }
    
    override func tearDownWithError() throws {
        super.tearDown()
    }
    
    // MARK: - Core Functionality Tests
    
    func testAppConfigurationLoading() throws {
        // Test that app configuration loads correctly
        let config = AppConfig.shared
        
        XCTAssertNotNil(config)
        XCTAssertFalse(config.apiBaseURL.isEmpty)
    }
    
    func testErrorHandling() throws {
        // Test custom error types
        let networkError = TravelAppError.networkError
        let authError = TravelAppError.authenticationFailed
        let dataError = TravelAppError.dataError("Test error message")
        let validationError = TravelAppError.validationError("Invalid input")
        let unknownError = TravelAppError.unknown
        
        XCTAssertNotNil(networkError)
        XCTAssertNotNil(authError)
        XCTAssertNotNil(dataError)
        XCTAssertNotNil(validationError)
        XCTAssertNotNil(unknownError)
        
        // Test error descriptions
        if case .dataError(let message) = dataError {
            XCTAssertEqual(message, "Test error message")
        } else {
            XCTFail("Expected dataError with message")
        }
    }
    
    func testDateUtilities() throws {
        let date = Date()
        let calendar = Calendar.current
        
        // Test date formatting
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let formattedDate = formatter.string(from: date)
        
        XCTAssertFalse(formattedDate.isEmpty)
        
        // Test date calculations
        let futureDate = calendar.date(byAdding: .day, value: 7, to: date)!
        let daysBetween = calendar.dateComponents([.day], from: date, to: futureDate).day!
        
        XCTAssertEqual(daysBetween, 7)
    }
    
    func testModelSerialization() throws {
        let trip = TestConfiguration.createTestTrip()
        
        // Test that models can be encoded/decoded
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(trip)
            let decodedTrip = try decoder.decode(Trip.self, from: data)
            
            XCTAssertEqual(trip.id, decodedTrip.id)
            XCTAssertEqual(trip.title, decodedTrip.title)
            XCTAssertEqual(trip.destination, decodedTrip.destination)
            XCTAssertEqual(trip.status, decodedTrip.status)
        } catch {
            XCTFail("Model serialization failed: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testModelCreationPerformance() throws {
        // Test performance of creating multiple models
        self.measure {
            for _ in 0..<1000 {
                _ = TestConfiguration.createTestTrip()
                _ = TestConfiguration.createTestUserProfile()
                _ = TestConfiguration.createTestPointsProfile()
            }
        }
    }
    
    func testValidationPerformance() throws {
        // Test performance of validation functions
        let emails = Array(repeating: "test@example.com", count: 1000)
        let passwords = Array(repeating: "securePassword123", count: 1000)
        
        self.measure {
            for i in 0..<1000 {
                _ = FormValidation.isValidEmail(emails[i])
                _ = FormValidation.isValidPassword(passwords[i])
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteDataFlow() async throws {
        // Test a complete data flow from user creation to trip planning
        let expectation = expectation(description: "Complete data flow")
        
        Task {
            // Create test user
            let user = TestConfiguration.createMockUser()
            let userProfile = TestConfiguration.createTestUserProfile(userId: user.uid)
            
            // Create test trip
            let trip = TestConfiguration.createTestTrip(userId: user.uid)
            
            // Create test points
            let pointsProfile = TestConfiguration.createTestPointsProfile(userId: user.uid)
            
            // Verify all data is consistent
            XCTAssertEqual(userProfile.userId, user.uid)
            XCTAssertEqual(trip.userId, user.uid)
            XCTAssertEqual(pointsProfile.userId, user.uid)
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testConcurrentOperations() async throws {
        // Test that the app handles concurrent operations correctly
        let expectation = expectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 5
        
        // Run multiple operations concurrently
        for i in 0..<5 {
            Task {
                let trip = TestConfiguration.createTestTrip(id: "concurrent-trip-\(i)")
                XCTAssertEqual(trip.id, "concurrent-trip-\(i)")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyDataHandling() throws {
        // Test handling of empty data
        XCTAssertFalse(FormValidation.isValidEmail(""))
        XCTAssertFalse(FormValidation.isValidPassword(""))
        XCTAssertFalse(FormValidation.isValidName(""))
        XCTAssertFalse(FormValidation.isValidTripTitle(""))
        XCTAssertFalse(FormValidation.isValidDestination(""))
    }
    
    func testBoundaryValues() throws {
        // Test boundary values for validation
        XCTAssertTrue(FormValidation.isValidPassword("123456")) // Minimum length
        XCTAssertFalse(FormValidation.isValidPassword("12345")) // Below minimum
        
        XCTAssertTrue(FormValidation.isValidPointsAmount(0)) // Minimum points
        XCTAssertFalse(FormValidation.isValidPointsAmount(-1)) // Below minimum
    }
    
    func testSpecialCharacters() throws {
        // Test handling of special characters in inputs
        XCTAssertTrue(FormValidation.isValidEmail("test+tag@example.com"))
        XCTAssertTrue(FormValidation.isValidName("José García"))
        XCTAssertTrue(FormValidation.isValidName("Mary-Jane"))
        
        // Test sanitization
        let sanitized = FormValidation.sanitizeInput("Hello<script>alert('xss')</script>")
        XCTAssertFalse(sanitized.contains("<script>"))
    }
}